#!/bin/bash

source "$GITD_INSTALL/src/lib/utils.sh"

echo -e "${COLOR_CYAN}${INFO_MARK} Running setup...${COLOR_RESET}"

if [ -e package.json ]; then
    echo ""
    echo -e "${COLOR_GREEN}${CHECK_MARK} Detected npm project.${COLOR_RESET}"

    if ! command -v npm &>/dev/null; then
        echo ""
        echo "${COLOR_YELLOW}${WARNING_MARK} Warning: ${COLOR_RESET}npm is not installed."
        echo ""
        read -r "response?$(echo -e '\e[1;34m::\e[0m') Do you want to install it? [Y/n]: "
        response=${response:-Y}

        if [[ ! $response =~ ^[Yy]$ ]]; then
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
        else
            echo ""
            echo -e "${COLOR_RED}${CROSS_MARK} Please install npm manually and run the script again.${COLOR_RESET}"
            exit 1
        fi
    fi
    echo ""
    show_loading "Running npm install..." "${COLOR_GREEN}${CHECK_MARK} npm install completed successfully.${COLOR_RESET}" "npm install"

elif [ -e yarn.lock ]; then
    echo ""
    echo -e "${COLOR_GREEN}${CHECK_MARK} Detected yarn project.${COLOR_RESET}"

    if ! command -v yarn &>/dev/null; then
        echo ""
        echo "${COLOR_YELLOW}${WARNING_MARK} Warning: ${COLOR_RESET}yarn is not installed."
        echo ""
        read -r "response?$(echo -e '\e[1;34m::\e[0m') Do you want to install it? [Y/n]: "
        response=${response:-Y}

        if [[ ! $response =~ ^[Yy]$ ]]; then
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
        else
            echo ""
            echo -e "${COLOR_RED}${CROSS_MARK} Please install yarn manually and run the script again.${COLOR_RESET}"
            exit 1
        fi
    fi

    echo ""
    show_loading "Running yarn install..." "${COLOR_GREEN}${CHECK_MARK} yarn install completed successfully.${COLOR_RESET}" "yarn install "

elif [ -e pnpm-lock.yaml ]; then
    echo ""
    echo -e "${COLOR_GREEN}${CHECK_MARK} Detected pnpm project.${COLOR_RESET}"

    if ! command -v pnpm &>/dev/null; then
        echo ""
        echo "${COLOR_YELLOW}${WARNING_MARK} Warning: ${COLOR_RESET}pnpm is not installed."
        echo ""
        read -r "response?$(echo -e '\e[1;34m::\e[0m') Do you want to install it? [Y/n]: "
        response=${response:-Y}

        if [[ ! $response =~ ^[Yy]$ ]]; then
            case $(uname -s) in
            Darwin)
                echo ""
                echo -e "${COLOR_CYAN}${INFO_MARK} Installing pnpm for macOS...${COLOR_RESET}"
                brew install pnpm
                ;;
            Linux)
                if [ -f /etc/lsb-release ]; then
                    echo ""
                    echo -e "${COLOR_CYAN}${INFO_MARK} Installing pnpm for Ubuntu/Debian...${COLOR_RESET}"
                    sudo apt-get install pnpm
                elif [ -f /etc/fedora-release ]; then
                    echo ""
                    echo -e "${COLOR_CYAN}${INFO_MARK} Installing pnpm for Fedora...${COLOR_RESET}"
                    sudo dnf install pnpm
                elif [ -f /etc/centos-release ]; then
                    echo ""
                    echo -e "${COLOR_CYAN}${INFO_MARK} Installing pnpm for CentOS...${COLOR_RESET}"
                    sudo yum install pnpm
                elif [ -f /etc/arch-release ]; then
                    echo ""
                    echo -e "${COLOR_CYAN}${INFO_MARK} Installing pnpm for Arch Linux...${COLOR_RESET}"
                    sudo pacman -S pnpm
                elif [ -f /etc/SuSE-release ]; then
                    echo ""
                    echo -e "${COLOR_CYAN}${INFO_MARK} Installing pnpm for OpenSUSE...${COLOR_RESET}"
                    sudo zypper install pnpm
                else
                    echo ""
                    echo -e "${COLOR_RED}${CROSS_MARK} Unsupported operating system. Please install pnpm manually.${COLOR_RESET}"
                    exit 1
                fi
                ;;
            esac
        else
            echo ""
            echo -e "${COLOR_RED}${CROSS_MARK} Please install pnpm manually and run the script again.${COLOR_RESET}"
            exit 1
        fi
    fi

    echo ""
    show_loading "Running pnpm install..." "${COLOR_GREEN}${CHECK_MARK} pnpm install completed successfully.${COLOR_RESET}" "pnpm install"

elif [ -e Gemfile ]; then
    echo ""
    echo -e "${COLOR_GREEN}${CHECK_MARK} Detected Ruby project.${COLOR_RESET}"

    if ! command -v ruby &>/dev/null; then
        echo ""
        echo "${COLOR_YELLOW}${WARNING_MARK} Warning: ${COLOR_RESET}Ruby is not installed."
        echo ""
        read -r "response?$(echo -e '\e[1;34m::\e[0m') Do you want to install it? [Y/n]: "
        response=${response:-Y}

        if [[ ! $response =~ ^[Yy]$ ]]; then
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
        else
            echo ""
            echo -e "${COLOR_RED}${CROSS_MARK} Please install Ruby manually and run the script again.${COLOR_RESET}"
            exit 1
        fi
    fi

    echo ""
    show_loading "Running bundle install..." "${COLOR_GREEN}${CHECK_MARK} bundle install completed successfully.${COLOR_RESET}" "bundle install"

elif [ -e pom.xml ]; then
    echo ""
    echo -e "${COLOR_GREEN}${CHECK_MARK} Detected Java project.${COLOR_RESET}"

    if ! command -v java &>/dev/null; then
        echo ""
        echo "${COLOR_YELLOW}${WARNING_MARK} Warning: ${COLOR_RESET}Java is not installed."
        echo ""
        read -r "response?$(echo -e '\e[1;34m::\e[0m') Do you want to install it? [Y/n]: "
        response=${response:-Y}

        if [[ ! $response =~ ^[Yy]$ ]]; then
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
        else
            echo ""
            echo -e "${COLOR_RED}${CROSS_MARK} Please install Java manually and run the script again.${COLOR_RESET}"
            exit 1
        fi
    fi

    echo ""
    show_loading "Running Maven install..." "${COLOR_GREEN}${CHECK_MARK} Maven install completed successfully.${COLOR_RESET}" "mvn clean install install"

elif [ -e go.mod ]; then
    echo ""
    echo -e "${COLOR_GREEN}${CHECK_MARK} Detected Go project.${COLOR_RESET}"

    if ! command -v go &>/dev/null; then
        echo ""
        echo "${COLOR_YELLOW}${WARNING_MARK} Warning: ${COLOR_RESET}Go is not installed."
        echo ""
        read -r "response?$(echo -e '\e[1;34m::\e[0m') Do you want to install it? [Y/n]: "
        response=${response:-Y}

        if [[ ! $response =~ ^[Yy]$ ]]; then
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
        else
            echo ""
            echo -e "${COLOR_RED}${CROSS_MARK} Please install Go manually and run the script again.${COLOR_RESET}"
            exit 1
        fi
    fi

    echo ""
    show_loading "Running Go install..." "${COLOR_GREEN}${CHECK_MARK} Go install completed successfully.${COLOR_RESET}" "go build"

elif [ -e Makefile ]; then
    echo ""
    echo -e "${COLOR_GREEN}${CHECK_MARK} Detected C/C++ project.${COLOR_RESET}"

    if ! command -v gcc &>/dev/null; then
        echo ""
        echo "${COLOR_YELLOW}${WARNING_MARK} Warning: ${COLOR_RESET}GCC is not installed."
        echo ""
        read -r "response?$(echo -e '\e[1;34m::\e[0m') Do you want to install it? [Y/n]: "
        response=${response:-Y}

        if [[ ! $response =~ ^[Yy]$ ]]; then
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
        else
            echo ""
            echo -e "${COLOR_RED}${CROSS_MARK} Please install GCC manually and run the script again.${COLOR_RESET}"
            exit 1
        fi
    fi

    echo ""
    show_loading "Running Make..." "${COLOR_GREEN}${CHECK_MARK} Make completed successfully.${COLOR_RESET}" "make"

else
    echo ""
    echo -e "${COLOR_BLUE}${INFO_MARK} Unsupported project. No setup required.${COLOR_RESET}"
fi
