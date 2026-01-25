#!/bin/bash
# GITD Logging Module v1.0
# Verbose logging and debug output

# Ensure utils are loaded
if [[ -z "$COLOR_RESET" ]]; then
    source "$GITD_INSTALL/src/lib/utils.sh"
fi

# =============================================================================
# LOGGING CONFIGURATION
# =============================================================================

# Logging levels
GITD_LOG_LEVEL="${GITD_LOG_LEVEL:-info}"
GITD_VERBOSE="${GITD_VERBOSE:-false}"
GITD_DEBUG="${GITD_DEBUG:-false}"

# Log file (optional)
GITD_LOG_FILE="${GITD_LOG_FILE:-}"

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

# Internal log function
_log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Write to log file if configured
    if [[ -n "$GITD_LOG_FILE" ]]; then
        echo "[$timestamp] [$level] $message" >> "$GITD_LOG_FILE"
    fi

    # Console output based on level
    case "$level" in
        DEBUG)
            if [[ "$GITD_DEBUG" == "true" ]]; then
                echo -e "${COLOR_BLUE}[DEBUG]${COLOR_RESET} $message"
            fi
            ;;
        VERBOSE)
            if [[ "$GITD_VERBOSE" == "true" ]] || [[ "$GITD_DEBUG" == "true" ]]; then
                echo -e "${COLOR_CYAN}[VERBOSE]${COLOR_RESET} $message"
            fi
            ;;
        INFO)
            echo -e "${COLOR_CYAN}${INFO_MARK}${COLOR_RESET} $message"
            ;;
        SUCCESS)
            echo -e "${COLOR_GREEN}${CHECK_MARK}${COLOR_RESET} $message"
            ;;
        WARNING)
            echo -e "${COLOR_YELLOW}${WARNING_MARK}${COLOR_RESET} $message"
            ;;
        ERROR)
            echo -e "${COLOR_RED}${CROSS_MARK}${COLOR_RESET} $message" >&2
            ;;
    esac
}

# Public logging functions
log_debug() {
    _log "DEBUG" "$1"
}

log_verbose() {
    _log "VERBOSE" "$1"
}

log_info() {
    _log "INFO" "$1"
}

log_success() {
    _log "SUCCESS" "$1"
}

log_warning() {
    _log "WARNING" "$1"
}

log_error() {
    _log "ERROR" "$1"
}

# =============================================================================
# VERBOSE MODE HELPERS
# =============================================================================

# Enable verbose mode
enable_verbose() {
    GITD_VERBOSE="true"
    log_verbose "Verbose mode enabled"
}

# Enable debug mode
enable_debug() {
    GITD_DEBUG="true"
    GITD_VERBOSE="true"
    log_debug "Debug mode enabled"
}

# Check if verbose mode is enabled
is_verbose() {
    [[ "$GITD_VERBOSE" == "true" ]] || [[ "$GITD_DEBUG" == "true" ]]
}

# Check if debug mode is enabled
is_debug() {
    [[ "$GITD_DEBUG" == "true" ]]
}

# =============================================================================
# TIMING FUNCTIONS
# =============================================================================

# Start timer
_GITD_TIMER_START=""

timer_start() {
    _GITD_TIMER_START=$(date +%s%N)
}

# Get elapsed time in milliseconds
timer_elapsed() {
    if [[ -z "$_GITD_TIMER_START" ]]; then
        echo "0"
        return
    fi

    local end
    end=$(date +%s%N)
    local elapsed=$(( (end - _GITD_TIMER_START) / 1000000 ))
    echo "$elapsed"
}

# Log elapsed time
timer_log() {
    local label="${1:-Operation}"
    local elapsed
    elapsed=$(timer_elapsed)

    if [[ "$elapsed" -lt 1000 ]]; then
        log_verbose "$label completed in ${elapsed}ms"
    else
        local seconds=$((elapsed / 1000))
        log_verbose "$label completed in ${seconds}s"
    fi
}

# =============================================================================
# SECTION LOGGING
# =============================================================================

# Log section start
log_section_start() {
    local section="$1"

    if is_verbose; then
        echo ""
        echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
        echo -e "${COLOR_CYAN}  $section${COLOR_RESET}"
        echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    fi

    timer_start
}

# Log section end
log_section_end() {
    local section="$1"

    if is_verbose; then
        timer_log "$section"
        echo ""
    fi
}

# =============================================================================
# COMMAND LOGGING
# =============================================================================

# Log command execution
log_command() {
    local cmd="$1"
    log_debug "Executing: $cmd"
}

# Log command result
log_command_result() {
    local exit_code="$1"
    local cmd="$2"

    if [[ "$exit_code" -eq 0 ]]; then
        log_debug "Command succeeded: $cmd"
    else
        log_debug "Command failed (exit $exit_code): $cmd"
    fi
}

# =============================================================================
# CONFIG LOGGING
# =============================================================================

# Log configuration loading
log_config_loaded() {
    local config_path="$1"
    log_verbose "Loaded config: $config_path"
}

# Log configuration value
log_config_value() {
    local key="$1"
    local value="$2"
    log_debug "Config: $key = $value"
}

# =============================================================================
# SUMMARY LOGGING
# =============================================================================

# Log operation summary
log_summary() {
    local title="$1"
    shift
    local items=("$@")

    if is_verbose; then
        echo ""
        echo -e "${COLOR_CYAN}${INFO_MARK} $title:${COLOR_RESET}"
        for item in "${items[@]}"; do
            echo -e "  ${COLOR_BLUE}•${COLOR_RESET} $item"
        done
        echo ""
    fi
}

# Log stats
log_stats() {
    local label="$1"
    local value="$2"
    log_verbose "$label: $value"
}
