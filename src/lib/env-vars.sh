#!/bin/bash
# GITD Environment Variables Module v1.0
# Handle environment variable prompts and defaults from .gitdrc

# Ensure dependencies are loaded
if [[ -z "$COLOR_RESET" ]]; then
    source "$GITD_INSTALL/src/lib/utils.sh"
fi

if ! type load_repo_config &>/dev/null 2>&1; then
    source "$GITD_INSTALL/src/lib/config-repo.sh"
fi

# =============================================================================
# ENVIRONMENT VARIABLE STORAGE
# =============================================================================

# Exported environment variables (for this session)
declare -A _GITD_ENV_VARS

# =============================================================================
# PROMPT FUNCTIONS
# =============================================================================

# Prompt user for a single environment variable
# Usage: value=$(prompt_env_var "DATABASE_URL" "PostgreSQL connection string" "postgresql://localhost:5432/db" false)
prompt_env_var() {
    local var_name="$1"
    local description="${2:-Enter value for $var_name}"
    local default_value="$3"
    local is_secret="${4:-false}"
    local validate_pattern="$5"

    local prompt_text
    if [[ -n "$default_value" ]]; then
        prompt_text="$description [$default_value]: "
    else
        prompt_text="$description: "
    fi

    local value
    local valid=false

    while [[ "$valid" == "false" ]]; do
        echo -e "${COLOR_CYAN}${INFO_MARK} ${var_name}${COLOR_RESET}"

        if [[ "$is_secret" == "true" ]]; then
            # Hidden input for secrets
            read -rs -p "  $prompt_text" value
            echo ""  # New line after hidden input
        else
            read -r -p "  $prompt_text" value
        fi

        # Use default if empty
        if [[ -z "$value" ]] && [[ -n "$default_value" ]]; then
            value="$default_value"
        fi

        # Validate if pattern provided
        if [[ -n "$validate_pattern" ]] && [[ -n "$value" ]]; then
            if echo "$value" | grep -qE "$validate_pattern"; then
                valid=true
            else
                echo -e "${COLOR_RED}${CROSS_MARK} Invalid format. Expected: $validate_pattern${COLOR_RESET}"
            fi
        else
            valid=true
        fi
    done

    echo "$value"
}

# =============================================================================
# BATCH PROMPT FUNCTIONS
# =============================================================================

# Prompt for all required environment variables
# Usage: prompt_required_env_vars
# Returns: 0 if all provided, 1 if any missing
prompt_required_env_vars() {
    local required_vars
    required_vars=$(repo_config_get_required_env)

    if [[ -z "$required_vars" ]]; then
        return 0
    fi

    echo ""
    echo -e "${COLOR_CYAN}╔════════════════════════════════════════════════════╗${COLOR_RESET}"
    echo -e "${COLOR_CYAN}║  Required Environment Variables                    ║${COLOR_RESET}"
    echo -e "${COLOR_CYAN}╚════════════════════════════════════════════════════╝${COLOR_RESET}"
    echo ""

    local missing=false

    while IFS= read -r var_name; do
        if [[ -z "$var_name" ]]; then
            continue
        fi

        # Get prompt configuration
        local description
        local default_value
        local is_secret
        local validate_pattern

        description=$(repo_config_get_env_prompt_desc "$var_name")
        default_value=$(repo_config_get_env_default "$var_name")
        is_secret=$(repo_config_is_env_secret "$var_name" && echo "true" || echo "false")
        validate_pattern=$(repo_config_get "env.prompts.$var_name.validate" "")

        # Prompt user
        local value
        value=$(prompt_env_var "$var_name" "$description" "$default_value" "$is_secret" "$validate_pattern")

        if [[ -z "$value" ]]; then
            echo -e "${COLOR_RED}${CROSS_MARK} Required variable '$var_name' not provided${COLOR_RESET}"
            missing=true
        else
            # Store and export
            _GITD_ENV_VARS["$var_name"]="$value"
            export "$var_name=$value"

            if [[ "$is_secret" == "true" ]]; then
                echo -e "${COLOR_GREEN}${CHECK_MARK} $var_name = ****${COLOR_RESET}"
            else
                echo -e "${COLOR_GREEN}${CHECK_MARK} $var_name = $value${COLOR_RESET}"
            fi
        fi
    done <<< "$required_vars"

    echo ""

    if [[ "$missing" == "true" ]]; then
        return 1
    fi

    return 0
}

# Prompt for optional environment variables
# Usage: prompt_optional_env_vars
prompt_optional_env_vars() {
    local optional_vars
    optional_vars=$(repo_config_get_optional_env)

    if [[ -z "$optional_vars" ]]; then
        return 0
    fi

    echo ""
    echo -e "${COLOR_CYAN}${INFO_MARK} Optional Environment Variables${COLOR_RESET}"
    echo -e "${COLOR_BLUE}  (Press Enter to skip)${COLOR_RESET}"
    echo ""

    while IFS= read -r var_name; do
        if [[ -z "$var_name" ]]; then
            continue
        fi

        # Get prompt configuration
        local description
        local default_value
        local is_secret

        description=$(repo_config_get_env_prompt_desc "$var_name")
        default_value=$(repo_config_get_env_default "$var_name")
        is_secret=$(repo_config_is_env_secret "$var_name" && echo "true" || echo "false")

        # Prompt user
        local value
        value=$(prompt_env_var "$var_name" "$description" "$default_value" "$is_secret")

        if [[ -n "$value" ]]; then
            _GITD_ENV_VARS["$var_name"]="$value"
            export "$var_name=$value"

            if [[ "$is_secret" == "true" ]]; then
                echo -e "${COLOR_GREEN}${CHECK_MARK} $var_name = ****${COLOR_RESET}"
            else
                echo -e "${COLOR_GREEN}${CHECK_MARK} $var_name = $value${COLOR_RESET}"
            fi
        else
            echo -e "${COLOR_BLUE}${INFO_MARK} $var_name skipped${COLOR_RESET}"
        fi
    done <<< "$optional_vars"

    echo ""
    return 0
}

# =============================================================================
# DEFAULT VALUES
# =============================================================================

# Export all default environment variables from config
# Usage: export_env_defaults
export_env_defaults() {
    if ! command -v jq &>/dev/null; then
        return 0
    fi

    local config_path="$_REPO_CONFIG_PATH"
    if [[ -z "$config_path" ]] || [[ ! -f "$config_path" ]]; then
        return 0
    fi

    # Get all default key-value pairs
    local defaults
    defaults=$(jq -r '.env.defaults | to_entries[]? | "\(.key)=\(.value)"' "$config_path" 2>/dev/null)

    if [[ -z "$defaults" ]]; then
        return 0
    fi

    echo -e "${COLOR_CYAN}${INFO_MARK} Exporting default environment variables:${COLOR_RESET}"

    while IFS='=' read -r key value; do
        if [[ -n "$key" ]]; then
            # Only set if not already set
            if [[ -z "${!key}" ]]; then
                export "$key=$value"
                _GITD_ENV_VARS["$key"]="$value"
                echo -e "  ${COLOR_GREEN}${CHECK_MARK}${COLOR_RESET} $key = $value"
            else
                echo -e "  ${COLOR_BLUE}${INFO_MARK}${COLOR_RESET} $key already set (keeping existing value)"
            fi
        fi
    done <<< "$defaults"

    echo ""
}

# =============================================================================
# MAIN FUNCTIONS
# =============================================================================

# Process all environment variables (defaults + prompts)
# Usage: if process_env_vars; then continue; else abort; fi
process_env_vars() {
    # First, export defaults
    export_env_defaults

    # Then, prompt for required variables
    if ! prompt_required_env_vars; then
        echo -e "${COLOR_RED}${CROSS_MARK} Setup aborted: Required environment variables not provided${COLOR_RESET}"
        return 1
    fi

    # Finally, prompt for optional variables
    prompt_optional_env_vars

    return 0
}

# Check if any environment variables are configured
# Usage: if has_env_config; then process_env_vars; fi
has_env_config() {
    local required optional defaults

    required=$(repo_config_get_required_env)
    optional=$(repo_config_get_optional_env)

    if command -v jq &>/dev/null; then
        defaults=$(jq -r '.env.defaults | length // 0' "$_REPO_CONFIG_PATH" 2>/dev/null)
    fi

    [[ -n "$required" ]] || [[ -n "$optional" ]] || [[ "$defaults" -gt 0 ]]
}

# =============================================================================
# WRITE ENV FILE
# =============================================================================

# Write environment variables to a .env file
# Usage: write_env_file "/path/to/.env"
write_env_file() {
    local env_file="$1"

    if [[ ${#_GITD_ENV_VARS[@]} -eq 0 ]]; then
        return 0
    fi

    echo -e "${COLOR_CYAN}${INFO_MARK} Writing environment variables to $env_file${COLOR_RESET}"

    # Create or truncate file
    : > "$env_file"

    # Write header
    echo "# Generated by GITD" >> "$env_file"
    echo "# $(date)" >> "$env_file"
    echo "" >> "$env_file"

    # Write variables
    for key in "${!_GITD_ENV_VARS[@]}"; do
        local value="${_GITD_ENV_VARS[$key]}"
        # Escape special characters
        value="${value//\\/\\\\}"
        value="${value//\"/\\\"}"
        echo "$key=\"$value\"" >> "$env_file"
    done

    echo -e "${COLOR_GREEN}${CHECK_MARK} Environment file created${COLOR_RESET}"
}

# =============================================================================
# DISPLAY FUNCTIONS
# =============================================================================

# Display configured environment variables (without values for secrets)
# Usage: display_env_config
display_env_config() {
    echo -e "${COLOR_CYAN}${INFO_MARK} Environment Configuration:${COLOR_RESET}"

    local required
    required=$(repo_config_get_required_env)
    if [[ -n "$required" ]]; then
        echo -e "  ${COLOR_YELLOW}Required:${COLOR_RESET}"
        while IFS= read -r var; do
            [[ -n "$var" ]] && echo -e "    • $var"
        done <<< "$required"
    fi

    local optional
    optional=$(repo_config_get_optional_env)
    if [[ -n "$optional" ]]; then
        echo -e "  ${COLOR_BLUE}Optional:${COLOR_RESET}"
        while IFS= read -r var; do
            [[ -n "$var" ]] && echo -e "    • $var"
        done <<< "$optional"
    fi

    echo ""
}

# Get summary of environment configuration
# Usage: summary=$(get_env_summary)
get_env_summary() {
    local required_count=0
    local optional_count=0

    local required
    required=$(repo_config_get_required_env)
    if [[ -n "$required" ]]; then
        required_count=$(echo "$required" | wc -l | tr -d ' ')
    fi

    local optional
    optional=$(repo_config_get_optional_env)
    if [[ -n "$optional" ]]; then
        optional_count=$(echo "$optional" | wc -l | tr -d ' ')
    fi

    echo "required:$required_count optional:$optional_count"
}
