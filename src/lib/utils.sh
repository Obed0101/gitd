#!/bin/sh

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

SHELL_NAME=$(basename "$SHELL")

function show_loading() {
case "$SHELL_NAME" in
  "bash")
loading_message="$1"
completion_message="$2"
command_to_execute="$3"

spin="/-\|"
index=0

{
    while true; do
        echo -en "\r${spin:$index:1} ${loading_message}"
        sleep 0.1
        index=$(( (index + 1) % 4 ))
    done
} &

SPIN_PID=$!

command_output=$(eval "$command_to_execute" 2>&1)

kill $SPIN_PID

echo -e "\r${completion_message}\n"
    ;;
  "zsh")
    loading_message="$1"
    completion_message="$2"
    command_to_execute="$3"

    spin="/-\|"
    index=0

    { 
        while true; do
            echo -en "\r${spin:$index:1} ${loading_message}"
            sleep 0.1
            index=$(( (index + 1) % 4 ))
        done
    } &!

    SPIN_PID=$!

    command_output=$(eval "$command_to_execute" 2>&1)

    kill $SPIN_PID

    echo -e "\r${completion_message}\n"
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
