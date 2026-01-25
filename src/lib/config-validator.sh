#!/bin/bash
# GITD Config Validator Module v1.0
# Validate .gitdrc configuration files

# Ensure utils are loaded
if [[ -z "$COLOR_RESET" ]]; then
    source "$GITD_INSTALL/src/lib/utils.sh"
fi

# =============================================================================
# VALIDATION CONSTANTS
# =============================================================================

# Supported languages
VALID_LANGUAGES=(
    "javascript" "typescript" "rust" "go" "python" "ruby"
    "java" "scala" "php" "elixir" "erlang" "dotnet"
    "zig" "swift" "haskell" "lua" "dart" "nim"
    "ocaml" "clojure" "cpp" "v"
)

# Supported tools
VALID_TOOLS=(
    # JavaScript
    "bun" "pnpm" "yarn" "npm"
    # Python
    "uv" "pip" "poetry" "pipenv" "conda"
    # Rust
    "cargo"
    # Go
    "go"
    # Ruby
    "bundle" "bundler"
    # Java
    "mvn" "maven" "gradle"
    # PHP
    "composer"
    # Elixir
    "mix"
    # .NET
    "dotnet"
    # Haskell
    "stack" "cabal"
    # C/C++
    "make" "cmake"
    # Zig
    "zig"
    # Swift
    "swift"
)

# Valid hook types
VALID_HOOKS=("post-clone" "pre-setup" "post-setup")

# =============================================================================
# CORE VALIDATION
# =============================================================================

# Validate JSON syntax
# Usage: if validate_json_syntax "/path/to/.gitdrc"; then ...
# Returns: 0 if valid, 1 if invalid
validate_json_syntax() {
    local config_path="$1"

    if [[ ! -f "$config_path" ]]; then
        echo "error:File not found: $config_path"
        return 1
    fi

    if command -v jq &>/dev/null; then
        if ! jq empty "$config_path" 2>/dev/null; then
            echo "error:Invalid JSON syntax"
            return 1
        fi
    else
        # Basic check without jq
        if ! grep -q "^[[:space:]]*{" "$config_path"; then
            echo "error:File does not appear to be valid JSON"
            return 1
        fi
    fi

    return 0
}

# Validate required fields
# Usage: validate_required_fields "/path/to/.gitdrc"
validate_required_fields() {
    local config_path="$1"
    local errors=()

    if ! command -v jq &>/dev/null; then
        # Without jq, we can only do basic validation
        if ! grep -q '"version"' "$config_path"; then
            errors+=("warning:Missing 'version' field (recommended)")
        fi

        if [[ ${#errors[@]} -gt 0 ]]; then
            printf '%s\n' "${errors[@]}"
            return 1
        fi
        return 0
    fi

    # Check version field
    local version
    version=$(jq -r '.version // empty' "$config_path" 2>/dev/null)
    if [[ -z "$version" ]]; then
        errors+=("warning:Missing 'version' field (recommended)")
    elif [[ "$version" != "1.0" ]]; then
        errors+=("warning:Unknown version '$version', expected '1.0'")
    fi

    if [[ ${#errors[@]} -gt 0 ]]; then
        printf '%s\n' "${errors[@]}"
        return 1
    fi

    return 0
}

# Validate detection section
# Usage: validate_detection "/path/to/.gitdrc"
validate_detection() {
    local config_path="$1"
    local errors=()

    if ! command -v jq &>/dev/null; then
        return 0
    fi

    # Check language
    local language
    language=$(jq -r '.detection.language // empty' "$config_path" 2>/dev/null)
    if [[ -n "$language" ]]; then
        local valid=false
        for lang in "${VALID_LANGUAGES[@]}"; do
            if [[ "$language" == "$lang" ]]; then
                valid=true
                break
            fi
        done
        if [[ "$valid" == "false" ]]; then
            errors+=("error:Invalid detection.language: '$language'")
        fi
    fi

    # Check tool
    local tool
    tool=$(jq -r '.detection.tool // empty' "$config_path" 2>/dev/null)
    if [[ -n "$tool" ]]; then
        local valid=false
        for t in "${VALID_TOOLS[@]}"; do
            if [[ "$tool" == "$t" ]]; then
                valid=true
                break
            fi
        done
        if [[ "$valid" == "false" ]]; then
            errors+=("error:Invalid detection.tool: '$tool'")
        fi
    fi

    if [[ ${#errors[@]} -gt 0 ]]; then
        printf '%s\n' "${errors[@]}"
        return 1
    fi

    return 0
}

# Validate hooks section
# Usage: validate_hooks "/path/to/.gitdrc"
validate_hooks() {
    local config_path="$1"
    local errors=()

    if ! command -v jq &>/dev/null; then
        return 0
    fi

    # Check each hook type
    local hook_keys
    hook_keys=$(jq -r '.hooks | keys[]? // empty' "$config_path" 2>/dev/null)

    while IFS= read -r hook_type; do
        if [[ -z "$hook_type" ]]; then
            continue
        fi

        # Validate hook type name
        local valid=false
        for h in "${VALID_HOOKS[@]}"; do
            if [[ "$hook_type" == "$h" ]]; then
                valid=true
                break
            fi
        done
        if [[ "$valid" == "false" ]]; then
            errors+=("warning:Unknown hook type: '$hook_type'")
        fi

        # Validate commands array
        local commands_type
        commands_type=$(jq -r ".hooks.\"$hook_type\".commands | type" "$config_path" 2>/dev/null)
        if [[ "$commands_type" != "array" ]] && [[ "$commands_type" != "null" ]]; then
            errors+=("error:hooks.$hook_type.commands must be an array")
        fi

        # Validate timeout (must be positive number)
        local timeout
        timeout=$(jq -r ".hooks.\"$hook_type\".timeout // empty" "$config_path" 2>/dev/null)
        if [[ -n "$timeout" ]]; then
            if ! [[ "$timeout" =~ ^[0-9]+$ ]] || [[ "$timeout" -le 0 ]]; then
                errors+=("error:hooks.$hook_type.timeout must be a positive number")
            fi
        fi

        # Validate continueOnError (must be boolean)
        local continue_type
        continue_type=$(jq -r ".hooks.\"$hook_type\".continueOnError | type" "$config_path" 2>/dev/null)
        if [[ "$continue_type" != "boolean" ]] && [[ "$continue_type" != "null" ]]; then
            errors+=("error:hooks.$hook_type.continueOnError must be a boolean")
        fi
    done <<< "$hook_keys"

    if [[ ${#errors[@]} -gt 0 ]]; then
        printf '%s\n' "${errors[@]}"
        return 1
    fi

    return 0
}

# Validate workflows section
# Usage: validate_workflows "/path/to/.gitdrc"
validate_workflows() {
    local config_path="$1"
    local errors=()

    if ! command -v jq &>/dev/null; then
        return 0
    fi

    local workflow_keys
    workflow_keys=$(jq -r '.workflows | keys[]? // empty' "$config_path" 2>/dev/null)

    while IFS= read -r workflow_name; do
        if [[ -z "$workflow_name" ]]; then
            continue
        fi

        # Validate workflow name (lowercase, hyphens, numbers)
        if ! [[ "$workflow_name" =~ ^[a-z][a-z0-9-]*$ ]]; then
            errors+=("warning:Workflow name '$workflow_name' should be lowercase with hyphens")
        fi

        # Validate steps array
        local steps_type
        steps_type=$(jq -r ".workflows.\"$workflow_name\".steps | type" "$config_path" 2>/dev/null)
        if [[ "$steps_type" != "array" ]]; then
            errors+=("error:workflows.$workflow_name.steps must be an array")
        else
            # Check steps array is not empty
            local steps_count
            steps_count=$(jq -r ".workflows.\"$workflow_name\".steps | length" "$config_path" 2>/dev/null)
            if [[ "$steps_count" -eq 0 ]]; then
                errors+=("warning:workflows.$workflow_name.steps is empty")
            fi
        fi
    done <<< "$workflow_keys"

    if [[ ${#errors[@]} -gt 0 ]]; then
        printf '%s\n' "${errors[@]}"
        return 1
    fi

    return 0
}

# Validate environment section
# Usage: validate_env "/path/to/.gitdrc"
validate_env() {
    local config_path="$1"
    local errors=()

    if ! command -v jq &>/dev/null; then
        return 0
    fi

    # Validate required array
    local required_type
    required_type=$(jq -r '.env.required | type' "$config_path" 2>/dev/null)
    if [[ "$required_type" != "array" ]] && [[ "$required_type" != "null" ]]; then
        errors+=("error:env.required must be an array")
    fi

    # Validate optional array
    local optional_type
    optional_type=$(jq -r '.env.optional | type' "$config_path" 2>/dev/null)
    if [[ "$optional_type" != "array" ]] && [[ "$optional_type" != "null" ]]; then
        errors+=("error:env.optional must be an array")
    fi

    # Validate defaults object
    local defaults_type
    defaults_type=$(jq -r '.env.defaults | type' "$config_path" 2>/dev/null)
    if [[ "$defaults_type" != "object" ]] && [[ "$defaults_type" != "null" ]]; then
        errors+=("error:env.defaults must be an object")
    fi

    # Validate variable names (uppercase with underscores)
    local required_vars
    required_vars=$(jq -r '.env.required[]? // empty' "$config_path" 2>/dev/null)
    while IFS= read -r var; do
        if [[ -n "$var" ]] && ! [[ "$var" =~ ^[A-Z_][A-Z0-9_]*$ ]]; then
            errors+=("warning:Environment variable '$var' should be uppercase")
        fi
    done <<< "$required_vars"

    if [[ ${#errors[@]} -gt 0 ]]; then
        printf '%s\n' "${errors[@]}"
        return 1
    fi

    return 0
}

# =============================================================================
# MAIN VALIDATION FUNCTION
# =============================================================================

# Validate entire config file
# Usage: result=$(validate_repo_config "/path/to/.gitdrc")
# Returns: validation messages (error:, warning:, info: prefixed)
validate_repo_config() {
    local config_path="$1"
    local all_messages=()
    local has_errors=false

    # Syntax validation
    local syntax_result
    syntax_result=$(validate_json_syntax "$config_path")
    if [[ $? -ne 0 ]]; then
        echo "$syntax_result"
        return 1
    fi

    # Required fields
    local required_result
    required_result=$(validate_required_fields "$config_path")
    if [[ -n "$required_result" ]]; then
        all_messages+=("$required_result")
    fi

    # Detection validation
    local detection_result
    detection_result=$(validate_detection "$config_path")
    if [[ -n "$detection_result" ]]; then
        all_messages+=("$detection_result")
        if echo "$detection_result" | grep -q "^error:"; then
            has_errors=true
        fi
    fi

    # Hooks validation
    local hooks_result
    hooks_result=$(validate_hooks "$config_path")
    if [[ -n "$hooks_result" ]]; then
        all_messages+=("$hooks_result")
        if echo "$hooks_result" | grep -q "^error:"; then
            has_errors=true
        fi
    fi

    # Workflows validation
    local workflows_result
    workflows_result=$(validate_workflows "$config_path")
    if [[ -n "$workflows_result" ]]; then
        all_messages+=("$workflows_result")
        if echo "$workflows_result" | grep -q "^error:"; then
            has_errors=true
        fi
    fi

    # Environment validation
    local env_result
    env_result=$(validate_env "$config_path")
    if [[ -n "$env_result" ]]; then
        all_messages+=("$env_result")
        if echo "$env_result" | grep -q "^error:"; then
            has_errors=true
        fi
    fi

    # Output all messages
    if [[ ${#all_messages[@]} -gt 0 ]]; then
        printf '%s\n' "${all_messages[@]}"
    fi

    if [[ "$has_errors" == "true" ]]; then
        return 1
    fi

    return 0
}

# =============================================================================
# DISPLAY FUNCTIONS
# =============================================================================

# Display validation results with colors
# Usage: display_validation_results "$(validate_repo_config '/path/to/.gitdrc')"
display_validation_results() {
    local results="$1"

    if [[ -z "$results" ]]; then
        echo -e "${COLOR_GREEN}${CHECK_MARK} Configuration is valid${COLOR_RESET}"
        return 0
    fi

    local has_errors=false

    while IFS= read -r line; do
        case "$line" in
            error:*)
                echo -e "${COLOR_RED}${CROSS_MARK} Error: ${line#error:}${COLOR_RESET}"
                has_errors=true
                ;;
            warning:*)
                echo -e "${COLOR_YELLOW}${WARNING_MARK} Warning: ${line#warning:}${COLOR_RESET}"
                ;;
            info:*)
                echo -e "${COLOR_CYAN}${INFO_MARK} ${line#info:}${COLOR_RESET}"
                ;;
            *)
                echo "$line"
                ;;
        esac
    done <<< "$results"

    if [[ "$has_errors" == "true" ]]; then
        return 1
    fi

    return 0
}

# Quick validation check (returns 0 for valid, 1 for invalid)
# Usage: if is_config_valid "/path/to/.gitdrc"; then ...
is_config_valid() {
    local config_path="$1"
    validate_repo_config "$config_path" >/dev/null 2>&1
}
