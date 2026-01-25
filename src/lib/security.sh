#!/bin/bash
# GITD Security Module v1.0
# Command validation and safety checks

# Ensure utils are loaded
if [[ -z "$COLOR_RESET" ]]; then
    source "$GITD_INSTALL/src/lib/utils.sh"
fi

# =============================================================================
# DANGEROUS COMMAND PATTERNS
# =============================================================================

# Built-in dangerous command patterns (regex)
DANGEROUS_PATTERNS=(
    # Destructive file operations
    'rm[[:space:]]+-rf[[:space:]]+/'
    'rm[[:space:]]+-rf[[:space:]]+~'
    'rm[[:space:]]+-rf[[:space:]]+\*'
    'rm[[:space:]]+-fr[[:space:]]+/'
    '>[[:space:]]*/dev/sd'
    '>[[:space:]]*/dev/nvme'

    # System manipulation
    'mkfs[[:space:]]'
    'dd[[:space:]]+if=/dev/zero'
    'dd[[:space:]]+if=/dev/random'
    'dd[[:space:]]+of=/dev/sd'
    'dd[[:space:]]+of=/dev/nvme'

    # Fork bombs
    ':\(\)[[:space:]]*\{[[:space:]]*:\|:&[[:space:]]*\};:'
    '\./\$0\|'

    # Remote code execution (piping to shell)
    'curl[^|]*\|[[:space:]]*sh'
    'curl[^|]*\|[[:space:]]*bash'
    'wget[^|]*\|[[:space:]]*sh'
    'wget[^|]*\|[[:space:]]*bash'

    # Privilege escalation
    'chmod[[:space:]]+-R[[:space:]]+777[[:space:]]+/'
    'chmod[[:space:]]+777[[:space:]]+/'
    'chown[[:space:]]+-R[^/]*/'

    # Dangerous network operations
    'nc[[:space:]]+-l'

    # Crypto miners
    'xmrig'
    'minerd'
    'cpuminer'
)

# Commands that always require confirmation
SENSITIVE_COMMANDS=(
    'sudo'
    'su '
    'doas'
    'pkexec'
    'chmod'
    'chown'
    'rm -r'
    'rm -f'
    'mv /'
    'cp /'
)

# =============================================================================
# COMMAND VALIDATION
# =============================================================================

# Check if command matches dangerous patterns
# Usage: if is_command_dangerous "$cmd"; then ...
is_command_dangerous() {
    local cmd="$1"

    for pattern in "${DANGEROUS_PATTERNS[@]}"; do
        if echo "$cmd" | grep -qE "$pattern"; then
            return 0  # Dangerous
        fi
    done

    return 1  # Safe
}

# Check if command contains sudo
# Usage: if command_has_sudo "$cmd"; then ...
command_has_sudo() {
    local cmd="$1"
    echo "$cmd" | grep -qE '(^|[;&|])[[:space:]]*sudo[[:space:]]'
}

# Check if command is sensitive (requires extra attention)
# Usage: if is_command_sensitive "$cmd"; then ...
is_command_sensitive() {
    local cmd="$1"

    for sensitive in "${SENSITIVE_COMMANDS[@]}"; do
        if echo "$cmd" | grep -qF "$sensitive"; then
            return 0  # Sensitive
        fi
    done

    return 1  # Normal
}

# Check if command matches custom restricted patterns
# Usage: if is_command_restricted "$cmd" "pattern1" "pattern2" ...
is_command_restricted() {
    local cmd="$1"
    shift

    for pattern in "$@"; do
        if echo "$cmd" | grep -qF "$pattern"; then
            return 0  # Restricted
        fi
    done

    return 1  # Allowed
}

# Main safety check function
# Usage: result=$(check_command_safety "$cmd" "$allow_sudo" "pattern1" "pattern2")
# Returns: "safe", "dangerous", "sudo_blocked", "restricted"
check_command_safety() {
    local cmd="$1"
    local allow_sudo="${2:-false}"
    shift 2
    local restricted_patterns=("$@")

    # Check dangerous patterns first
    if is_command_dangerous "$cmd"; then
        echo "dangerous"
        return 1
    fi

    # Check sudo
    if command_has_sudo "$cmd"; then
        if [[ "$allow_sudo" != "true" ]]; then
            echo "sudo_blocked"
            return 1
        fi
    fi

    # Check custom restricted patterns
    if [[ ${#restricted_patterns[@]} -gt 0 ]]; then
        if is_command_restricted "$cmd" "${restricted_patterns[@]}"; then
            echo "restricted"
            return 1
        fi
    fi

    echo "safe"
    return 0
}

# =============================================================================
# SECURITY ANALYSIS
# =============================================================================

# Analyze a list of commands for security risks
# Usage: risk_count=$(analyze_commands_security "cmd1" "cmd2" ...)
analyze_commands_security() {
    local risk_count=0

    for cmd in "$@"; do
        if is_command_dangerous "$cmd"; then
            echo -e "${COLOR_RED}${CROSS_MARK} Dangerous: $cmd${COLOR_RESET}"
            ((risk_count++))
        elif command_has_sudo "$cmd"; then
            echo -e "${COLOR_YELLOW}${WARNING_MARK} Uses sudo: $cmd${COLOR_RESET}"
            ((risk_count++))
        elif is_command_sensitive "$cmd"; then
            echo -e "${COLOR_YELLOW}${WARNING_MARK} Sensitive: $cmd${COLOR_RESET}"
        fi
    done

    return $risk_count
}

# Analyze config file for security risks
# Usage: if analyze_config_security "/path/to/.gitdrc"; then echo "safe"; fi
analyze_config_security() {
    local config_path="$1"
    local risk_count=0

    if [[ ! -f "$config_path" ]]; then
        return 0
    fi

    echo -e "${COLOR_CYAN}${INFO_MARK} Security analysis:${COLOR_RESET}"

    # Check if jq is available
    if ! command -v jq &>/dev/null; then
        echo -e "${COLOR_YELLOW}${WARNING_MARK} jq not available, limited analysis${COLOR_RESET}"
        return 0
    fi

    # Analyze all hook commands
    local commands
    commands=$(jq -r '
        .hooks | to_entries[]? |
        .value.commands[]? // empty
    ' "$config_path" 2>/dev/null)

    if [[ -n "$commands" ]]; then
        while IFS= read -r cmd; do
            if [[ -z "$cmd" ]]; then
                continue
            fi

            if is_command_dangerous "$cmd"; then
                echo -e "${COLOR_RED}  ${CROSS_MARK} BLOCKED: $cmd${COLOR_RESET}"
                ((risk_count++))
            elif command_has_sudo "$cmd"; then
                echo -e "${COLOR_YELLOW}  ${WARNING_MARK} Uses sudo: $cmd${COLOR_RESET}"
                ((risk_count++))
            elif is_command_sensitive "$cmd"; then
                echo -e "${COLOR_BLUE}  ${INFO_MARK} Sensitive: $cmd${COLOR_RESET}"
            fi
        done <<< "$commands"
    fi

    # Analyze setup commands
    commands=$(jq -r '.setup.commands[]? // empty' "$config_path" 2>/dev/null)

    if [[ -n "$commands" ]]; then
        while IFS= read -r cmd; do
            if [[ -z "$cmd" ]]; then
                continue
            fi

            if is_command_dangerous "$cmd"; then
                echo -e "${COLOR_RED}  ${CROSS_MARK} BLOCKED: $cmd${COLOR_RESET}"
                ((risk_count++))
            elif command_has_sudo "$cmd"; then
                echo -e "${COLOR_YELLOW}  ${WARNING_MARK} Uses sudo: $cmd${COLOR_RESET}"
                ((risk_count++))
            fi
        done <<< "$commands"
    fi

    # Analyze workflow commands
    commands=$(jq -r '.workflows | to_entries[]? | .value.steps[]? // empty' "$config_path" 2>/dev/null)

    if [[ -n "$commands" ]]; then
        while IFS= read -r cmd; do
            if [[ -z "$cmd" ]]; then
                continue
            fi

            if is_command_dangerous "$cmd"; then
                echo -e "${COLOR_RED}  ${CROSS_MARK} BLOCKED: $cmd${COLOR_RESET}"
                ((risk_count++))
            fi
        done <<< "$commands"
    fi

    if [[ $risk_count -eq 0 ]]; then
        echo -e "${COLOR_GREEN}  ${CHECK_MARK} No security risks detected${COLOR_RESET}"
    else
        echo ""
        echo -e "${COLOR_RED}${CROSS_MARK} Found $risk_count security risk(s)${COLOR_RESET}"
    fi

    return $risk_count
}

# =============================================================================
# USER CONFIRMATION
# =============================================================================

# Prompt user to confirm command execution
# Usage: if confirm_command "$cmd" "hook_name"; then execute; fi
confirm_command() {
    local cmd="$1"
    local context="${2:-command}"

    echo ""
    echo -e "${COLOR_YELLOW}${WARNING_MARK} $context wants to execute:${COLOR_RESET}"
    echo -e "${COLOR_CYAN}  $cmd${COLOR_RESET}"
    echo ""

    read -r -p "$(echo -e '\033[1;34m::\033[0m') Execute this command? [Y/n]: " response
    response=${response:-Y}

    [[ $response =~ ^[Yy]$ ]]
}

# Prompt user to confirm all commands at once
# Usage: if confirm_all_commands "hook_name" "cmd1" "cmd2" ...; then execute_all; fi
confirm_all_commands() {
    local context="$1"
    shift
    local commands=("$@")

    echo ""
    echo -e "${COLOR_YELLOW}${WARNING_MARK} $context wants to execute ${#commands[@]} command(s):${COLOR_RESET}"
    echo ""

    for cmd in "${commands[@]}"; do
        local prefix="${COLOR_BLUE}  →${COLOR_RESET}"

        if is_command_dangerous "$cmd"; then
            prefix="${COLOR_RED}  ✖${COLOR_RESET}"
        elif command_has_sudo "$cmd"; then
            prefix="${COLOR_YELLOW}  !${COLOR_RESET}"
        fi

        echo -e "$prefix $cmd"
    done

    echo ""
    read -r -p "$(echo -e '\033[1;34m::\033[0m') Execute all commands? [Y/n]: " response
    response=${response:-Y}

    [[ $response =~ ^[Yy]$ ]]
}

# =============================================================================
# SAFE EXECUTION
# =============================================================================

# Execute command with safety checks
# Usage: safe_execute "$cmd" "$allow_sudo" "$require_confirmation" "$timeout"
# Returns: command exit code, or 1 if blocked
safe_execute() {
    local cmd="$1"
    local allow_sudo="${2:-false}"
    local require_confirmation="${3:-true}"
    local timeout_seconds="${4:-300}"
    local working_dir="${5:-.}"

    # Safety check
    local safety_result
    safety_result=$(check_command_safety "$cmd" "$allow_sudo")

    case "$safety_result" in
        dangerous)
            echo -e "${COLOR_RED}${CROSS_MARK} Blocked dangerous command: $cmd${COLOR_RESET}"
            return 1
            ;;
        sudo_blocked)
            echo -e "${COLOR_RED}${CROSS_MARK} Blocked sudo command (not allowed): $cmd${COLOR_RESET}"
            return 1
            ;;
        restricted)
            echo -e "${COLOR_RED}${CROSS_MARK} Blocked restricted command: $cmd${COLOR_RESET}"
            return 1
            ;;
    esac

    # Confirmation if required
    if [[ "$require_confirmation" == "true" ]]; then
        if ! confirm_command "$cmd" "Command"; then
            echo -e "${COLOR_YELLOW}${WARNING_MARK} Skipped by user${COLOR_RESET}"
            return 2
        fi
    fi

    # Execute with timeout
    cd "$working_dir" || return 1

    if command -v timeout &>/dev/null; then
        timeout "$timeout_seconds" bash -c "$cmd"
    else
        # Fallback without timeout
        bash -c "$cmd"
    fi

    return $?
}
