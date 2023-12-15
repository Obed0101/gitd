#!/bin/bash

source "$GITD_INSTALL/src/lib/utils.sh"

echo -e "${COLOR_CYAN}${INFO_MARK} Running setup...${COLOR_RESET}"

if [ -e pom.xml ]; then
    echo ""
    echo -e "${COLOR_GREEN}${CHECK_MARK} Detected Java project.${COLOR_RESET}"

    if ! command -v java &>/dev/null; then
        echo ""
        read -r -p "$(echo -e '\033[1;34m::\033[0m Do you want to install Java? [Y/n]: ')" response
        response=${response:-Y}

        if [[ ! $response =~ ^[Yy]$ ]]; then
            install_java
        fi
    fi

    echo ""
    show_loading "Running Maven install..." "${COLOR_GREEN}${CHECK_MARK} Maven install completed successfully.${COLOR_RESET}" "mvn clean install install"

elif [ -e Gemfile ]; then
    echo ""
    echo -e "${COLOR_GREEN}${CHECK_MARK} Detected Ruby project.${COLOR_RESET}"

    if ! command -v ruby &>/dev/null; then
        echo ""
        read -r -p "$(echo -e '\033[1;34m::\033[0m Do you want to install Ruby? [Y/n]: ')" response
        response=${response:-Y}

        if [[ ! $response =~ ^[Yy]$ ]]; then
            install_ruby
        fi
    fi

    echo ""
    show_loading "Running Bundler install..." "${COLOR_GREEN}${CHECK_MARK} Bundler install completed successfully.${COLOR_RESET}" "bundle install"

elif [ -e go.mod ]; then
    echo ""
    echo -e "${COLOR_GREEN}${CHECK_MARK} Detected Go project.${COLOR_RESET}"

    if ! command -v go &>/dev/null; then
        echo ""
        read -r -p "$(echo -e '\033[1;34m::\033[0m Do you want to install Go? [Y/n]: ')" response
        response=${response:-Y}

        if [[ ! $response =~ ^[Yy]$ ]]; then
            install_go
        fi
    fi

    echo ""
    show_loading "Running Go install..." "${COLOR_GREEN}${CHECK_MARK} Go install completed successfully.${COLOR_RESET}" "go build"

elif [ -e makefile ] || [ -e MAKEFILE ] || [ -e Makefile ]; then
    echo ""
    echo -e "${COLOR_GREEN}${CHECK_MARK} Detected C/C++ project.${COLOR_RESET}"

    if ! command -v gcc &>/dev/null; then
        echo ""
        read -r -p "$(echo -e '\033[1;34m::\033[0m Do you want to install GCC? [Y/n]: ')" response
        response=${response:-Y}

        if [[ ! $response =~ ^[Yy]$ ]]; then
            install_gcc
        fi
    fi

    echo ""
    show_loading "Running Make..." "${COLOR_GREEN}${CHECK_MARK} Make completed successfully.${COLOR_RESET}" "make"

elif [ -e pnpm-lock.yaml ]; then
    echo ""
    echo -e "${COLOR_GREEN}${CHECK_MARK} Detected pnpm project.${COLOR_RESET}"

    if ! command -v pnpm &>/dev/null; then
        echo ""
        read -r -p "$(echo -e '\033[1;33m!\033[0m Warning: \033[0mpnpm is not installed.\n\n\033[1;34m::\033[0m Do you want to install it? [Y/n]: ')" response
        response=${response:-Y}

        if [[ ! $response =~ ^[Yy]$ ]]; then
            echo ""
            echo -e "${COLOR_RED}${CROSS_MARK} Please install pnpm manually and run the script again.${COLOR_RESET}"
            exit 1
        else
            install_pnpm
        fi
    fi

    echo ""
    show_loading "Running pnpm install..." "${COLOR_GREEN}${CHECK_MARK} pnpm install completed successfully.${COLOR_RESET}" "pnpm install"

elif [ -e yarn.lock ]; then
    echo ""
    echo -e "${COLOR_GREEN}${CHECK_MARK} Detected yarn project.${COLOR_RESET}"

    if ! command -v yarn &>/dev/null; then
        echo ""
        read -r -p "$(echo -e '\033[1;33m!\033[0m Warning: \033[0myarn is not installed.\n\n\033[1;34m::\033[0m Do you want to install it? [Y/n]: ')" response
        response=${response:-Y}

        if [[ ! $response =~ ^[Yy]$ ]]; then
            install_yarn
        fi
    fi

    echo ""
    show_loading "Running yarn install..." "${COLOR_GREEN}${CHECK_MARK} yarn install completed successfully.${COLOR_RESET}" "yarn install"

elif [ -e package.json ]; then
    echo ""
    echo -e "${COLOR_GREEN}${CHECK_MARK} Detected npm project.${COLOR_RESET}"

    if ! command -v npm &>/dev/null; then
        echo ""
        read -r -p "$(echo -e '\033[1;33m!\033[0m Warning: \033[0mnpm is not installed.\n\n\033[1;34m::\033[0m Do you want to install it? [Y/n]: ')" response
        response=${response:-Y}

        if [[ ! $response =~ ^[Yy]$ ]]; then
            install_npm
        fi
    fi

    echo ""
    show_loading "Running npm install..." "${COLOR_GREEN}${CHECK_MARK} npm install completed successfully.${COLOR_RESET}" "npm install"

else
    echo ""
    echo -e "${COLOR_BLUE}${INFO_MARK} Unsupported project. No setup required.${COLOR_RESET}"
fi
