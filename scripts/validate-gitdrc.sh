#!/bin/bash
# GITD .gitdrc Configuration Validator
# Validates .gitdrc files against the JSON Schema

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SCHEMA_FILE="${REPO_ROOT}/gitdrc.schema.json"

# Print functions
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  GITD Configuration Validator${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Usage
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [FILE]

Validate .gitdrc configuration files against the JSON Schema.

Arguments:
  FILE                  Path to .gitdrc file (default: ./.gitdrc)

Options:
  -h, --help           Show this help message
  -s, --schema PATH    Path to schema file (default: ./gitdrc.schema.json)
  -v, --verbose        Show detailed validation output
  -q, --quiet          Only show errors
  --examples           Validate all example files

Examples:
  $(basename "$0")                          # Validate ./.gitdrc
  $(basename "$0") /path/to/.gitdrc         # Validate specific file
  $(basename "$0") --examples               # Validate all examples
  $(basename "$0") -v .gitdrc               # Verbose validation

EOF
    exit 0
}

# Check if jq is installed
check_jq() {
    if ! command -v jq &>/dev/null; then
        print_error "jq is not installed"
        echo ""
        echo "Install jq to use this validator:"
        echo ""
        echo "  macOS:   brew install jq"
        echo "  Ubuntu:  sudo apt-get install jq"
        echo "  Fedora:  sudo dnf install jq"
        echo ""
        exit 1
    fi
}

# Validate JSON syntax
validate_json_syntax() {
    local file="$1"

    if ! jq empty "$file" 2>/dev/null; then
        print_error "Invalid JSON syntax in: $file"
        echo ""
        echo "Details:"
        jq empty "$file" 2>&1 | sed 's/^/  /'
        return 1
    fi

    return 0
}

# Validate required version field
validate_version() {
    local file="$1"

    if ! jq -e '.version' "$file" &>/dev/null; then
        print_error "Missing required 'version' field"
        return 1
    fi

    local version
    version=$(jq -r '.version' "$file")

    if [[ "$version" != "1.0" ]]; then
        print_error "Invalid version: $version (expected '1.0')"
        return 1
    fi

    return 0
}

# Basic schema validation (without ajv)
basic_validate() {
    local file="$1"
    local errors=0

    # Check for unknown top-level keys
    local known_keys=("version" "detection" "hooks" "setup" "env" "workflows" "security" "editor" "git" "\$schema")
    local file_keys
    file_keys=$(jq -r 'keys[]' "$file")

    while IFS= read -r key; do
        local found=false
        for known in "${known_keys[@]}"; do
            if [[ "$key" == "$known" ]]; then
                found=true
                break
            fi
        done

        if ! $found; then
            print_warning "Unknown property: $key"
            ((errors++))
        fi
    done <<< "$file_keys"

    # Validate detection.language
    if jq -e '.detection.language' "$file" &>/dev/null; then
        local lang
        lang=$(jq -r '.detection.language' "$file")

        local valid_langs=(
            "javascript" "typescript" "rust" "go" "python" "ruby" "java" "scala"
            "php" "elixir" "erlang" "dotnet" "zig" "swift" "haskell" "lua"
            "dart" "nim" "ocaml" "clojure" "cpp" "vlang"
        )

        local valid=false
        for valid_lang in "${valid_langs[@]}"; do
            if [[ "$lang" == "$valid_lang" ]]; then
                valid=true
                break
            fi
        done

        if ! $valid; then
            print_warning "Invalid language: $lang"
            ((errors++))
        fi
    fi

    # Validate hook structure
    for hook in post-clone pre-setup post-setup; do
        if jq -e ".hooks.\"$hook\"" "$file" &>/dev/null; then
            if ! jq -e ".hooks.\"$hook\".commands" "$file" &>/dev/null; then
                print_error "Hook '$hook' missing required 'commands' array"
                ((errors++))
            fi
        fi
    done

    # Validate workflow names
    if jq -e '.workflows' "$file" &>/dev/null; then
        local workflow_names
        workflow_names=$(jq -r '.workflows | keys[]' "$file")

        while IFS= read -r name; do
            if ! [[ "$name" =~ ^[a-z][a-z0-9-]*$ ]]; then
                print_warning "Invalid workflow name: $name (must match ^[a-z][a-z0-9-]*$)"
                ((errors++))
            fi

            if ! jq -e ".workflows.\"$name\".steps" "$file" &>/dev/null; then
                print_error "Workflow '$name' missing required 'steps' array"
                ((errors++))
            fi
        done <<< "$workflow_names"
    fi

    return $errors
}

# Validate a single file
validate_file() {
    local file="$1"
    local verbose="${2:-false}"
    local quiet="${3:-false}"

    if [[ ! -f "$file" ]]; then
        print_error "File not found: $file"
        return 1
    fi

    if ! $quiet; then
        print_info "Validating: $file"
    fi

    # Step 1: Validate JSON syntax
    if ! validate_json_syntax "$file"; then
        return 1
    fi

    if $verbose; then
        print_success "Valid JSON syntax"
    fi

    # Step 2: Validate required version
    if ! validate_version "$file"; then
        return 1
    fi

    if $verbose; then
        print_success "Valid version field"
    fi

    # Step 3: Basic schema validation
    if ! basic_validate "$file"; then
        if ! $quiet; then
            print_warning "Validation completed with warnings"
        fi
        return 2  # Warnings, not errors
    fi

    if ! $quiet; then
        print_success "Configuration is valid"
    fi

    # Show summary if verbose
    if $verbose; then
        echo ""
        echo "Configuration summary:"

        if jq -e '.detection.language' "$file" &>/dev/null; then
            local lang
            lang=$(jq -r '.detection.language' "$file")
            echo "  Language: $lang"
        fi

        if jq -e '.detection.tool' "$file" &>/dev/null; then
            local tool
            tool=$(jq -r '.detection.tool' "$file")
            echo "  Tool: $tool"
        fi

        if jq -e '.workflows | length' "$file" &>/dev/null; then
            local count
            count=$(jq -r '.workflows | length' "$file")
            echo "  Workflows: $count"
        fi

        if jq -e '.hooks | length' "$file" &>/dev/null; then
            local count
            count=$(jq -r '.hooks | length' "$file")
            echo "  Hooks: $count"
        fi
    fi

    return 0
}

# Validate all example files
validate_examples() {
    local examples_dir="${REPO_ROOT}/examples/gitdrc"
    local total=0
    local passed=0
    local failed=0

    print_info "Validating example configurations..."
    echo ""

    if [[ ! -d "$examples_dir" ]]; then
        print_error "Examples directory not found: $examples_dir"
        return 1
    fi

    while IFS= read -r file; do
        ((total++))

        echo "[$total] $(basename "$file")"

        if validate_file "$file" false true; then
            print_success "Valid"
            ((passed++))
        else
            ((failed++))
        fi

        echo ""
    done < <(find "$examples_dir" -name "*.gitdrc" -type f)

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Results:"
    echo "  Total:   $total"
    echo -e "  ${GREEN}Passed:  $passed${NC}"

    if [[ $failed -gt 0 ]]; then
        echo -e "  ${RED}Failed:  $failed${NC}"
        return 1
    fi

    echo ""
    print_success "All examples validated successfully"
    return 0
}

# Main
main() {
    local file=".gitdrc"
    local schema="$SCHEMA_FILE"
    local verbose=false
    local quiet=false
    local validate_all_examples=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                ;;
            -s|--schema)
                schema="$2"
                shift 2
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -q|--quiet)
                quiet=true
                shift
                ;;
            --examples)
                validate_all_examples=true
                shift
                ;;
            -*)
                print_error "Unknown option: $1"
                echo ""
                usage
                ;;
            *)
                file="$1"
                shift
                ;;
        esac
    done

    print_header

    # Check dependencies
    check_jq

    # Validate all examples
    if $validate_all_examples; then
        validate_examples
        exit $?
    fi

    # Validate single file
    validate_file "$file" "$verbose" "$quiet"
    exit $?
}

main "$@"
