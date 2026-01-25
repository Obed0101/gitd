#!/bin/bash
# GITD Hooks Module v1.0
# Execute lifecycle hooks from .gitdrc configuration

# Ensure dependencies are loaded
if [[ -z "$COLOR_RESET" ]]; then
    source "$GITD_INSTALL/src/lib/utils.sh"
fi

if ! type load_repo_config &>/dev/null 2>&1; then
    source "$GITD_INSTALL/src/lib/config-repo.sh"
fi

if ! type check_command_safety &>/dev/null 2>&1; then
    source "$GITD_INSTALL/src/lib/security.sh"
fi

if ! type should_require_confirmation &>/dev/null 2>&1; then
    source "$GITD_INSTALL/src/lib/config-merge.sh"
fi

# =============================================================================
# HOOK TYPES
# =============================================================================

# Valid hook types in execution order
HOOK_TYPES=("post-clone" "pre-setup" "post-setup")

# =============================================================================
# HOOK EXECUTION
# =============================================================================

# Execute a single hook command
# Usage: execute_hook_command "$cmd" "$timeout_ms" "$working_dir" "$allow_sudo"
# Returns: 0 on success, 1 on failure, 2 on timeout, 3 on blocked
execute_hook_command() {
    local cmd="$1"
    local timeout_ms="${2:-300000}"
    local working_dir="${3:-.}"
    local allow_sudo="${4:-false}"

    # Convert milliseconds to seconds
    local timeout_seconds=$((timeout_ms / 1000))

    # Safety check
    local safety_result
    safety_result=$(check_command_safety "$cmd" "$allow_sudo")

    case "$safety_result" in
        dangerous)
            echo -e "${COLOR_RED}${CROSS_MARK} Blocked: $cmd${COLOR_RESET}"
            echo -e "${COLOR_RED}  Reason: Dangerous command pattern detected${COLOR_RESET}"
            return 3
            ;;
        sudo_blocked)
            echo -e "${COLOR_RED}${CROSS_MARK} Blocked: $cmd${COLOR_RESET}"
            echo -e "${COLOR_RED}  Reason: sudo not allowed${COLOR_RESET}"
            return 3
            ;;
        restricted)
            echo -e "${COLOR_RED}${CROSS_MARK} Blocked: $cmd${COLOR_RESET}"
            echo -e "${COLOR_RED}  Reason: Command is restricted${COLOR_RESET}"
            return 3
            ;;
    esac

    # Show command being executed
    echo -e "${COLOR_BLUE}  → ${cmd}${COLOR_RESET}"

    # Change to working directory
    local original_dir
    original_dir=$(pwd)
    cd "$working_dir" || {
        echo -e "${COLOR_RED}${CROSS_MARK} Failed to change to directory: $working_dir${COLOR_RESET}"
        return 1
    }

    # Execute with timeout
    local exit_code
    if command -v timeout &>/dev/null; then
        timeout "$timeout_seconds" bash -c "$cmd" 2>&1
        exit_code=$?

        if [[ $exit_code -eq 124 ]]; then
            echo -e "${COLOR_RED}${CROSS_MARK} Timeout after ${timeout_seconds}s${COLOR_RESET}"
            cd "$original_dir"
            return 2
        fi
    else
        # Fallback without timeout command
        bash -c "$cmd" 2>&1
        exit_code=$?
    fi

    cd "$original_dir"

    if [[ $exit_code -eq 0 ]]; then
        echo -e "${COLOR_GREEN}${CHECK_MARK} Success${COLOR_RESET}"
    else
        echo -e "${COLOR_RED}${CROSS_MARK} Failed (exit code: $exit_code)${COLOR_RESET}"
    fi

    return $exit_code
}

# Execute all commands for a hook type
# Usage: execute_hooks "post-clone" "/path/to/repo"
# Returns: 0 if all succeed, 1 if any fail (and continueOnError is false)
execute_hooks() {
    local hook_type="$1"
    local working_dir="${2:-.}"

    # Check if hook exists
    if ! repo_config_has_hook "$hook_type"; then
        return 0
    fi

    # Get hook configuration
    local timeout_ms
    timeout_ms=$(repo_config_get_hook_timeout "$hook_type")

    local continue_on_error
    continue_on_error=$(repo_config_hook_continue_on_error "$hook_type" && echo "true" || echo "false")

    local allow_sudo
    allow_sudo=$(is_sudo_allowed && echo "true" || echo "false")

    local require_confirmation
    require_confirmation=$(should_require_confirmation && echo "true" || echo "false")

    # Get commands
    local commands=()
    while IFS= read -r cmd; do
        if [[ -n "$cmd" ]]; then
            commands+=("$cmd")
        fi
    done < <(repo_config_get_hook_commands "$hook_type")

    if [[ ${#commands[@]} -eq 0 ]]; then
        return 0
    fi

    # Display header
    echo ""
    echo -e "${COLOR_CYAN}${INFO_MARK} Executing $hook_type hooks (${#commands[@]} commands)${COLOR_RESET}"

    # User confirmation if required
    if [[ "$require_confirmation" == "true" ]]; then
        if ! confirm_all_commands "$hook_type" "${commands[@]}"; then
            echo -e "${COLOR_YELLOW}${WARNING_MARK} Hooks skipped by user${COLOR_RESET}"
            return 0
        fi
    fi

    # Execute each command
    local failed=false
    for cmd in "${commands[@]}"; do
        execute_hook_command "$cmd" "$timeout_ms" "$working_dir" "$allow_sudo"
        local result=$?

        if [[ $result -ne 0 ]]; then
            if [[ "$continue_on_error" != "true" ]]; then
                echo -e "${COLOR_RED}${CROSS_MARK} Hook execution aborted${COLOR_RESET}"
                return 1
            fi
            failed=true
        fi
    done

    if [[ "$failed" == "true" ]]; then
        echo -e "${COLOR_YELLOW}${WARNING_MARK} Some hooks failed but continued${COLOR_RESET}"
    else
        echo -e "${COLOR_GREEN}${CHECK_MARK} All $hook_type hooks completed${COLOR_RESET}"
    fi

    return 0
}

# =============================================================================
# HOOK LIFECYCLE
# =============================================================================

# Execute post-clone hooks
# Usage: execute_post_clone_hooks "/path/to/repo"
execute_post_clone_hooks() {
    local working_dir="$1"
    execute_hooks "post-clone" "$working_dir"
}

# Execute pre-setup hooks
# Usage: execute_pre_setup_hooks "/path/to/repo"
execute_pre_setup_hooks() {
    local working_dir="$1"
    execute_hooks "pre-setup" "$working_dir"
}

# Execute post-setup hooks
# Usage: execute_post_setup_hooks "/path/to/repo"
execute_post_setup_hooks() {
    local working_dir="$1"
    execute_hooks "post-setup" "$working_dir"
}

# =============================================================================
# HOOK INFORMATION
# =============================================================================

# List all hooks in config
# Usage: list_hooks
list_hooks() {
    echo -e "${COLOR_CYAN}${INFO_MARK} Configured hooks:${COLOR_RESET}"

    local found_any=false

    for hook_type in "${HOOK_TYPES[@]}"; do
        if repo_config_has_hook "$hook_type"; then
            found_any=true
            local count
            count=$(repo_config_get_hook_commands "$hook_type" | wc -l | tr -d ' ')
            echo -e "  • $hook_type: ${COLOR_YELLOW}$count command(s)${COLOR_RESET}"

            # Show commands
            while IFS= read -r cmd; do
                echo -e "      ${COLOR_BLUE}→${COLOR_RESET} $cmd"
            done < <(repo_config_get_hook_commands "$hook_type")
        fi
    done

    if [[ "$found_any" == "false" ]]; then
        echo -e "  ${COLOR_BLUE}No hooks configured${COLOR_RESET}"
    fi
}

# Get hook summary for display
# Usage: summary=$(get_hooks_summary)
get_hooks_summary() {
    local summary=""

    for hook_type in "${HOOK_TYPES[@]}"; do
        if repo_config_has_hook "$hook_type"; then
            local count
            count=$(repo_config_get_hook_commands "$hook_type" | wc -l | tr -d ' ')
            summary+="$hook_type:$count "
        fi
    done

    echo "$summary"
}

# =============================================================================
# DRY RUN
# =============================================================================

# Dry run - show what would be executed without running
# Usage: dry_run_hooks "post-clone" "/path/to/repo"
dry_run_hooks() {
    local hook_type="$1"
    local working_dir="${2:-.}"

    if ! repo_config_has_hook "$hook_type"; then
        echo -e "${COLOR_BLUE}${INFO_MARK} No $hook_type hooks configured${COLOR_RESET}"
        return 0
    fi

    local timeout_ms
    timeout_ms=$(repo_config_get_hook_timeout "$hook_type")

    local continue_on_error
    continue_on_error=$(repo_config_hook_continue_on_error "$hook_type" && echo "true" || echo "false")

    echo ""
    echo -e "${COLOR_CYAN}${INFO_MARK} [DRY RUN] $hook_type hooks:${COLOR_RESET}"
    echo -e "  Working directory: $working_dir"
    echo -e "  Timeout: $((timeout_ms / 1000))s"
    echo -e "  Continue on error: $continue_on_error"
    echo ""
    echo -e "  Commands:"

    while IFS= read -r cmd; do
        local safety
        safety=$(check_command_safety "$cmd" "false")

        case "$safety" in
            dangerous)
                echo -e "    ${COLOR_RED}✖ [BLOCKED] $cmd${COLOR_RESET}"
                ;;
            sudo_blocked)
                echo -e "    ${COLOR_RED}✖ [SUDO BLOCKED] $cmd${COLOR_RESET}"
                ;;
            *)
                echo -e "    ${COLOR_GREEN}→ $cmd${COLOR_RESET}"
                ;;
        esac
    done < <(repo_config_get_hook_commands "$hook_type")

    echo ""
}

# Dry run all hooks
# Usage: dry_run_all_hooks "/path/to/repo"
dry_run_all_hooks() {
    local working_dir="$1"

    echo -e "${COLOR_CYAN}╔════════════════════════════════════════════════════╗${COLOR_RESET}"
    echo -e "${COLOR_CYAN}║  DRY RUN - Hook Execution Preview                  ║${COLOR_RESET}"
    echo -e "${COLOR_CYAN}╚════════════════════════════════════════════════════╝${COLOR_RESET}"

    for hook_type in "${HOOK_TYPES[@]}"; do
        dry_run_hooks "$hook_type" "$working_dir"
    done
}
