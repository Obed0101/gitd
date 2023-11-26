#!/bin/bash

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

if [ -t 1 ]; then
    INFO_MARK="\e[1;34mi\e[0m"
    CHECK_MARK="\e[1;32m✔\e[0m"
    CROSS_MARK="\e[1;31m✖\e[0m"
    WARNING_MARK="\e[1;33m!\e[0m"
    QUESTION_MARK="\e[1;35m?\e[0m"

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

    COLOR_RED=''
    COLOR_GREEN=''
    COLOR_YELLOW=''
    COLOR_BLUE=''
    COLOR_CYAN=''
    COLOR_RESET=''
fi

if [[ $1 == --version ]] || [[ $1 == -v ]] || [[ $1 == -VERSION ]]; then
    cat <<'EOF'
gitd installer 1.0
EOF
    exit 0
fi

cat <<'EOF'
 ██████╗ ██╗████████╗██████╗                                          
██╔════╝ ██║╚══██╔══╝██╔══██╗                                         
██║  ███╗██║   ██║   ██║  ██║                                         
██║   ██║██║   ██║   ██║  ██║                                         
╚██████╔╝██║   ██║   ██████╔╝                                         
 ╚═════╝ ╚═╝   ╚═╝   ╚═════╝                                          
                                                                      
██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     ███████╗██████╗ 
██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     ██╔════╝██╔══██╗
██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     █████╗  ██████╔╝
██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     ██╔══╝  ██╔══██╗
██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗███████╗██║  ██║
╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝
EOF

GITD_INSTALL_DIR="$HOME/.gitd"

echo ""
git clone --depth 1 https://github.com/xXDeathAbyssXx/gitd.git "$GITD_INSTALL_DIR"
echo ""

SHELL_NAME=$(basename "$SHELL")

if [ "$SHELL_NAME" = "bash" ]; then
    echo -e "\n# gitd\nexport GITD_INSTALL=\"$GITD_INSTALL_DIR\"\nsource \"\$GITD_INSTALL/src/bash/gitd.bash\"" >>"$HOME/.bashrc"
    echo -e "${COLOR_CYAN}${INFO_MARK} gitd has been installed for Bash.${COLOR_RESET} Please restart your terminal or run 'source ~/.bashrc'."
elif [ "$SHELL_NAME" = "zsh" ]; then
    echo -e "\n# gitd\nexport GITD_INSTALL=\"$GITD_INSTALL_DIR\"\nsource \"\$GITD_INSTALL/src/zsh/gitd.zsh\"" >>"$HOME/.zshrc"
    echo -e "${COLOR_CYAN}${INFO_MARK} gitd has been installed for Zsh.${COLOR_RESET} Please restart your terminal or run 'source ~/.zshrc'."
else
    echo -e "${COLOR_RED}${CROSS_MARK} Unsupported shell: $SHELL_NAME. Please manually configure gitd in your shell's RC file.${COLOR_RESET}"
fi

repo_size=$(gh api repos/xXDeathAbyssXx/gitd --jq '.size')

echo -e "\n${COLOR_CYAN}${INFO_MARK} gitd installation details:${COLOR_RESET}"
echo -e "${COLOR_CYAN}  • Installation directory: ${COLOR_RESET}$GITD_INSTALL_DIR"
echo -e "${COLOR_CYAN}${INFO_MARK} Repository details:${COLOR_RESET}"
echo -e "${COLOR_CYAN}  • Repository size: ${COLOR_RESET}$(format_size $repo_size)"
echo -e "${COLOR_CYAN}${INFO_MARK} Repository location:${COLOR_RESET}"
echo -e "${COLOR_GREEN}  $GITD_INSTALL_DIR${COLOR_RESET}"
