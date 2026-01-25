#!/bin/bash
# GITD Workflows Module v1.0
# Execute named workflows from .gitdrc configuration

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
# WORKFLOW EXECUTION
# =============================================================================

# Execute a single workflow step
# Usage: execute_workflow_step "$cmd" "$working_dir"
# Returns: command exit code
execute_workflow_step() {
    local cmd="$1"
    local working_dir="${2:-.}"

    # Safety check
    local safety_result
    safety_result=$(check_command_safety "$cmd" "false")

    case "$safety_result" in
        dangerous)
            echo -e "${COLOR_RED}${CROSS_MARK} Blocked: $cmd${COLOR_RESET}"
            echo -e "${COLOR_RED}  Reason: Dangerous command${COLOR_RESET}"
            return 1
            ;;
        sudo_blocked)
            echo -e "${COLOR_RED}${CROSS_MARK} Blocked: $cmd${COLOR_RESET}"
            echo -e "${COLOR_RED}  Reason: sudo not allowed in workflows${COLOR_RESET}"
            return 1
            ;;
    esac

    # Show step
    echo -e "${COLOR_BLUE}  → ${cmd}${COLOR_RESET}"

    # Execute
    local original_dir
    original_dir=$(pwd)
    cd "$working_dir" || return 1

    bash -c "$cmd"
    local exit_code=$?

    cd "$original_dir"

    if [[ $exit_code -eq 0 ]]; then
        echo -e "${COLOR_GREEN}  ${CHECK_MARK} Done${COLOR_RESET}"
    else
        echo -e "${COLOR_RED}  ${CROSS_MARK} Failed (exit code: $exit_code)${COLOR_RESET}"
    fi

    return $exit_code
}

# Execute a named workflow
# Usage: execute_workflow "dev" "/path/to/repo"
# Returns: 0 if all steps succeed, 1 if any fail
execute_workflow() {
    local workflow_name="$1"
    local working_dir="${2:-.}"

    # Check if workflow exists
    if ! repo_config_has_workflow "$workflow_name"; then
        echo -e "${COLOR_RED}${CROSS_MARK} Workflow '$workflow_name' not found${COLOR_RESET}"
        echo ""
        list_workflows
        return 1
    fi

    # Get workflow info
    local description
    description=$(repo_config_get_workflow_description "$workflow_name")

    local workdir
    workdir=$(repo_config_get "workflows.$workflow_name.workdir" ".")

    # Resolve working directory
    if [[ "$workdir" != "." ]] && [[ "$workdir" != "./" ]]; then
        working_dir="$working_dir/$workdir"
    fi

    # Display header
    echo ""
    echo -e "${COLOR_CYAN}╔════════════════════════════════════════════════════╗${COLOR_RESET}"
    echo -e "${COLOR_CYAN}║  Workflow: ${workflow_name}${COLOR_RESET}"
    if [[ -n "$description" ]]; then
        echo -e "${COLOR_CYAN}║  ${description}${COLOR_RESET}"
    fi
    echo -e "${COLOR_CYAN}╚════════════════════════════════════════════════════╝${COLOR_RESET}"
    echo ""

    # Get steps
    local steps=()
    while IFS= read -r step; do
        if [[ -n "$step" ]]; then
            steps+=("$step")
        fi
    done < <(repo_config_get_workflow_steps "$workflow_name")

    if [[ ${#steps[@]} -eq 0 ]]; then
        echo -e "${COLOR_YELLOW}${WARNING_MARK} Workflow has no steps${COLOR_RESET}"
        return 0
    fi

    echo -e "${COLOR_CYAN}${INFO_MARK} Running ${#steps[@]} step(s):${COLOR_RESET}"
    echo ""

    # Execute each step
    local failed=false
    local step_num=1

    for step in "${steps[@]}"; do
        echo -e "${COLOR_CYAN}Step $step_num/${#steps[@]}:${COLOR_RESET}"

        if ! execute_workflow_step "$step" "$working_dir"; then
            failed=true
            echo -e "${COLOR_RED}${CROSS_MARK} Workflow aborted at step $step_num${COLOR_RESET}"
            return 1
        fi

        ((step_num++))
        echo ""
    done

    echo -e "${COLOR_GREEN}${CHECK_MARK} Workflow '$workflow_name' completed successfully${COLOR_RESET}"
    return 0
}

# =============================================================================
# WORKFLOW LISTING
# =============================================================================

# List all available workflows
# Usage: list_workflows
list_workflows() {
    local workflows
    workflows=$(repo_config_list_workflows)

    if [[ -z "$workflows" ]]; then
        echo -e "${COLOR_BLUE}${INFO_MARK} No workflows configured${COLOR_RESET}"
        return 0
    fi

    echo -e "${COLOR_CYAN}${INFO_MARK} Available workflows:${COLOR_RESET}"
    echo ""

    while IFS= read -r name; do
        if [[ -z "$name" ]]; then
            continue
        fi

        local description
        description=$(repo_config_get_workflow_description "$name")

        local step_count
        step_count=$(repo_config_get_workflow_steps "$name" | wc -l | tr -d ' ')

        if [[ -n "$description" ]]; then
            echo -e "  ${COLOR_GREEN}$name${COLOR_RESET} - $description ($step_count steps)"
        else
            echo -e "  ${COLOR_GREEN}$name${COLOR_RESET} ($step_count steps)"
        fi
    done <<< "$workflows"

    echo ""
    echo -e "${COLOR_BLUE}Usage: gitd workflow <name>${COLOR_RESET}"
}

# =============================================================================
# WORKFLOW INFO
# =============================================================================

# Show detailed info about a workflow
# Usage: show_workflow_info "dev"
show_workflow_info() {
    local workflow_name="$1"

    if ! repo_config_has_workflow "$workflow_name"; then
        echo -e "${COLOR_RED}${CROSS_MARK} Workflow '$workflow_name' not found${COLOR_RESET}"
        return 1
    fi

    local description
    description=$(repo_config_get_workflow_description "$workflow_name")

    local workdir
    workdir=$(repo_config_get "workflows.$workflow_name.workdir" ".")

    echo ""
    echo -e "${COLOR_CYAN}Workflow: ${COLOR_GREEN}$workflow_name${COLOR_RESET}"

    if [[ -n "$description" ]]; then
        echo -e "${COLOR_CYAN}Description:${COLOR_RESET} $description"
    fi

    if [[ "$workdir" != "." ]]; then
        echo -e "${COLOR_CYAN}Working directory:${COLOR_RESET} $workdir"
    fi

    echo ""
    echo -e "${COLOR_CYAN}Steps:${COLOR_RESET}"

    local step_num=1
    while IFS= read -r step; do
        if [[ -n "$step" ]]; then
            echo -e "  $step_num. $step"
            ((step_num++))
        fi
    done < <(repo_config_get_workflow_steps "$workflow_name")

    echo ""
}

# =============================================================================
# DRY RUN
# =============================================================================

# Dry run a workflow (show steps without executing)
# Usage: dry_run_workflow "dev" "/path/to/repo"
dry_run_workflow() {
    local workflow_name="$1"
    local working_dir="${2:-.}"

    if ! repo_config_has_workflow "$workflow_name"; then
        echo -e "${COLOR_RED}${CROSS_MARK} Workflow '$workflow_name' not found${COLOR_RESET}"
        return 1
    fi

    local description
    description=$(repo_config_get_workflow_description "$workflow_name")

    echo ""
    echo -e "${COLOR_CYAN}╔════════════════════════════════════════════════════╗${COLOR_RESET}"
    echo -e "${COLOR_CYAN}║  [DRY RUN] Workflow: ${workflow_name}${COLOR_RESET}"
    echo -e "${COLOR_CYAN}╚════════════════════════════════════════════════════╝${COLOR_RESET}"
    echo ""

    if [[ -n "$description" ]]; then
        echo -e "${COLOR_CYAN}Description:${COLOR_RESET} $description"
    fi

    echo -e "${COLOR_CYAN}Working directory:${COLOR_RESET} $working_dir"
    echo ""
    echo -e "${COLOR_CYAN}Steps that would be executed:${COLOR_RESET}"
    echo ""

    local step_num=1
    while IFS= read -r step; do
        if [[ -z "$step" ]]; then
            continue
        fi

        local safety
        safety=$(check_command_safety "$step" "false")

        local prefix
        case "$safety" in
            dangerous)
                prefix="${COLOR_RED}✖ [BLOCKED]${COLOR_RESET}"
                ;;
            sudo_blocked)
                prefix="${COLOR_RED}✖ [SUDO BLOCKED]${COLOR_RESET}"
                ;;
            *)
                prefix="${COLOR_GREEN}→${COLOR_RESET}"
                ;;
        esac

        echo -e "  $step_num. $prefix $step"
        ((step_num++))
    done < <(repo_config_get_workflow_steps "$workflow_name")

    echo ""
    echo -e "${COLOR_BLUE}${INFO_MARK} No commands were executed (dry run)${COLOR_RESET}"
}

# =============================================================================
# WORKFLOW SELECTION
# =============================================================================

# Interactive workflow selection
# Usage: selected=$(select_workflow)
select_workflow() {
    local workflows
    workflows=$(repo_config_list_workflows)

    if [[ -z "$workflows" ]]; then
        echo ""
        return 1
    fi

    echo ""
    echo -e "${COLOR_CYAN}${INFO_MARK} Select a workflow:${COLOR_RESET}"
    echo ""

    local options=()
    local num=1

    while IFS= read -r name; do
        if [[ -z "$name" ]]; then
            continue
        fi

        local description
        description=$(repo_config_get_workflow_description "$name")

        if [[ -n "$description" ]]; then
            echo -e "  $num) ${COLOR_GREEN}$name${COLOR_RESET} - $description"
        else
            echo -e "  $num) ${COLOR_GREEN}$name${COLOR_RESET}"
        fi

        options+=("$name")
        ((num++))
    done <<< "$workflows"

    echo ""
    read -r -p "$(echo -e '\033[1;34m::\033[0m') Enter number (1-$((num-1))): " choice

    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -lt "$num" ]]; then
        echo "${options[$((choice-1))]}"
        return 0
    fi

    echo ""
    return 1
}

# =============================================================================
# WORKFLOW COMMAND HANDLER
# =============================================================================

# Handle workflow subcommand
# Usage: handle_workflow_command "dev" "/path/to/repo"
# Or: handle_workflow_command "--list" "/path/to/repo"
# Or: handle_workflow_command "--info" "dev" "/path/to/repo"
handle_workflow_command() {
    local action="$1"
    local working_dir

    case "$action" in
        --list|-l)
            list_workflows
            return $?
            ;;
        --info|-i)
            local workflow_name="$2"
            if [[ -z "$workflow_name" ]]; then
                echo -e "${COLOR_RED}${CROSS_MARK} Usage: gitd workflow --info <name>${COLOR_RESET}"
                return 1
            fi
            show_workflow_info "$workflow_name"
            return $?
            ;;
        --dry-run|-n)
            local workflow_name="$2"
            working_dir="${3:-.}"
            if [[ -z "$workflow_name" ]]; then
                echo -e "${COLOR_RED}${CROSS_MARK} Usage: gitd workflow --dry-run <name>${COLOR_RESET}"
                return 1
            fi
            dry_run_workflow "$workflow_name" "$working_dir"
            return $?
            ;;
        --select|-s)
            working_dir="${2:-.}"
            local selected
            selected=$(select_workflow)
            if [[ -n "$selected" ]]; then
                execute_workflow "$selected" "$working_dir"
                return $?
            fi
            return 1
            ;;
        "")
            # No argument, show available workflows
            list_workflows
            return 0
            ;;
        *)
            # Assume it's a workflow name
            working_dir="${2:-.}"
            execute_workflow "$action" "$working_dir"
            return $?
            ;;
    esac
}
