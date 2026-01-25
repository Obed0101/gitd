#!/bin/bash
# GITD Installer v2.0
# Interactive installer with backup, restore, and configuration support

set -e

# =============================================================================
# CONFIGURATION
# =============================================================================

GITD_VERSION="2.0.0"
GITD_REPO="https://github.com/Obed0101/gitd.git"
GITD_INSTALL_DIR="${GITD_INSTALL:-$HOME/.gitd}"

# Temporary directory for installer modules
INSTALLER_TMP=""

# Rollback stack
declare -a ROLLBACK_STACK=()

# =============================================================================
# INLINE UI FUNCTIONS (before cloning)
# =============================================================================

setup_colors() {
    if [ -t 1 ] && [ -z "$NO_COLOR" ]; then
        COLOR_RED='\033[1;31m'
        COLOR_GREEN='\033[1;32m'
        COLOR_YELLOW='\033[1;33m'
        COLOR_BLUE='\033[1;34m'
        COLOR_MAGENTA='\033[1;35m'
        COLOR_CYAN='\033[1;36m'
        COLOR_WHITE='\033[1;37m'
        COLOR_GRAY='\033[0;90m'
        COLOR_RESET='\033[0m'
        COLOR_BOLD='\033[1m'

        ICON_CHECK="✔"
        ICON_CROSS="✖"
        ICON_ARROW="❯"
        ICON_INFO="ℹ"
        ICON_WARN="⚠"
        ICON_ROCKET="🚀"
        ICON_GEAR="⚙"
        ICON_FOLDER="📁"
        ICON_PACKAGE="📦"
    else
        COLOR_RED=''
        COLOR_GREEN=''
        COLOR_YELLOW=''
        COLOR_BLUE=''
        COLOR_MAGENTA=''
        COLOR_CYAN=''
        COLOR_WHITE=''
        COLOR_GRAY=''
        COLOR_RESET=''
        COLOR_BOLD=''

        ICON_CHECK="[OK]"
        ICON_CROSS="[X]"
        ICON_ARROW=">"
        ICON_INFO="[i]"
        ICON_WARN="[!]"
        ICON_ROCKET="[R]"
        ICON_GEAR="[G]"
        ICON_FOLDER="[F]"
        ICON_PACKAGE="[P]"
    fi
}

show_banner() {
    echo -e "${COLOR_CYAN}"
    cat << 'EOF'
   ██████╗ ██╗████████╗██████╗
  ██╔════╝ ██║╚══██╔══╝██╔══██╗
  ██║  ███╗██║   ██║   ██║  ██║
  ██║   ██║██║   ██║   ██║  ██║
  ╚██████╔╝██║   ██║   ██████╔╝
   ╚═════╝ ╚═╝   ╚═╝   ╚═════╝
EOF
    echo -e "${COLOR_RESET}"
    echo -e "${COLOR_GRAY}  Git Download Tool ${COLOR_WHITE}v${GITD_VERSION}${COLOR_RESET}"
    echo ""
}

msg_info() { echo -e "${COLOR_BLUE}${ICON_INFO}${COLOR_RESET} $1"; }
msg_success() { echo -e "${COLOR_GREEN}${ICON_CHECK}${COLOR_RESET} $1"; }
msg_warning() { echo -e "${COLOR_YELLOW}${ICON_WARN}${COLOR_RESET} $1"; }
msg_error() { echo -e "${COLOR_RED}${ICON_CROSS}${COLOR_RESET} $1"; }
msg_step() { echo -e "${COLOR_CYAN}${ICON_ARROW}${COLOR_RESET} $1"; }

# Interactive menu selector
select_menu() {
    local title="$1"
    shift
    local options=("$@")
    local selected=0
    local total=${#options[@]}

    if [ ! -t 0 ] || [ ! -t 1 ]; then
        echo "0"
        return
    fi

    tput civis 2>/dev/null
    trap 'tput cnorm 2>/dev/null; tput sgr0 2>/dev/null' EXIT INT TERM
    tput sc 2>/dev/null

    while true; do
        tput rc 2>/dev/null
        tput ed 2>/dev/null

        echo -e "${COLOR_CYAN}┌─────────────────────────────────────────────┐${COLOR_RESET}"
        echo -e "${COLOR_CYAN}│${COLOR_RESET} ${COLOR_BOLD}${title}${COLOR_RESET}"
        echo -e "${COLOR_CYAN}├─────────────────────────────────────────────┤${COLOR_RESET}"

        for i in "${!options[@]}"; do
            if [[ $i -eq $selected ]]; then
                echo -e "${COLOR_CYAN}│${COLOR_RESET}   ${COLOR_GREEN}${ICON_ARROW}${COLOR_RESET} ${COLOR_WHITE}${options[$i]}${COLOR_RESET}"
            else
                echo -e "${COLOR_CYAN}│${COLOR_RESET}     ${COLOR_GRAY}${options[$i]}${COLOR_RESET}"
            fi
        done

        echo -e "${COLOR_CYAN}└─────────────────────────────────────────────┘${COLOR_RESET}"
        echo -e "${COLOR_GRAY}  ↑/↓ Navigate  Enter Select  q Quit${COLOR_RESET}"

        local key
        IFS= read -rsn1 key

        case "$key" in
            $'\x1b')
                read -rsn2 -t 0.1 key
                case "$key" in
                    '[A') ((selected > 0)) && ((selected--)) ;;
                    '[B') ((selected < total - 1)) && ((selected++)) ;;
                esac
                ;;
            'k'|'K') ((selected > 0)) && ((selected--)) ;;
            'j'|'J') ((selected < total - 1)) && ((selected++)) ;;
            ''|$'\n') break ;;
            'q'|'Q')
                tput cnorm 2>/dev/null
                echo "-1"
                return 1
                ;;
            [1-9])
                if ((key <= total)); then
                    selected=$((key - 1))
                    break
                fi
                ;;
        esac
    done

    tput cnorm 2>/dev/null
    echo "$selected"
}

confirm() {
    local prompt="$1"
    local default="${2:-y}"
    local yn_hint="[Y/n]"
    [[ ! "$default" =~ ^[Yy] ]] && yn_hint="[y/N]"

    echo -en "${COLOR_BLUE}?${COLOR_RESET} ${prompt} ${COLOR_GRAY}${yn_hint}${COLOR_RESET} "
    local response
    read -r response
    response=${response:-$default}
    [[ "$response" =~ ^[Yy] ]]
}

input_text() {
    local prompt="$1"
    local default="$2"

    if [[ -n "$default" ]]; then
        echo -en "${COLOR_BLUE}?${COLOR_RESET} ${prompt} ${COLOR_GRAY}[${default}]${COLOR_RESET}: "
    else
        echo -en "${COLOR_BLUE}?${COLOR_RESET} ${prompt}: "
    fi

    local value
    read -r value
    echo "${value:-$default}"
}

# =============================================================================
# ROLLBACK MECHANISM
# =============================================================================

rollback_push() {
    ROLLBACK_STACK+=("$1")
}

rollback_execute() {
    msg_warning "Rolling back changes..."
    for ((i=${#ROLLBACK_STACK[@]}-1; i>=0; i--)); do
        eval "${ROLLBACK_STACK[$i]}" 2>/dev/null || true
    done
    ROLLBACK_STACK=()
}

rollback_clear() {
    ROLLBACK_STACK=()
}

# =============================================================================
# SHELL DETECTION & CONFIG
# =============================================================================

detect_shell() {
    basename "${SHELL:-/bin/bash}"
}

get_rc_file() {
    local shell_type="${1:-$(detect_shell)}"
    case "$shell_type" in
        bash)
            if [[ -f "$HOME/.bash_profile" && "$(uname)" == "Darwin" ]]; then
                echo "$HOME/.bash_profile"
            else
                echo "$HOME/.bashrc"
            fi
            ;;
        zsh)  echo "$HOME/.zshrc" ;;
        fish) echo "$HOME/.config/fish/config.fish" ;;
        *)    echo "$HOME/.profile" ;;
    esac
}

backup_rc_file() {
    local rc_file="$1"
    # Store backups in home directory to avoid deletion during clone
    local backup_dir="$HOME/.gitd-backups"
    local timestamp
    timestamp=$(date +%Y-%m-%dT%H-%M-%S)

    mkdir -p "$backup_dir"

    if [[ -f "$rc_file" ]]; then
        local backup_path="${backup_dir}/$(basename "$rc_file").${timestamp}"
        cp "$rc_file" "$backup_path"
        echo "$backup_path"
    fi
}

create_minimal_rc() {
    local rc_file="$1"
    local shell_type="${2:-bash}"

    mkdir -p "$(dirname "$rc_file")"

    case "$shell_type" in
        zsh)
            cat > "$rc_file" << 'ZSHRC'
# Zsh configuration - Created by gitd
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS SHARE_HISTORY
export PATH="$HOME/.local/bin:$PATH"
autoload -Uz compinit && compinit
PROMPT='%F{cyan}%~%f %# '
ZSHRC
            ;;
        fish)
            cat > "$rc_file" << 'FISHRC'
# Fish configuration - Created by gitd
set -g fish_history_max 10000
fish_add_path $HOME/.local/bin
FISHRC
            ;;
        *)
            cat > "$rc_file" << 'BASHRC'
# Bash configuration - Created by gitd
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoredups:erasedups
export PATH="$HOME/.local/bin:$PATH"
PS1='\[\033[01;34m\]\w\[\033[00m\]\$ '
BASHRC
            ;;
    esac
}

update_rc_file() {
    local rc_file="$1"
    local gitd_install="$2"
    local shell_type="${3:-bash}"

    local section_start="# === GITD START ==="
    local section_end="# === GITD END ==="

    # Remove existing section if present
    if [[ -f "$rc_file" ]] && grep -q "$section_start" "$rc_file" 2>/dev/null; then
        local tmp
        tmp=$(mktemp)
        awk "/$section_start/,/$section_end/ { next } { print }" "$rc_file" > "$tmp"
        mv "$tmp" "$rc_file"
    fi

    # Create file if doesn't exist
    [[ ! -f "$rc_file" ]] && touch "$rc_file"

    # Get source file based on shell
    local source_file
    case "$shell_type" in
        zsh)  source_file="\$GITD_INSTALL/src/zsh/gitd.zsh" ;;
        fish) source_file="\$GITD_INSTALL/src/fish/gitd.fish" ;;
        *)    source_file="\$GITD_INSTALL/src/bash/gitd.bash" ;;
    esac

    # Append gitd configuration (GITD_BASE_DIR is now read from config.json inside gitd scripts)
    cat >> "$rc_file" << EOF

${section_start}
# gitd - Git Download Tool v${GITD_VERSION}
export GITD_INSTALL="${gitd_install}"
source "${source_file}"
${section_end}
EOF
}

# =============================================================================
# CONFIG FILE
# =============================================================================

create_config() {
    local js_pm="${1:-bun}"
    local py_pm="${2:-uv}"
    local repos_dir="${3:-~/Repos}"

    mkdir -p "$GITD_INSTALL_DIR"

    cat > "${GITD_INSTALL_DIR}/config.json" << EOF
{
  "version": "${GITD_VERSION}",
  "repos": {
    "baseDir": "${repos_dir}",
    "organizeByOwner": false,
    "removeGitDir": true
  },
  "packageManagers": {
    "javascript": "${js_pm}",
    "typescript": "${js_pm}",
    "python": "${py_pm}",
    "ruby": "bundle",
    "java": "mvn",
    "go": "go",
    "rust": "cargo",
    "php": "composer"
  },
  "setup": {
    "autoInstallDeps": true,
    "autoDetectProject": true,
    "confirmBeforeInstall": true
  },
  "shell": {
    "modifyRcFile": true,
    "createBackups": true
  },
  "ui": {
    "showBanner": true,
    "useColors": true
  }
}
EOF
}

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

check_dependencies() {
    local missing=()

    if ! command -v git &>/dev/null; then
        missing+=("git")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        msg_error "Missing required dependencies: ${missing[*]}"
        echo ""
        echo "Please install them and try again."
        exit 1
    fi

    # Optional: warn about jq
    if ! command -v jq &>/dev/null; then
        msg_warning "jq not found - using fallback config parser"
    fi
}

clone_gitd() {
    local target="$1"

    if [[ -d "$target" ]]; then
        rm -rf "$target"
    fi

    msg_step "Cloning gitd repository..."

    if git clone --depth 1 "$GITD_REPO" "$target" 2>/dev/null; then
        msg_success "Repository cloned successfully"
        return 0
    else
        msg_error "Failed to clone repository"
        return 1
    fi
}

# =============================================================================
# INSTALLATION MODES
# =============================================================================

install_quick() {
    msg_info "Quick Install - Using recommended settings"
    echo ""

    local shell_type
    shell_type=$(detect_shell)
    local rc_file
    rc_file=$(get_rc_file "$shell_type")

    # Step 1: Backup
    msg_step "Creating backup of shell configuration..."
    local backup_path=""
    if [[ -f "$rc_file" ]]; then
        backup_path=$(backup_rc_file "$rc_file")
        rollback_push "cp '$backup_path' '$rc_file'"
        msg_success "Backup created: $backup_path"
    fi

    # Step 2: Clone
    if ! clone_gitd "$GITD_INSTALL_DIR"; then
        rollback_execute
        exit 1
    fi
    rollback_push "rm -rf '$GITD_INSTALL_DIR'"

    # Step 3: Create config
    msg_step "Creating configuration..."
    create_config "bun" "uv" "~/Repos"
    msg_success "Configuration created"

    # Step 4: Update RC
    msg_step "Updating shell configuration..."
    update_rc_file "$rc_file" "$GITD_INSTALL_DIR" "$shell_type"
    msg_success "Shell configuration updated"

    # Success
    rollback_clear
    show_success_message "$shell_type" "$rc_file"
}

install_custom() {
    msg_info "Custom Install - Configure your preferences"
    echo ""

    # Shell selection
    local shell_choice
    shell_choice=$(select_menu "Select your shell" \
        "bash" \
        "zsh" \
        "fish" \
        "Auto-detect ($(detect_shell))")

    clear
    show_banner

    local shell_type
    case "$shell_choice" in
        0) shell_type="bash" ;;
        1) shell_type="zsh" ;;
        2) shell_type="fish" ;;
        *) shell_type=$(detect_shell) ;;
    esac

    local rc_file
    rc_file=$(get_rc_file "$shell_type")

    # RC file handling
    echo ""
    local rc_choice
    if [[ -f "$rc_file" ]]; then
        rc_choice=$(select_menu "Shell configuration ($rc_file exists)" \
            "Add to existing file (recommended)" \
            "Skip - I'll configure manually")
    else
        rc_choice=$(select_menu "Shell configuration ($rc_file not found)" \
            "Create new minimal RC file (recommended)" \
            "Skip - I'll configure manually")
    fi

    clear
    show_banner

    local modify_rc=true
    local create_new_rc=false
    case "$rc_choice" in
        0)
            modify_rc=true
            [[ ! -f "$rc_file" ]] && create_new_rc=true
            ;;
        1) modify_rc=false ;;
    esac

    # Default JS package manager
    echo ""
    local js_choice
    js_choice=$(select_menu "Default JavaScript package manager" \
        "bun (fastest, recommended)" \
        "pnpm (disk efficient)" \
        "yarn" \
        "npm (most compatible)")

    clear
    show_banner

    local js_pm
    case "$js_choice" in
        0) js_pm="bun" ;;
        1) js_pm="pnpm" ;;
        2) js_pm="yarn" ;;
        *) js_pm="npm" ;;
    esac

    # Default Python package manager
    echo ""
    local py_choice
    py_choice=$(select_menu "Default Python package manager" \
        "uv (fastest, recommended)" \
        "pip (standard)" \
        "poetry" \
        "pipenv")

    clear
    show_banner

    local py_pm
    case "$py_choice" in
        0) py_pm="uv" ;;
        1) py_pm="pip" ;;
        2) py_pm="poetry" ;;
        *) py_pm="pipenv" ;;
    esac

    # Repos directory
    echo ""
    local repos_dir
    repos_dir=$(input_text "Repositories directory" "~/Repos")

    echo ""

    # Confirmation
    echo -e "${COLOR_CYAN}┌─────────────────────────────────────────────┐${COLOR_RESET}"
    echo -e "${COLOR_CYAN}│${COLOR_RESET} ${COLOR_BOLD}Installation Summary${COLOR_RESET}"
    echo -e "${COLOR_CYAN}├─────────────────────────────────────────────┤${COLOR_RESET}"
    echo -e "${COLOR_CYAN}│${COLOR_RESET}   Shell:          ${COLOR_WHITE}${shell_type}${COLOR_RESET}"
    echo -e "${COLOR_CYAN}│${COLOR_RESET}   RC File:        ${COLOR_WHITE}${rc_file}${COLOR_RESET}"
    echo -e "${COLOR_CYAN}│${COLOR_RESET}   Modify RC:      ${COLOR_WHITE}${modify_rc}${COLOR_RESET}"
    echo -e "${COLOR_CYAN}│${COLOR_RESET}   JS Manager:     ${COLOR_WHITE}${js_pm}${COLOR_RESET}"
    echo -e "${COLOR_CYAN}│${COLOR_RESET}   Python Manager: ${COLOR_WHITE}${py_pm}${COLOR_RESET}"
    echo -e "${COLOR_CYAN}│${COLOR_RESET}   Repos Dir:      ${COLOR_WHITE}${repos_dir}${COLOR_RESET}"
    echo -e "${COLOR_CYAN}└─────────────────────────────────────────────┘${COLOR_RESET}"
    echo ""

    if ! confirm "Proceed with installation?"; then
        msg_warning "Installation cancelled"
        exit 0
    fi

    echo ""

    # Step 1: Backup (if modifying)
    if $modify_rc && [[ -f "$rc_file" ]]; then
        msg_step "Creating backup of shell configuration..."
        local backup_path
        backup_path=$(backup_rc_file "$rc_file")
        rollback_push "cp '$backup_path' '$rc_file'"
        msg_success "Backup created: $backup_path"
    fi

    # Step 2: Clone
    if ! clone_gitd "$GITD_INSTALL_DIR"; then
        rollback_execute
        exit 1
    fi
    rollback_push "rm -rf '$GITD_INSTALL_DIR'"

    # Step 3: Create config
    msg_step "Creating configuration..."
    create_config "$js_pm" "$py_pm" "$repos_dir"
    msg_success "Configuration created"

    # Step 4: Update RC (if requested)
    if $modify_rc; then
        if $create_new_rc; then
            msg_step "Creating minimal shell configuration..."
            create_minimal_rc "$rc_file" "$shell_type"
        fi
        msg_step "Updating shell configuration..."
        update_rc_file "$rc_file" "$GITD_INSTALL_DIR" "$shell_type"
        msg_success "Shell configuration updated"
    fi

    # Success
    rollback_clear
    show_success_message "$shell_type" "$rc_file" "$modify_rc"
}

upgrade_existing() {
    if [[ ! -d "$GITD_INSTALL_DIR" ]]; then
        msg_error "No existing installation found at $GITD_INSTALL_DIR"
        exit 1
    fi

    msg_info "Upgrading existing installation..."
    echo ""

    # Backup config
    if [[ -f "${GITD_INSTALL_DIR}/config.json" ]]; then
        cp "${GITD_INSTALL_DIR}/config.json" "${GITD_INSTALL_DIR}/config.json.backup"
        msg_success "Config backed up"
    fi

    # Pull latest
    msg_step "Pulling latest changes..."
    if cd "$GITD_INSTALL_DIR" && git pull origin main 2>/dev/null; then
        msg_success "Updated to latest version"
    else
        # If git pull fails, do fresh clone
        msg_warning "Git pull failed, doing fresh install..."
        local config_backup=""
        [[ -f "${GITD_INSTALL_DIR}/config.json.backup" ]] && \
            config_backup=$(cat "${GITD_INSTALL_DIR}/config.json.backup")

        rm -rf "$GITD_INSTALL_DIR"
        clone_gitd "$GITD_INSTALL_DIR"

        # Restore config
        if [[ -n "$config_backup" ]]; then
            echo "$config_backup" > "${GITD_INSTALL_DIR}/config.json"
            msg_success "Config restored"
        fi
    fi

    echo ""
    msg_success "Upgrade complete!"
    msg_info "Restart your terminal or run: source $(get_rc_file)"
}

uninstall() {
    msg_warning "Uninstalling gitd..."
    echo ""

    if [[ ! -d "$GITD_INSTALL_DIR" ]]; then
        msg_info "gitd is not installed"
        exit 0
    fi

    if ! confirm "Are you sure you want to uninstall gitd?" "n"; then
        msg_info "Uninstall cancelled"
        exit 0
    fi

    echo ""

    # Remove from shell configs
    for shell_type in bash zsh fish; do
        local rc_file
        rc_file=$(get_rc_file "$shell_type")
        if [[ -f "$rc_file" ]] && grep -q "GITD START" "$rc_file" 2>/dev/null; then
            msg_step "Removing from $rc_file..."
            local tmp
            tmp=$(mktemp)
            awk '/# === GITD START ===/,/# === GITD END ===/ { next } { print }' "$rc_file" > "$tmp"
            mv "$tmp" "$rc_file"
            msg_success "Removed from $rc_file"
        fi
    done

    # Remove directory
    msg_step "Removing $GITD_INSTALL_DIR..."
    rm -rf "$GITD_INSTALL_DIR"
    msg_success "Directory removed"

    echo ""
    msg_success "gitd has been uninstalled"
    msg_info "Restart your terminal to complete uninstallation"
}

show_success_message() {
    local shell_type="$1"
    local rc_file="$2"
    local modified_rc="${3:-true}"

    echo ""
    echo -e "${COLOR_GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo -e "${COLOR_GREEN}${ICON_ROCKET}${COLOR_RESET} ${COLOR_BOLD}Installation Complete!${COLOR_RESET}"
    echo -e "${COLOR_GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo ""
    echo -e "${COLOR_CYAN}${ICON_FOLDER}${COLOR_RESET} Install location: ${COLOR_WHITE}${GITD_INSTALL_DIR}${COLOR_RESET}"
    echo -e "${COLOR_CYAN}${ICON_GEAR}${COLOR_RESET} Config file:      ${COLOR_WHITE}${GITD_INSTALL_DIR}/config.json${COLOR_RESET}"
    echo ""

    if [[ "$modified_rc" == "true" ]]; then
        echo -e "${COLOR_YELLOW}${ICON_WARN}${COLOR_RESET} To start using gitd, run:"
        echo ""
        echo -e "    ${COLOR_WHITE}source ${rc_file}${COLOR_RESET}"
        echo ""
        echo "Or restart your terminal."
    else
        echo -e "${COLOR_YELLOW}${ICON_WARN}${COLOR_RESET} Manual configuration required!"
        echo ""
        echo "Add the following to your shell configuration:"
        echo ""
        echo -e "${COLOR_GRAY}# === GITD START ===${COLOR_RESET}"
        echo -e "${COLOR_WHITE}export GITD_INSTALL=\"${GITD_INSTALL_DIR}\"${COLOR_RESET}"
        echo -e "${COLOR_WHITE}source \"\$GITD_INSTALL/src/${shell_type}/gitd.${shell_type}\"${COLOR_RESET}"
        echo -e "${COLOR_GRAY}# === GITD END ===${COLOR_RESET}"
    fi

    echo ""
    echo -e "${COLOR_CYAN}${ICON_PACKAGE}${COLOR_RESET} Quick start:"
    echo ""
    echo -e "    ${COLOR_WHITE}gitd https://github.com/user/repo${COLOR_RESET}"
    echo -e "    ${COLOR_WHITE}gitd -s https://github.com/user/repo${COLOR_RESET}  # with setup"
    echo ""
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    setup_colors

    # Handle flags
    case "${1:-}" in
        --version|-v)
            echo "gitd installer v${GITD_VERSION}"
            exit 0
            ;;
        --help|-h)
            echo "Usage: ./install.sh [options]"
            echo ""
            echo "Options:"
            echo "  --quick, -q     Quick install with defaults"
            echo "  --uninstall     Remove gitd"
            echo "  --upgrade       Upgrade existing installation"
            echo "  --version, -v   Show version"
            echo "  --help, -h      Show this help"
            exit 0
            ;;
        --quick|-q)
            show_banner
            check_dependencies
            install_quick
            exit 0
            ;;
        --uninstall)
            show_banner
            uninstall
            exit 0
            ;;
        --upgrade)
            show_banner
            upgrade_existing
            exit 0
            ;;
    esac

    # Interactive mode
    clear
    show_banner
    check_dependencies

    # Check for existing installation
    if [[ -d "$GITD_INSTALL_DIR" ]]; then
        msg_warning "Existing installation detected at $GITD_INSTALL_DIR"
        echo ""

        local upgrade_choice
        upgrade_choice=$(select_menu "What would you like to do?" \
            "Upgrade existing installation" \
            "Fresh install (overwrites existing)" \
            "Uninstall" \
            "Exit")

        clear
        show_banner

        case "$upgrade_choice" in
            0) upgrade_existing; exit 0 ;;
            1) ;; # Continue with install
            2) uninstall; exit 0 ;;
            *) exit 0 ;;
        esac
    fi

    # Main menu
    local choice
    choice=$(select_menu "Installation Mode" \
        "Quick Install (recommended)" \
        "Custom Install" \
        "Exit")

    clear
    show_banner

    case "$choice" in
        0) install_quick ;;
        1) install_custom ;;
        *) msg_info "Installation cancelled"; exit 0 ;;
    esac
}

# Run
main "$@"
