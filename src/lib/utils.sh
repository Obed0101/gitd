#!/bin/bash

if [ -t 1 ]; then
    INFO_MARK=$'\033[1;34mi\033[0m'
    CHECK_MARK=$'\033[1;32m✔\033[0m'
    CROSS_MARK=$'\033[1;31m✖\033[0m'
    WARNING_MARK=$'\033[1;33m!\033[0m'
    QUESTION_MARK=$'\033[1;35m?\033[0m'
    DOWNLOAD_MARK=$'\033[1;36m⬇\033[0m'

    COLOR_RED=$'\033[1;31m'
    COLOR_GREEN=$'\033[1;32m'
    COLOR_YELLOW=$'\033[1;33m'
    COLOR_BLUE=$'\033[1;34m'
    COLOR_CYAN=$'\033[1;36m'
    COLOR_RESET=$'\033[0m'
else
    INFO_MARK="i"
    CHECK_MARK="✔"
    CROSS_MARK="✖"
    WARNING_MARK="!"
    QUESTION_MARK="?"
    DOWNLOAD_MARK="⬇"

    COLOR_RED=''
    COLOR_GREEN=''
    COLOR_YELLOW=''
    COLOR_BLUE=''
    COLOR_CYAN=''
    COLOR_RESET=''
fi

# Get base directory from config.json
# Usage: base_dir=$(get_base_dir)
get_base_dir() {
    local config_file="$HOME/.gitd/config.json"
    if [ -f "$config_file" ]; then
        local base_dir
        base_dir=$(grep -o '"baseDir"[[:space:]]*:[[:space:]]*"[^"]*"' "$config_file" 2>/dev/null | head -1 | cut -d'"' -f4)
        if [ -n "$base_dir" ]; then
            # Expand ~ to $HOME
            echo "${base_dir/#\~/$HOME}"
            return 0
        fi
    fi
    echo "$HOME/Repos"
}

SHELL_NAME=$(basename "$SHELL")

# Execute a known command safely without eval
# Usage: run_command <command_type> [args...]
# Returns: exit status of the command
run_command() {
    local cmd_type="$1"
    shift

    case "$cmd_type" in
        # JavaScript/TypeScript
        "bun")
            bun install 2>&1
            ;;
        "npm")
            npm install 2>&1
            ;;
        "yarn")
            yarn install 2>&1
            ;;
        "pnpm")
            pnpm install 2>&1
            ;;

        # Rust
        "cargo")
            cargo build --release 2>&1
            ;;

        # Go
        "go")
            go build ./... 2>&1
            ;;

        # Python
        "uv")
            if [ -f "pyproject.toml" ]; then
                uv sync 2>&1
            else
                uv pip install -r requirements.txt 2>&1
            fi
            ;;
        "pip")
            if [ -f "pyproject.toml" ]; then
                pip install -e . 2>&1
            else
                pip install -r requirements.txt 2>&1
            fi
            ;;
        "poetry")
            poetry install 2>&1
            ;;
        "pipenv")
            pipenv install 2>&1
            ;;

        # Ruby
        "bundle")
            bundle install 2>&1
            ;;

        # Java
        "mvn")
            mvn clean install -DskipTests 2>&1
            ;;
        "gradle")
            gradle build -x test 2>&1
            ;;

        # PHP
        "composer")
            composer install 2>&1
            ;;

        # Elixir
        "mix")
            mix deps.get && mix compile 2>&1
            ;;

        # .NET
        "dotnet")
            dotnet restore && dotnet build 2>&1
            ;;

        # Zig
        "zig")
            zig build 2>&1
            ;;

        # Swift
        "swift")
            swift build 2>&1
            ;;

        # Haskell
        "stack")
            stack build 2>&1
            ;;
        "cabal")
            cabal update && cabal build 2>&1
            ;;

        # C/C++
        "make")
            make 2>&1
            ;;
        "cmake")
            cmake -B build && cmake --build build 2>&1
            ;;

        # Git operations
        "git-clone")
            # Args: branch, url, target_dir
            local branch="$1"
            local url="$2"
            local target_dir="$3"
            git clone --depth 1 -b "$branch" "$url" "$target_dir" 2>&1
            ;;

        *)
            echo "Unknown command type: $cmd_type"
            return 1
            ;;
    esac
}

# Show loading message while executing a command
# Usage: show_loading <loading_msg> <success_msg> <command_type> [args...]
function show_loading() {
    local loading_message="$1"
    local completion_message="$2"
    local command_type="$3"
    shift 3

    echo -en "\r${DOWNLOAD_MARK} ${loading_message}"

    command_output=$(run_command "$command_type" "$@")
    command_exit_status=$?

    if [ $command_exit_status -eq 0 ]; then
        echo -e "\r${completion_message}\n"
    else
        echo -e "\r${COLOR_RED}${CROSS_MARK} Error executing the command.${COLOR_RESET}\n"
    fi

    return $command_exit_status
}

format_size() {
    local size_in_kb=$1

    if ((size_in_kb < 1024)); then
        echo "${size_in_kb} KB"
    elif ((size_in_kb < 1048576)); then
        echo "$((size_in_kb / 1024)) MB"
    else
        echo "$((size_in_kb / 1048576)) GB"
    fi
}

install_pnpm() {
              case $(uname -s) in
            Darwin)
                echo ""
                echo -e "${COLOR_CYAN}${INFO_MARK} Installing pnpm for macOS...${COLOR_RESET}"
                brew install pnpm
                ;;
            Linux)
                if command -v apt-get &>/dev/null; then
                    echo ""
                    echo -e "${COLOR_CYAN}${INFO_MARK} Installing pnpm for Debian/Ubuntu...${COLOR_RESET}"
                    sudo apt-get install pnpm
                elif command -v dnf &>/dev/null; then
                    echo ""
                    echo -e "${COLOR_CYAN}${INFO_MARK} Installing pnpm for Fedora...${COLOR_RESET}"
                    sudo dnf install pnpm
                elif command -v yum &>/dev/null; then
                    echo ""
                    echo -e "${COLOR_CYAN}${INFO_MARK} Installing pnpm for CentOS...${COLOR_RESET}"
                    sudo yum install pnpm
                elif command -v pacman &>/dev/null; then
                    echo ""
                    echo -e "${COLOR_CYAN}${INFO_MARK} Installing pnpm for Arch Linux...${COLOR_RESET}"
                    sudo pacman -S pnpm
                elif command -v zypper &>/dev/null; then
                    echo ""
                    echo -e "${COLOR_CYAN}${INFO_MARK} Installing pnpm for OpenSUSE...${COLOR_RESET}"
                    sudo zypper install pnpm
                else
                    echo ""
                    echo -e "${COLOR_RED}${CROSS_MARK} Unsupported package manager. Please install pnpm manually.${COLOR_RESET}"
                    exit 1
                fi
                ;;
            esac
}

install_yarn() {
  case $(uname -s) in
            Darwin)
                echo ""
                echo -e "${COLOR_CYAN}${INFO_MARK} Installing yarn for macOS...${COLOR_RESET}"
                brew install yarn
                ;;
            Linux)
                if [ -f /etc/lsb-release ]; then
                    echo ""
                    echo -e "${COLOR_CYAN}${INFO_MARK} Installing yarn for Ubuntu/Debian...${COLOR_RESET}"
                    sudo apt-get install yarn
                elif [ -f /etc/fedora-release ]; then
                    echo ""
                    echo -e "${COLOR_CYAN}${INFO_MARK} Installing yarn for Fedora...${COLOR_RESET}"
                    sudo dnf install yarn
                elif [ -f /etc/centos-release ]; then
                    echo ""
                    echo -e "${COLOR_CYAN}${INFO_MARK} Installing yarn for CentOS...${COLOR_RESET}"
                    sudo yum install yarn
                elif [ -f /etc/arch-release ]; then
                    echo ""
                    echo -e "${COLOR_CYAN}${INFO_MARK} Installing yarn for Arch Linux...${COLOR_RESET}"
                    sudo pacman -S yarn
                elif [ -f /etc/SuSE-release ]; then
                    echo ""
                    echo -e "${COLOR_CYAN}${INFO_MARK} Installing yarn for OpenSUSE...${COLOR_RESET}"
                    sudo zypper install yarn
                else
                    echo ""
                    echo -e "${COLOR_RED}${CROSS_MARK} Unsupported operating system. Please install yarn manually.${COLOR_RESET}"
                    exit 1
                fi
                ;;
            *)
                echo ""
                echo -e "${COLOR_RED}${CROSS_MARK} Unsupported operating system. Please install yarn manually.${COLOR_RESET}"
                exit 1
                ;;
            esac
}

install_npm(){
  case $(uname -s) in
            Darwin)
                echo ""
                echo -e "${COLOR_CYAN}${INFO_MARK} Installing npm for macOS...${COLOR_RESET}"
                brew install npm
                ;;
            Linux)
                if [ -f /etc/lsb-release ]; then
                    echo ""
                    echo -e "${COLOR_CYAN}${INFO_MARK} Installing npm for Ubuntu/Debian...${COLOR_RESET}"
                    sudo apt-get install npm
                elif [ -f /etc/fedora-release ]; then
                    echo ""
                    echo -e "${COLOR_CYAN}${INFO_MARK} Installing npm for Fedora...${COLOR_RESET}"
                    sudo dnf install npm
                else
                    echo ""
                    echo -e "${COLOR_RED}${CROSS_MARK} Unsupported operating system. Please install npm manually.${COLOR_RESET}"
                    exit 1
                fi
                ;;
            *)
                echo ""
                echo -e "${COLOR_RED}${CROSS_MARK} Unsupported operating system. Please install npm manually.${COLOR_RESET}"
                exit 1
                ;;
            esac
}

install_ruby(){
  case $(uname -s) in
            Darwin)
                echo ""
                echo -e "${COLOR_CYAN}${INFO_MARK} Installing Ruby for macOS...${COLOR_RESET}"
                brew install ruby
                ;;
            Linux)
                if [ -f /etc/lsb-release ]; then
                    echo ""
                    echo -e "${COLOR_CYAN}${INFO_MARK} Installing Ruby for Ubuntu/Debian...${COLOR_RESET}"
                    sudo apt-get install ruby
                elif [ -f /etc/fedora-release ]; then
                    echo ""
                    echo -e "${COLOR_CYAN}${INFO_MARK} Installing Ruby for Fedora...${COLOR_RESET}"
                    sudo dnf install ruby
                elif [ -f /etc/centos-release ]; then
                    echo ""
                    echo -e "${COLOR_CYAN}${INFO_MARK} Installing Ruby for CentOS...${COLOR_RESET}"
                    sudo yum install ruby
                elif [ -f /etc/arch-release ]; then
                    echo ""
                    echo -e "${COLOR_CYAN}${INFO_MARK} Installing Ruby for Arch Linux...${COLOR_RESET}"
                    sudo pacman -S ruby
                elif [ -f /etc/SuSE-release ]; then
                    echo ""
                    echo -e "${COLOR_CYAN}${INFO_MARK} Installing Ruby for OpenSUSE...${COLOR_RESET}"
                    sudo zypper install ruby
                else
                    echo ""
                    echo -e "${COLOR_RED}${CROSS_MARK} Unsupported operating system. Please install Ruby manually.${COLOR_RESET}"
                    exit 1
                fi
                ;;
            esac
}

install_java(){
   case $(uname -s) in
            Darwin)
                echo ""
                echo -e "${COLOR_CYAN}${INFO_MARK} Installing Java for macOS...${COLOR_RESET}"
                brew install openjdk
                ;;
            Linux)
                if [ -f /etc/lsb-release ]; then
                    echo ""
                    echo -e "${COLOR_CYAN}${INFO_MARK} Installing Java for Ubuntu/Debian...${COLOR_RESET}"
                    sudo apt-get install openjdk-11-jdk
                elif [ -f /etc/fedora-release ]; then
                    echo ""
                    echo -e "${COLOR_CYAN}${INFO_MARK} Installing Java for Fedora...${COLOR_RESET}"
                    sudo dnf install java-11-openjdk
                elif [ -f /etc/centos-release ]; then
                    echo ""
                    echo -e "${COLOR_CYAN}${INFO_MARK} Installing Java for CentOS...${COLOR_RESET}"
                    sudo yum install java-11-openjdk
                else
                    echo ""
                    echo -e "${COLOR_RED}${CROSS_MARK} Unsupported operating system. Please install Java manually.${COLOR_RESET}"
                    exit 1
                fi
                ;;
            *)
                echo ""
                echo -e "${COLOR_RED}${CROSS_MARK} Unsupported operating system. Please install Java manually.${COLOR_RESET}"
                exit 1
                ;;
            esac
}

install_go(){
     case $(uname -s) in
            Darwin)
                echo ""
                echo -e "${COLOR_CYAN}${INFO_MARK} Installing Go for macOS...${COLOR_RESET}"
                brew install go
                ;;
            Linux)
                if [ -f /etc/lsb-release ]; then
                    echo ""
                    echo -e "${COLOR_CYAN}${INFO_MARK} Installing Go for Ubuntu/Debian...${COLOR_RESET}"
                    sudo apt-get install golang
                elif [ -f /etc/fedora-release ]; then
                    echo ""
                    echo -e "${COLOR_CYAN}${INFO_MARK} Installing Go for Fedora...${COLOR_RESET}"
                    sudo dnf install golang
                elif [ -f /etc/centos-release ]; then
                    echo ""
                    echo -e "${COLOR_CYAN}${INFO_MARK} Installing Go for CentOS...${COLOR_RESET}"
                    sudo yum install golang
                else
                    echo ""
                    echo -e "${COLOR_RED}${CROSS_MARK} Unsupported operating system. Please install Go manually.${COLOR_RESET}"
                    exit 1
                fi
                ;;
            *)
                echo ""
                echo -e "${COLOR_RED}${CROSS_MARK} Unsupported operating system. Please install Go manually.${COLOR_RESET}"
                exit 1
                ;;
            esac
}

install_gcc(){
   case $(uname -s) in
            Darwin)
                echo ""
                echo -e "${COLOR_CYAN}${INFO_MARK} Installing GCC for macOS...${COLOR_RESET}"
                brew install gcc
                ;;
            Linux)
                if [ -f /etc/lsb-release ]; then
                    echo ""
                    echo -e "${COLOR_CYAN}${INFO_MARK} Installing GCC for Ubuntu/Debian...${COLOR_RESET}"
                    sudo apt-get install gcc
                elif [ -f /etc/fedora-release ]; then
                    echo ""
                    echo -e "${COLOR_CYAN}${INFO_MARK} Installing GCC for Fedora...${COLOR_RESET}"
                    sudo dnf install gcc
                elif [ -f /etc/centos-release ]; then
                    echo ""
                    echo -e "${COLOR_CYAN}${INFO_MARK} Installing GCC for CentOS...${COLOR_RESET}"
                    sudo yum install gcc
                else
                    echo ""
                    echo -e "${COLOR_RED}${CROSS_MARK} Unsupported operating system. Please install GCC manually.${COLOR_RESET}"
                    exit 1
                fi
                ;;
            *)
                echo ""
                echo -e "${COLOR_RED}${CROSS_MARK} Unsupported operating system. Please install GCC manually.${COLOR_RESET}"
                exit 1
                ;;
            esac
}