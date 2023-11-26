#!/bin/bash

source "$GITD_INSTALL/src/lib/utils.sh"

session_pwd=$(pwd)

gitd() {
    if [ -z "$1" ]; then
        echo -e "${COLOR_RED}${CROSS_MARK} Error: ${COLOR_RESET}(use -h or --help for help)"
        echo "Usage: gitd <repo_url> [branch (optional)]"
        return 1
    fi

    if [ "$1" = "--version" ] || [ "$1" = "-v" ]; then
        echo "gitd version 1.0"
        return 0
    fi

    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        echo "Usage: gitd [options] <repo_url> [branch]"
        echo ""
        echo "Options:"
        echo "  -h, --help     Show this help message"
        echo "  -v, --version  Display the script version"
        echo "  -s, --setup    Set up the downloaded repository, including installing dependencies"

        return 0
    fi

    local repo_url
    local branch

    if [ "$1" = "--setup" ] || [ "$1" = "-s" ]; then
        repo_url=$2
        branch=$3
    else
        repo_url=$1
        branch=$2
    fi

    local repo_name=$(basename "$repo_url" .git)
    local repo_owner=$(echo "$repo_url" | cut -d '/' -f 4)
    local base_dir=${GITD_BASE_DIR:-"$HOME/Repos"}
    local target_dir="$base_dir/$repo_name"
    local repo_size=$(gh api repos/"$repo_owner"/"$repo_name" --jq '.size')

    if [ -e "$target_dir" ]; then
        echo ""
        echo -e "${COLOR_YELLOW}${WARNING_MARK} Warning: ${COLOR_RESET}Target directory '$target_dir' already exists."
        echo ""
        echo -e "${COLOR_CYAN}${INFO_MARK} Repository size: ${COLOR_RESET}$(format_size $repo_size)"
        echo ""
        read -r -p "$(echo -e '\033[1;34m::\033[0m') Do you want to delete it and re-download the repository? [Y/n]: " response
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
        read -r -p "$(echo -e '\033[1;34m::\033[0m') Do you want to delete it and re-download the repository? [Y/n]: " response
        response=${response:-Y}

        if [[ ! $response =~ ^[Yy]$ ]]; then
            echo ""
            echo -e "${COLOR_RED}${CROSS_MARK} Operation canceled.${COLOR_RESET}"
            return 1
        fi
    fi

    local default_branch
    default_branch=$(gh api repos/"$repo_owner"/"$repo_name" --jq '.default_branch')

    if [ -z "$branch" ]; then
        branch=$default_branch
    fi

    echo ""
    show_loading "Cloning repository..." "${COLOR_GREEN}${CHECK_MARK} Repository downloaded successfully.${COLOR_RESET}" "git clone --depth 1 -b "$branch" "$repo_url" "$target_dir""

    if [ $? -eq 0 ]; then
        local downloaded_size=$(du -sh "$target_dir" | cut -f1)
        echo -e "${COLOR_CYAN}${INFO_MARK} Repository details:${COLOR_RESET}"
        echo -e "${COLOR_CYAN}  • Name: ${COLOR_RESET}$repo_name"
        echo -e "${COLOR_CYAN}  • Owner: ${COLOR_RESET}$repo_owner"
        echo -e "${COLOR_CYAN}  • Default Branch: ${COLOR_RESET}$branch"
        echo -e "${COLOR_CYAN}  • Size: ${COLOR_RESET}$(format_size $repo_size)"
        echo -e "${COLOR_CYAN}${INFO_MARK} Repository location:${COLOR_RESET}"
        echo -e "${COLOR_GREEN}  $target_dir${COLOR_RESET}"
        echo ""
        cd "$target_dir"
        if [ "$1" = "--setup" ] || [ "$1" = "-s" ]; then
            bash "$GITD_INSTALL/src/scripts/setup.sh"
        fi
        cd "$session_pwd"
    else
        echo ""
        echo -e "${COLOR_RED}${CROSS_MARK} Error: ${COLOR_RESET}Failed to clone the repository."
        return 1
    fi
}
