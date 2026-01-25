#!/bin/bash
# GITD Config Merge Module v1.0
# Merge configurations with precedence: CLI > Repo > User > Defaults

# Ensure dependencies are loaded
if [[ -z "$COLOR_RESET" ]]; then
    source "$GITD_INSTALL/src/lib/utils.sh"
fi

if ! type config_get &>/dev/null 2>&1; then
    source "$GITD_INSTALL/src/lib/config.sh" 2>/dev/null || true
fi

if ! type load_repo_config &>/dev/null 2>&1; then
    source "$GITD_INSTALL/src/lib/config-repo.sh"
fi

# =============================================================================
# MERGED CONFIG STATE
# =============================================================================

# Effective configuration (after merge)
declare -A _EFFECTIVE_CONFIG

# CLI overrides (set by command line flags)
declare -A _CLI_OVERRIDES

# =============================================================================
# CLI OVERRIDE FUNCTIONS
# =============================================================================

# Set CLI override
# Usage: set_cli_override "setup.skip" "true"
set_cli_override() {
    local key="$1"
    local value="$2"
    _CLI_OVERRIDES["$key"]="$value"
}

# Get CLI override
# Usage: value=$(get_cli_override "setup.skip")
get_cli_override() {
    local key="$1"
    echo "${_CLI_OVERRIDES[$key]:-}"
}

# Clear all CLI overrides
clear_cli_overrides() {
    _CLI_OVERRIDES=()
}

# =============================================================================
# MERGE FUNCTIONS
# =============================================================================

# Get effective config value with precedence
# Precedence: CLI > Repo Config > User Config > Default
# Usage: value=$(get_effective_config "detection.language" "")
get_effective_config() {
    local key="$1"
    local default="$2"

    # 1. Check CLI overrides first
    local cli_value="${_CLI_OVERRIDES[$key]:-}"
    if [[ -n "$cli_value" ]]; then
        echo "$cli_value"
        return 0
    fi

    # 2. Check repo config
    local repo_value
    repo_value=$(repo_config_get "$key" "")
    if [[ -n "$repo_value" ]]; then
        echo "$repo_value"
        return 0
    fi

    # 3. Check user config (global ~/.gitd/config.json)
    if type config_get &>/dev/null 2>&1; then
        local user_value
        user_value=$(config_get "$key" "")
        if [[ -n "$user_value" ]]; then
            echo "$user_value"
            return 0
        fi
    fi

    # 4. Return default
    echo "$default"
}

# Get effective boolean config value
# Usage: if get_effective_config_bool "setup.skip" "false"; then ...
get_effective_config_bool() {
    local key="$1"
    local default="${2:-false}"

    local value
    value=$(get_effective_config "$key" "$default")

    [[ "$value" == "true" ]]
}

# =============================================================================
# DETECTION CONFIGURATION
# =============================================================================

# Get effective detection language
# Usage: lang=$(get_effective_detection_language)
get_effective_detection_language() {
    get_effective_config "detection.language" ""
}

# Get effective detection tool
# Usage: tool=$(get_effective_detection_tool)
get_effective_detection_tool() {
    get_effective_config "detection.tool" ""
}

# Should skip detection?
# Usage: if should_skip_detection; then ...
should_skip_detection() {
    get_effective_config_bool "detection.skip" "false"
}

# =============================================================================
# SETUP CONFIGURATION
# =============================================================================

# Should skip setup?
# Usage: if should_skip_setup; then ...
should_skip_setup() {
    get_effective_config_bool "setup.skip" "false"
}

# Get effective package manager for language
# Usage: pm=$(get_effective_package_manager "javascript")
get_effective_package_manager() {
    local language="$1"

    # First check repo config override
    local tool
    tool=$(get_effective_detection_tool)
    if [[ -n "$tool" ]]; then
        echo "$tool"
        return 0
    fi

    # Then check user config
    if type config_get_package_manager &>/dev/null 2>&1; then
        config_get_package_manager "$language"
    else
        # Fallback defaults
        case "$language" in
            javascript|typescript) echo "npm" ;;
            python) echo "pip" ;;
            rust) echo "cargo" ;;
            go) echo "go" ;;
            ruby) echo "bundle" ;;
            java) echo "mvn" ;;
            php) echo "composer" ;;
            *) echo "" ;;
        esac
    fi
}

# =============================================================================
# SECURITY CONFIGURATION
# =============================================================================

# Should require confirmation for hooks?
# Usage: if should_require_confirmation; then ...
should_require_confirmation() {
    # Default to true for security
    get_effective_config_bool "security.requireConfirmation" "true"
}

# Is sudo allowed?
# Usage: if is_sudo_allowed; then ...
is_sudo_allowed() {
    # Default to false for security
    get_effective_config_bool "security.allowSudo" "false"
}

# =============================================================================
# GIT CONFIGURATION
# =============================================================================

# Should keep .git directory?
# Usage: if should_keep_git_dir; then ...
should_keep_git_dir() {
    get_effective_config_bool "git.keepGitDir" "false"
}

# Should remove .git directory? (inverse of keep)
# Usage: if should_remove_git_dir; then ...
should_remove_git_dir() {
    ! should_keep_git_dir
}

# Get branch to create after clone
# Usage: branch=$(get_create_branch)
get_create_branch() {
    get_effective_config "git.createBranch" ""
}

# =============================================================================
# EDITOR CONFIGURATION
# =============================================================================

# Get editor to open
# Usage: editor=$(get_editor_to_open)
get_editor_to_open() {
    get_effective_config "editor.open" ""
}

# Get workspace file
# Usage: workspace=$(get_workspace_file)
get_workspace_file() {
    get_effective_config "editor.workspace" ""
}

# =============================================================================
# DISPLAY MERGED CONFIG
# =============================================================================

# Display effective configuration summary
# Usage: display_effective_config
display_effective_config() {
    echo ""
    echo -e "${COLOR_CYAN}${INFO_MARK} Effective Configuration:${COLOR_RESET}"

    # Detection
    local lang tool
    lang=$(get_effective_detection_language)
    tool=$(get_effective_detection_tool)
    if [[ -n "$lang" ]] || [[ -n "$tool" ]]; then
        echo -e "${COLOR_CYAN}  Detection:${COLOR_RESET}"
        [[ -n "$lang" ]] && echo -e "    Language: $lang"
        [[ -n "$tool" ]] && echo -e "    Tool: $tool"
    fi

    # Setup
    if should_skip_setup; then
        echo -e "${COLOR_CYAN}  Setup:${COLOR_RESET} ${COLOR_YELLOW}Skipped${COLOR_RESET}"
    fi

    # Git
    if should_keep_git_dir; then
        echo -e "${COLOR_CYAN}  Git:${COLOR_RESET} Keep .git directory"
    fi

    local branch
    branch=$(get_create_branch)
    if [[ -n "$branch" ]]; then
        echo -e "${COLOR_CYAN}  Branch:${COLOR_RESET} Create '$branch'"
    fi

    # Editor
    local editor
    editor=$(get_editor_to_open)
    if [[ -n "$editor" ]]; then
        echo -e "${COLOR_CYAN}  Editor:${COLOR_RESET} Open with $editor"
    fi

    # Security
    echo -e "${COLOR_CYAN}  Security:${COLOR_RESET}"
    if should_require_confirmation; then
        echo -e "    Confirmation: ${COLOR_GREEN}Required${COLOR_RESET}"
    else
        echo -e "    Confirmation: ${COLOR_YELLOW}Disabled${COLOR_RESET}"
    fi
    if is_sudo_allowed; then
        echo -e "    Sudo: ${COLOR_YELLOW}Allowed${COLOR_RESET}"
    else
        echo -e "    Sudo: ${COLOR_GREEN}Blocked${COLOR_RESET}"
    fi

    echo ""
}

# =============================================================================
# INITIALIZATION
# =============================================================================

# Initialize merged configuration
# Usage: init_merged_config "/path/to/repo"
init_merged_config() {
    local repo_dir="$1"

    # Clear previous state
    _EFFECTIVE_CONFIG=()

    # Load repo config if available
    if [[ -n "$repo_dir" ]]; then
        load_repo_config "$repo_dir" >/dev/null 2>&1
    fi
}
