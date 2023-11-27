#!/bin/sh

  if [ -t 1 ]; then
INFO_MARK="\e[1;34mi\e[0m"
CHECK_MARK="\e[1;32m✔\e[0m"
CROSS_MARK="\e[1;31m✖\e[0m"
WARNING_MARK="\e[1;33m!\e[0m"
QUESTION_MARK="\e[1;35m?\e[0m"
DOWNLOAD_MARK="\e[1;36m⬇\e[0m"

COLOR_RED='\e[1;31m'
COLOR_GREEN='\e[1;32m'
COLOR_YELLOW='\e[1;33m'
COLOR_BLUE='\e[1;34m'
COLOR_CYAN='\e[1;36m'
COLOR_RESET='\e[0m'
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

SHELL_NAME=$(basename "$SHELL")

function show_loading() {
case "$SHELL_NAME" in
  "bash")
      loading_message="$1"
      completion_message="$2"
      command_to_execute="$3"

      echo -en "\r${DOWNLOAD_MARK} ${loading_message}"

      command_output=$(eval "$command_to_execute" 2>&1)
      command_exit_status=$?

      if [ $command_exit_status -eq 0 ]; then
        echo -e "\r${completion_message}\n"
      else
        echo -e "\r${COLOR_RED}${CROSS_MARK} Error executing the command.${COLOR_RESET}\n"
      fi
    ;;
  "zsh")
    loading_message="$1"
    completion_message="$2"
    command_to_execute="$3"
    

    echo -en "\r${DOWNLOAD_MARK} ${loading_message}"

     command_output=$(eval "$command_to_execute" 2>&1)
     command_exit_status=$?

     if [ $command_exit_status -eq 0 ]; then
        echo -e "\r${completion_message}\n"
      else
        echo -e "\r${COLOR_RED}${CROSS_MARK} Error executing the command.${COLOR_RESET}"
      fi
    ;;
  *)
     echo ""
     echo -e "${COLOR_RED}${CROSS_MARK} Unknown shell.${COLOR_RESET}"

    ;;
esac

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