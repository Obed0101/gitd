#!/bin/bash
# GITD Config Repo Module v1.0
# Load and manage per-repository configuration (.gitdrc)

# Ensure utils are loaded
if [[ -z "$COLOR_RESET" ]]; then
    source "$GITD_INSTALL/src/lib/utils.sh"
fi

# Config file search order
GITDRC_FILES=(".gitdrc" ".gitdrc.json" ".gitd.json")

# Current repo config (cached)
_REPO_CONFIG_PATH=""
_REPO_CONFIG_CACHE=""

# =============================================================================
# CORE FUNCTIONS
# =============================================================================

# Load repo config from directory
# Usage: config_path=$(load_repo_config "/path/to/repo")
# Returns: path to config file or empty string
load_repo_config() {
    local repo_dir="$1"

    if [[ -z "$repo_dir" ]]; then
        repo_dir="."
    fi

    # Search for config files in order
    for config_file in "${GITDRC_FILES[@]}"; do
        local full_path="$repo_dir/$config_file"
        if [[ -f "$full_path" ]]; then
            _REPO_CONFIG_PATH="$full_path"
            _REPO_CONFIG_CACHE=""  # Clear cache
            echo "$full_path"
            return 0
        fi
    done

    _REPO_CONFIG_PATH=""
    _REPO_CONFIG_CACHE=""
    return 1
}

# Check if repo has configuration
# Usage: if has_repo_config "/path/to/repo"; then ...
has_repo_config() {
    local repo_dir="$1"
    load_repo_config "$repo_dir" >/dev/null 2>&1
}

# Get the cached config content
# Usage: content=$(get_repo_config_content)
get_repo_config_content() {
    if [[ -z "$_REPO_CONFIG_PATH" ]]; then
        return 1
    fi

    if [[ -z "$_REPO_CONFIG_CACHE" ]]; then
        _REPO_CONFIG_CACHE=$(cat "$_REPO_CONFIG_PATH" 2>/dev/null)
    fi

    echo "$_REPO_CONFIG_CACHE"
}

# =============================================================================
# VALUE GETTERS
# =============================================================================

# Check if jq is available
_has_jq() {
    command -v jq &>/dev/null
}

# Get value from repo config using jq or grep fallback
# Usage: value=$(repo_config_get "hooks.post-clone.commands" "[]")
repo_config_get() {
    local key="$1"
    local default="$2"

    if [[ -z "$_REPO_CONFIG_PATH" ]] || [[ ! -f "$_REPO_CONFIG_PATH" ]]; then
        echo "$default"
        return 1
    fi

    local content
    content=$(get_repo_config_content)

    if _has_jq; then
        local value
        value=$(echo "$content" | jq -r ".$key // empty" 2>/dev/null)
        if [[ -n "$value" ]] && [[ "$value" != "null" ]]; then
            echo "$value"
            return 0
        fi
    else
        # Fallback: simple grep for top-level keys
        local simple_key="${key%%.*}"
        local value
        value=$(echo "$content" | grep -o "\"$simple_key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | cut -d'"' -f4)
        if [[ -n "$value" ]]; then
            echo "$value"
            return 0
        fi
    fi

    echo "$default"
    return 1
}

# Get boolean value from repo config
# Usage: if repo_config_get_bool "setup.skip" "false"; then ...
repo_config_get_bool() {
    local key="$1"
    local default="${2:-false}"

    local value
    value=$(repo_config_get "$key" "$default")

    [[ "$value" == "true" ]]
}

# Get array from repo config as newline-separated values
# Usage: while IFS= read -r cmd; do echo "$cmd"; done < <(repo_config_get_array "hooks.post-clone.commands")
repo_config_get_array() {
    local key="$1"

    if [[ -z "$_REPO_CONFIG_PATH" ]] || [[ ! -f "$_REPO_CONFIG_PATH" ]]; then
        return 1
    fi

    local content
    content=$(get_repo_config_content)

    if _has_jq; then
        echo "$content" | jq -r ".$key[]? // empty" 2>/dev/null
    fi
}

# Get object keys from repo config
# Usage: keys=$(repo_config_get_keys "workflows")
repo_config_get_keys() {
    local key="$1"

    if [[ -z "$_REPO_CONFIG_PATH" ]] || [[ ! -f "$_REPO_CONFIG_PATH" ]]; then
        return 1
    fi

    local content
    content=$(get_repo_config_content)

    if _has_jq; then
        echo "$content" | jq -r ".$key | keys[]? // empty" 2>/dev/null
    fi
}

# =============================================================================
# DETECTION OVERRIDE
# =============================================================================

# Get detection override language
# Usage: lang=$(repo_config_get_detection_language)
repo_config_get_detection_language() {
    repo_config_get "detection.language" ""
}

# Get detection override tool
# Usage: tool=$(repo_config_get_detection_tool)
repo_config_get_detection_tool() {
    repo_config_get "detection.tool" ""
}

# Check if detection should be skipped
# Usage: if repo_config_should_skip_detection; then ...
repo_config_should_skip_detection() {
    repo_config_get_bool "detection.skip" "false"
}

# =============================================================================
# SETUP CONFIGURATION
# =============================================================================

# Check if setup should be skipped
# Usage: if repo_config_should_skip_setup; then ...
repo_config_should_skip_setup() {
    repo_config_get_bool "setup.skip" "false"
}

# Get custom setup commands
# Usage: while IFS= read -r cmd; do ... done < <(repo_config_get_setup_commands)
repo_config_get_setup_commands() {
    repo_config_get_array "setup.commands"
}

# Get setup working directory
# Usage: workdir=$(repo_config_get_setup_workdir)
repo_config_get_setup_workdir() {
    repo_config_get "setup.workdir" "."
}

# =============================================================================
# HOOKS CONFIGURATION
# =============================================================================

# Get hook commands
# Usage: while IFS= read -r cmd; do ... done < <(repo_config_get_hook_commands "post-clone")
repo_config_get_hook_commands() {
    local hook_type="$1"
    repo_config_get_array "hooks.${hook_type}.commands"
}

# Get hook timeout (in milliseconds, default 300000 = 5 minutes)
# Usage: timeout=$(repo_config_get_hook_timeout "post-clone")
repo_config_get_hook_timeout() {
    local hook_type="$1"
    local default_timeout="300000"
    repo_config_get "hooks.${hook_type}.timeout" "$default_timeout"
}

# Check if hook should continue on error
# Usage: if repo_config_hook_continue_on_error "post-clone"; then ...
repo_config_hook_continue_on_error() {
    local hook_type="$1"
    repo_config_get_bool "hooks.${hook_type}.continueOnError" "false"
}

# Check if hook exists
# Usage: if repo_config_has_hook "post-clone"; then ...
repo_config_has_hook() {
    local hook_type="$1"
    local commands
    commands=$(repo_config_get_hook_commands "$hook_type")
    [[ -n "$commands" ]]
}

# =============================================================================
# ENVIRONMENT VARIABLES
# =============================================================================

# Get required environment variables
# Usage: while IFS= read -r var; do ... done < <(repo_config_get_required_env)
repo_config_get_required_env() {
    repo_config_get_array "env.required"
}

# Get optional environment variables
# Usage: while IFS= read -r var; do ... done < <(repo_config_get_optional_env)
repo_config_get_optional_env() {
    repo_config_get_array "env.optional"
}

# Get environment variable default value
# Usage: default=$(repo_config_get_env_default "NODE_ENV")
repo_config_get_env_default() {
    local var_name="$1"
    repo_config_get "env.defaults.$var_name" ""
}

# Get environment variable prompt description
# Usage: desc=$(repo_config_get_env_prompt_desc "DATABASE_URL")
repo_config_get_env_prompt_desc() {
    local var_name="$1"
    repo_config_get "env.prompts.$var_name.description" "Enter value for $var_name"
}

# Check if environment variable is secret
# Usage: if repo_config_is_env_secret "API_KEY"; then ...
repo_config_is_env_secret() {
    local var_name="$1"
    repo_config_get_bool "env.prompts.$var_name.secret" "false"
}

# =============================================================================
# WORKFLOWS
# =============================================================================

# Get workflow steps
# Usage: while IFS= read -r step; do ... done < <(repo_config_get_workflow_steps "dev")
repo_config_get_workflow_steps() {
    local workflow_name="$1"
    repo_config_get_array "workflows.${workflow_name}.steps"
}

# Get workflow description
# Usage: desc=$(repo_config_get_workflow_description "dev")
repo_config_get_workflow_description() {
    local workflow_name="$1"
    repo_config_get "workflows.${workflow_name}.description" ""
}

# List all workflow names
# Usage: while IFS= read -r name; do ... done < <(repo_config_list_workflows)
repo_config_list_workflows() {
    repo_config_get_keys "workflows"
}

# Check if workflow exists
# Usage: if repo_config_has_workflow "dev"; then ...
repo_config_has_workflow() {
    local workflow_name="$1"
    local steps
    steps=$(repo_config_get_workflow_steps "$workflow_name")
    [[ -n "$steps" ]]
}

# =============================================================================
# SECURITY CONFIGURATION
# =============================================================================

# Check if user confirmation is required
# Usage: if repo_config_require_confirmation; then ...
repo_config_require_confirmation() {
    repo_config_get_bool "security.requireConfirmation" "true"
}

# Check if sudo is allowed
# Usage: if repo_config_allow_sudo; then ...
repo_config_allow_sudo() {
    repo_config_get_bool "security.allowSudo" "false"
}

# Get restricted commands
# Usage: while IFS= read -r pattern; do ... done < <(repo_config_get_restricted_commands)
repo_config_get_restricted_commands() {
    repo_config_get_array "security.restrictedCommands"
}

# =============================================================================
# EDITOR CONFIGURATION
# =============================================================================

# Get editor to open
# Usage: editor=$(repo_config_get_editor)
repo_config_get_editor() {
    repo_config_get "editor.open" ""
}

# Get workspace file
# Usage: workspace=$(repo_config_get_workspace)
repo_config_get_workspace() {
    repo_config_get "editor.workspace" ""
}

# =============================================================================
# GIT CONFIGURATION
# =============================================================================

# Check if .git directory should be kept
# Usage: if repo_config_keep_git_dir; then ...
repo_config_keep_git_dir() {
    repo_config_get_bool "git.keepGitDir" "false"
}

# Get branch to create after clone
# Usage: branch=$(repo_config_get_create_branch)
repo_config_get_create_branch() {
    repo_config_get "git.createBranch" ""
}

# =============================================================================
# DISPLAY FUNCTIONS
# =============================================================================

# Display repo config summary
# Usage: repo_config_display_summary
repo_config_display_summary() {
    if [[ -z "$_REPO_CONFIG_PATH" ]]; then
        return 1
    fi

    echo ""
    echo -e "${COLOR_CYAN}╔════════════════════════════════════════════════════╗${COLOR_RESET}"
    echo -e "${COLOR_CYAN}║  Repository Configuration Detected                 ║${COLOR_RESET}"
    echo -e "${COLOR_CYAN}╚════════════════════════════════════════════════════╝${COLOR_RESET}"
    echo ""
    echo -e "${COLOR_CYAN}${INFO_MARK} Config file: ${COLOR_RESET}$(basename "$_REPO_CONFIG_PATH")"

    # Show detection override
    local lang tool
    lang=$(repo_config_get_detection_language)
    tool=$(repo_config_get_detection_tool)
    if [[ -n "$lang" ]] || [[ -n "$tool" ]]; then
        echo -e "${COLOR_CYAN}${INFO_MARK} Detection override:${COLOR_RESET}"
        [[ -n "$lang" ]] && echo -e "  • Language: ${COLOR_GREEN}$lang${COLOR_RESET}"
        [[ -n "$tool" ]] && echo -e "  • Tool: ${COLOR_GREEN}$tool${COLOR_RESET}"
    fi

    # Show hooks summary
    local has_hooks=false
    for hook_type in "post-clone" "pre-setup" "post-setup"; do
        if repo_config_has_hook "$hook_type"; then
            if [[ "$has_hooks" == "false" ]]; then
                echo -e "${COLOR_CYAN}${INFO_MARK} Hooks:${COLOR_RESET}"
                has_hooks=true
            fi
            local count
            count=$(repo_config_get_hook_commands "$hook_type" | wc -l | tr -d ' ')
            echo -e "  • $hook_type: ${COLOR_YELLOW}$count command(s)${COLOR_RESET}"
        fi
    done

    # Show workflows
    local workflows
    workflows=$(repo_config_list_workflows)
    if [[ -n "$workflows" ]]; then
        echo -e "${COLOR_CYAN}${INFO_MARK} Workflows:${COLOR_RESET}"
        while IFS= read -r wf; do
            local desc
            desc=$(repo_config_get_workflow_description "$wf")
            if [[ -n "$desc" ]]; then
                echo -e "  • $wf: ${COLOR_BLUE}$desc${COLOR_RESET}"
            else
                echo -e "  • $wf"
            fi
        done <<< "$workflows"
    fi

    # Show required env vars
    local required_env
    required_env=$(repo_config_get_required_env)
    if [[ -n "$required_env" ]]; then
        echo -e "${COLOR_CYAN}${INFO_MARK} Required environment variables:${COLOR_RESET}"
        while IFS= read -r var; do
            echo -e "  • ${COLOR_YELLOW}$var${COLOR_RESET}"
        done <<< "$required_env"
    fi

    echo ""
}

# Display config version
# Usage: version=$(repo_config_get_version)
repo_config_get_version() {
    repo_config_get "version" "1.0"
}
