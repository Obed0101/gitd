#!/bin/zsh
# GITD - Git Download Tool v2.0
# Main command for Zsh shell

# Load core utilities
source "$GITD_INSTALL/src/lib/utils.sh"

# Load configuration modules
source "$GITD_INSTALL/src/lib/config-repo.sh" 2>/dev/null || true
source "$GITD_INSTALL/src/lib/config-merge.sh" 2>/dev/null || true
source "$GITD_INSTALL/src/lib/config-validator.sh" 2>/dev/null || true
source "$GITD_INSTALL/src/lib/security.sh" 2>/dev/null || true
source "$GITD_INSTALL/src/lib/hooks.sh" 2>/dev/null || true
source "$GITD_INSTALL/src/lib/env-vars.sh" 2>/dev/null || true
source "$GITD_INSTALL/src/lib/workflows.sh" 2>/dev/null || true
source "$GITD_INSTALL/src/lib/logging.sh" 2>/dev/null || true

session_pwd=$(pwd)

# Check for environment variable verbose/debug
[[ "$GITD_VERBOSE" == "true" ]] && type enable_verbose &>/dev/null && enable_verbose
[[ "$GITD_DEBUG" == "true" ]] && type enable_debug &>/dev/null && enable_debug

# =============================================================================
# WORKFLOW SUBCOMMAND
# =============================================================================

gitd-workflow() {
    local action="$1"
    shift

    # Load repo config from current directory
    if type load_repo_config &>/dev/null 2>&1; then
        load_repo_config "." >/dev/null 2>&1
    fi

    if ! type handle_workflow_command &>/dev/null 2>&1; then
        echo -e "${COLOR_RED}${CROSS_MARK} Workflows module not available${COLOR_RESET}"
        return 1
    fi

    handle_workflow_command "$action" "." "$@"
}

# =============================================================================
# MAIN COMMAND
# =============================================================================

gitd() {
    # Handle subcommands
    if [[ "$1" == "workflow" ]]; then
        shift
        gitd-workflow "$@"
        return $?
    fi

    if [ -z "$1" ]; then
        echo -e "${COLOR_RED}${CROSS_MARK} Error: ${COLOR_RESET}(use -h or --help for help)"
        echo "Usage: gitd <repo_url> [options]"
        echo "       gitd workflow <name>"
        return 1
    fi

    local repo_url
    local branch
    local setup=false
    local dry_run=false
    local target_dir_override=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
        (-b|--branch)
            branch=$2
            shift 2
            ;;
        (-d|--dir)
            if [[ "$2" == "." ]]; then
                target_dir_override="$(pwd)/"
            elif [[ "$2" == /* ]]; then
                target_dir_override="$2"
            else
                target_dir_override="$(pwd)/$2"
            fi
            shift 2
            ;;
        (-s|--setup)
            setup=true
            shift
            ;;
        (--dry-run)
            dry_run=true
            shift
            ;;
        (--verbose)
            type enable_verbose &>/dev/null && enable_verbose
            shift
            ;;
        (--debug)
            type enable_debug &>/dev/null && enable_debug
            shift
            ;;
        (-v|--version)
            echo "gitd version 2.0.0"
            return 0
            ;;
        (-h|--help)
            echo "Usage: gitd <repo_url> [options]"
            echo "       gitd workflow <name>"
            echo ""
            echo "Options:"
            echo "  -h, --help     Show this help message"
            echo "  -v, --version  Display the script version"
            echo "  -s, --setup    Set up the repository after cloning"
            echo "  -b, --branch   Specify the branch for cloning"
            echo "  -d, --dir      Clone to specific directory (use '.' for current)"
            echo "  --dry-run      Show what would be executed without running"
            echo "  --verbose      Enable verbose output"
            echo "  --debug        Enable debug output (includes verbose)"
            echo ""
            echo "Subcommands:"
            echo "  workflow       Run a workflow from .gitdrc"
            echo "    gitd workflow --list       List available workflows"
            echo "    gitd workflow <name>       Execute a workflow"
            echo "    gitd workflow --info <n>   Show workflow details"
            echo ""
            echo "Per-repository configuration:"
            echo "  Place a .gitdrc file in your repository to customize setup."
            echo "  See: https://github.com/Obed0101/gitd#configuration"
            return 0
            ;;
        (*)
            repo_url=$1
            shift
            ;;
        esac
    done

    if [ -z "$repo_url" ]; then
        echo -e "${COLOR_RED}${CROSS_MARK} Error: ${COLOR_RESET}No repository URL provided."
        echo "Usage: gitd <repo_url> [options]"
        return 1
    fi

    local repo_name=$(basename "$repo_url" .git)
    local repo_owner=$(echo "$repo_url" | cut -d '/' -f 4)
    local base_dir=$(get_base_dir)

    # Determine target directory
    local target_dir
    if [[ -n "$target_dir_override" ]]; then
        # Use override directory (from -d/--dir flag)
        if [[ "$target_dir_override" == */ ]]; then
            target_dir="${target_dir_override}${repo_name}"
        else
            target_dir="$target_dir_override"
        fi
        type log_verbose &>/dev/null && log_verbose "Using custom directory: $target_dir"
    else
        target_dir="$base_dir/$repo_name"
    fi

    # Log parsed values
    type log_verbose &>/dev/null && log_verbose "Repository: $repo_owner/$repo_name"
    type log_verbose &>/dev/null && log_verbose "Target directory: $target_dir"
    type log_debug &>/dev/null && log_debug "URL: $repo_url"

    # Verify repository exists
    if ! gh repo view "$repo_owner/$repo_name" &>/dev/null; then
        echo -e "${COLOR_RED}${CROSS_MARK} Error: ${COLOR_RESET}The repository '$repo_owner/$repo_name' does not exist or you don't have access."
        return 1
    fi

    local repo_size=$(gh api repos/"$repo_owner"/"$repo_name" --jq '.size')

    # Handle existing directory
    if [ -e "$target_dir" ]; then
        echo ""
        echo -e "${COLOR_YELLOW}${WARNING_MARK} Warning: ${COLOR_RESET}Target directory '$target_dir' already exists."
        echo ""
        echo -e "${COLOR_CYAN}${INFO_MARK} Repository size: ${COLOR_RESET}$(format_size $repo_size)"
        echo ""
        read -r "response?$(echo -e '\033[1;34m::\033[0m') Do you want to delete it and re-download? [Y/n]: "
        response=${response:-Y}

        if [[ ! $response =~ ^[Yy]$ ]]; then
            echo ""
            echo -e "${COLOR_RED}${CROSS_MARK} Operation canceled.${COLOR_RESET}"
            return 1
        fi

        rm -rf "$target_dir"
        echo ""
        echo -e "${COLOR_GREEN}${CHECK_MARK} Target directory deleted.${COLOR_RESET}"
    else
        echo ""
        echo -e "${COLOR_CYAN}${INFO_MARK} Repository size: ${COLOR_RESET}$(format_size $repo_size)"
        echo ""
        read -r "response?$(echo -e '\033[1;34m::\033[0m') Proceed with installation? [Y/n]: "
        response=${response:-Y}

        if [[ ! $response =~ ^[Yy]$ ]]; then
            echo ""
            echo -e "${COLOR_RED}${CROSS_MARK} Operation canceled.${COLOR_RESET}"
            return 1
        fi
    fi

    # Get default branch if not specified
    local default_branch
    default_branch=$(gh api repos/"$repo_owner"/"$repo_name" --jq '.default_branch')

    if [ -z "$branch" ]; then
        branch=$default_branch
    fi

    # Clone repository
    echo ""
    show_loading "Cloning repository..." "${COLOR_GREEN}${CHECK_MARK} Repository downloaded successfully.${COLOR_RESET}" "git-clone" "$branch" "$repo_url" "$target_dir"

    if [ $? -ne 0 ]; then
        echo ""
        echo -e "${COLOR_RED}${CROSS_MARK} Error: ${COLOR_RESET}Failed to clone the repository."
        return 1
    fi

    # =========================================================================
    # LOAD REPO CONFIG (.gitdrc)
    # =========================================================================
    local repo_config_path=""
    local has_repo_config=false

    if type load_repo_config &>/dev/null 2>&1; then
        repo_config_path=$(load_repo_config "$target_dir")
        if [[ -n "$repo_config_path" ]]; then
            has_repo_config=true
            type log_verbose &>/dev/null && log_verbose "Found .gitdrc config at: $repo_config_path"

            # Validate config
            if type validate_repo_config &>/dev/null 2>&1; then
                local validation_result
                validation_result=$(validate_repo_config "$repo_config_path")
                if [[ $? -ne 0 ]]; then
                    echo ""
                    echo -e "${COLOR_YELLOW}${WARNING_MARK} Config validation warnings:${COLOR_RESET}"
                    display_validation_results "$validation_result"
                fi
            fi

            # Display config summary
            if type repo_config_display_summary &>/dev/null 2>&1; then
                repo_config_display_summary
            fi

            # Security analysis
            if type analyze_config_security &>/dev/null 2>&1; then
                analyze_config_security "$repo_config_path"
            fi

            # Dry run mode
            if [[ "$dry_run" == "true" ]]; then
                if type dry_run_all_hooks &>/dev/null 2>&1; then
                    dry_run_all_hooks "$target_dir"
                fi
                echo -e "${COLOR_CYAN}${INFO_MARK} Dry run complete. No commands were executed.${COLOR_RESET}"
                return 0
            fi
        fi
    fi

    # =========================================================================
    # HANDLE .git DIRECTORY
    # =========================================================================
    local remove_git_dir=true

    # Check global config first (repos.removeGitDir)
    local global_config="$HOME/.gitd/config.json"
    if [[ -f "$global_config" ]]; then
        local global_remove
        global_remove=$(grep -o '"removeGitDir"[[:space:]]*:[[:space:]]*[^,}]*' "$global_config" 2>/dev/null | head -1 | grep -o 'true\|false')
        if [[ "$global_remove" == "false" ]]; then
            remove_git_dir=false
        fi
    fi

    # Check repo config (git.keepGitDir) - overrides global
    if [[ "$has_repo_config" == "true" ]] && type should_keep_git_dir &>/dev/null 2>&1; then
        if should_keep_git_dir; then
            remove_git_dir=false
        fi
    fi

    if [[ "$remove_git_dir" == "true" ]]; then
        rm -rf "$target_dir/.git"
    else
        echo -e "${COLOR_CYAN}${INFO_MARK} Keeping .git directory${COLOR_RESET}"
    fi

    # Display repository details
    echo -e "${COLOR_CYAN}${INFO_MARK} Repository details:${COLOR_RESET}"
    echo -e "${COLOR_CYAN}  • Name: ${COLOR_RESET}$repo_name"
    echo -e "${COLOR_CYAN}  • Owner: ${COLOR_RESET}$repo_owner"
    echo -e "${COLOR_CYAN}  • Branch: ${COLOR_RESET}$branch"
    echo -e "${COLOR_CYAN}  • Size: ${COLOR_RESET}$(format_size $repo_size)"
    echo -e "${COLOR_CYAN}${INFO_MARK} Repository location:${COLOR_RESET}"
    echo -e "${COLOR_GREEN}  $target_dir${COLOR_RESET}"
    echo ""

    # =========================================================================
    # EXECUTE POST-CLONE HOOKS
    # =========================================================================
    if [[ "$has_repo_config" == "true" ]] && type execute_post_clone_hooks &>/dev/null 2>&1; then
        execute_post_clone_hooks "$target_dir"
    fi

    # =========================================================================
    # CREATE BRANCH (if configured)
    # =========================================================================
    if [[ "$has_repo_config" == "true" ]] && type get_create_branch &>/dev/null 2>&1; then
        local create_branch
        create_branch=$(get_create_branch)
        if [[ -n "$create_branch" ]] && [[ "$remove_git_dir" == "false" ]]; then
            echo -e "${COLOR_CYAN}${INFO_MARK} Creating branch: $create_branch${COLOR_RESET}"
            cd "$target_dir"
            git checkout -b "$create_branch" 2>/dev/null || true
            cd "$session_pwd"
        fi
    fi

    # =========================================================================
    # SETUP
    # =========================================================================
    cd "$target_dir"

    if [ "$setup" = true ]; then
        # Check if setup should be skipped
        local skip_setup=false
        if [[ "$has_repo_config" == "true" ]] && type should_skip_setup &>/dev/null 2>&1; then
            if should_skip_setup; then
                skip_setup=true
                echo -e "${COLOR_YELLOW}${WARNING_MARK} Setup skipped (configured in .gitdrc)${COLOR_RESET}"
            fi
        fi

        if [[ "$skip_setup" == "false" ]]; then
            # Process environment variables (prompts + defaults)
            if [[ "$has_repo_config" == "true" ]] && type has_env_config &>/dev/null 2>&1; then
                if has_env_config; then
                    if ! process_env_vars; then
                        echo -e "${COLOR_RED}${CROSS_MARK} Setup aborted${COLOR_RESET}"
                        cd "$session_pwd"
                        return 1
                    fi
                fi
            fi

            # Execute pre-setup hooks
            if [[ "$has_repo_config" == "true" ]] && type execute_pre_setup_hooks &>/dev/null 2>&1; then
                execute_pre_setup_hooks "$target_dir"
            fi

            # Run setup script
            bash "$GITD_INSTALL/src/scripts/setup.sh" "$repo_config_path"

            # Execute post-setup hooks
            if [[ "$has_repo_config" == "true" ]] && type execute_post_setup_hooks &>/dev/null 2>&1; then
                execute_post_setup_hooks "$target_dir"
            fi
        fi
    fi

    # Change to cloned directory
    cd "$target_dir"

    # =========================================================================
    # OPEN EDITOR (if configured)
    # =========================================================================
    if [[ "$has_repo_config" == "true" ]] && type get_editor_to_open &>/dev/null 2>&1; then
        local editor
        editor=$(get_editor_to_open)
        if [[ -n "$editor" ]]; then
            local workspace
            workspace=$(get_workspace_file)

            echo -e "${COLOR_CYAN}${INFO_MARK} Opening in $editor...${COLOR_RESET}"

            if [[ -n "$workspace" ]] && [[ -f "$target_dir/$workspace" ]]; then
                "$editor" "$target_dir/$workspace" &>/dev/null &
            else
                "$editor" "$target_dir" &>/dev/null &
            fi
        fi
    fi

    echo -e "${COLOR_GREEN}${CHECK_MARK} Done!${COLOR_RESET}"
}
