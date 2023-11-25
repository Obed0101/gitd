gitd() {

    if [ -z "$1" ]; then
        echo "\e[1;31m[✖] Error: \e[0mUsage: gitd <repo_url> [branch (optional)]"
        return 1
    fi

    local repo_url=$1
    local branch=$2
    local repo_name=$(basename $repo_url .git)
    local repo_owner=$(echo $repo_url | cut -d '/' -f 4)
    local base_dir=${GITD_BASE_DIR:-"$HOME/Repos"}
    local target_dir="$base_dir/$repo_name"
    echo ""
    echo "\e[1;34m[i] Starting gitd...\e[0m"

    if [ -e "$target_dir" ]; then
        echo ""
        echo -n "\e[1;34m::\e[0m Do you want to delete it and re-download the repository? [Y/n]: "
        read -r response
        response=${response:-Y}

        if [[ ! $response =~ ^[Yy]$ ]]; then
            echo ""
            echo "\e[1;31m[✖] Operation canceled.\e[0m"
            return 1
        fi

        rm -rf $target_dir
        echo ""
        echo "\e[1;32m[✔] Target directory deleted.\e[0m"
    fi

    local default_branch
    default_branch=$(gh api repos/$repo_owner/$repo_name --jq '.default_branch')

    if [ -z "$branch" ]; then
        branch=$default_branch
    fi

    echo ""
    echo "\e[1;36m[⬇] Cloning repository...\e[0m"
    git clone --depth 1 -b $branch $repo_url $target_dir >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo ""
        echo "\e[1;32m[✔] Repository downloaded successfully.\e[0m"
        echo ""
        echo "\e[1;34m[ℹ] Repository details:"
        echo "\e[1;34m  • Name: \e[0m$repo_name"
        echo "\e[1;34m  • Owner: \e[0m$repo_owner"
        echo "\e[1;34m  • Default Branch: \e[0m$branch"
        echo "\e[1;34m[ℹ] Repository location:"
        echo "\e[1;36m  $target_dir\e[0m"
    else
        echo ""
        echo "\e[1;31m[✖] Error: \e[0mFailed to clone the repository."
        return 1
    fi
}
