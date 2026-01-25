#!/bin/bash
# GITD Package Detection Module - Multi-language project detection

# =============================================================================
# DETECTION PRIORITY ORDER
# =============================================================================
# More specific lockfiles take priority over generic config files
# This ensures we use the correct package manager for the project

# Detection format: "file_pattern:language:tool:priority"
# Lower priority number = higher precedence

DETECTIONS=(
    # JavaScript/TypeScript - Lockfiles first (highest priority)
    "bun.lockb:javascript:bun:10"
    "pnpm-lock.yaml:javascript:pnpm:11"
    "yarn.lock:javascript:yarn:12"
    "package-lock.json:javascript:npm:13"

    # TypeScript config (indicates TS project, use JS package manager)
    "tsconfig.json:typescript:auto:20"

    # JavaScript generic (lowest JS priority)
    "package.json:javascript:auto:25"

    # Rust
    "Cargo.toml:rust:cargo:30"
    "Cargo.lock:rust:cargo:31"

    # Go
    "go.mod:go:go:40"
    "go.sum:go:go:41"

    # Python - Modern tools first
    "pyproject.toml:python:auto:50"
    "uv.lock:python:uv:51"
    "poetry.lock:python:poetry:52"
    "Pipfile.lock:python:pipenv:53"
    "Pipfile:python:pipenv:54"
    "requirements.txt:python:pip:55"
    "setup.py:python:pip:56"

    # Ruby
    "Gemfile.lock:ruby:bundle:60"
    "Gemfile:ruby:bundle:61"

    # Java/JVM
    "build.gradle.kts:java:gradle:70"
    "build.gradle:java:gradle:71"
    "settings.gradle:java:gradle:72"
    "pom.xml:java:mvn:73"
    "build.sbt:scala:sbt:74"

    # PHP
    "composer.lock:php:composer:80"
    "composer.json:php:composer:81"

    # Elixir/Erlang
    "mix.lock:elixir:mix:90"
    "mix.exs:elixir:mix:91"
    "rebar.lock:erlang:rebar3:92"
    "rebar.config:erlang:rebar3:93"

    # .NET
    "*.sln:dotnet:dotnet:100"
    "*.csproj:dotnet:dotnet:101"
    "*.fsproj:dotnet:dotnet:102"
    "packages.lock.json:dotnet:dotnet:103"

    # Zig
    "build.zig:zig:zig:110"
    "build.zig.zon:zig:zig:111"

    # Swift
    "Package.swift:swift:swift:120"
    "Package.resolved:swift:swift:121"

    # Haskell
    "stack.yaml:haskell:stack:130"
    "stack.yaml.lock:haskell:stack:131"
    "*.cabal:haskell:cabal:132"
    "cabal.project:haskell:cabal:133"

    # Lua
    "*.rockspec:lua:luarocks:140"

    # Dart/Flutter
    "pubspec.yaml:dart:dart:150"
    "pubspec.lock:dart:dart:151"

    # Nim
    "*.nimble:nim:nimble:160"

    # OCaml
    "dune-project:ocaml:dune:170"
    "*.opam:ocaml:opam:171"

    # Clojure
    "deps.edn:clojure:clojure:180"
    "project.clj:clojure:lein:181"

    # C/C++ - Build systems
    "CMakeLists.txt:cpp:cmake:190"
    "meson.build:cpp:meson:191"
    "Makefile:cpp:make:192"
    "makefile:cpp:make:193"
    "MAKEFILE:cpp:make:194"
    "configure.ac:cpp:autotools:195"

    # V
    "v.mod:vlang:v:200"
)

# =============================================================================
# TOOL AVAILABILITY CHECK
# =============================================================================

# Check if a tool is installed
tool_available() {
    local tool="$1"
    command -v "$tool" &>/dev/null
}

# Get fallback tool for a language
get_fallback_tool() {
    local lang="$1"
    local preferred="$2"

    case "$lang" in
        javascript|typescript)
            # Fallback chain: bun -> pnpm -> yarn -> npm
            for tool in bun pnpm yarn npm; do
                if [[ "$tool" != "$preferred" ]] && tool_available "$tool"; then
                    echo "$tool"
                    return 0
                fi
            done
            ;;
        python)
            # Fallback chain: uv -> pip -> poetry -> pipenv
            for tool in uv pip poetry pipenv; do
                if [[ "$tool" != "$preferred" ]] && tool_available "$tool"; then
                    echo "$tool"
                    return 0
                fi
            done
            ;;
        java)
            # Fallback: mvn <-> gradle
            if [[ "$preferred" == "mvn" ]] && tool_available gradle; then
                echo "gradle"
                return 0
            elif [[ "$preferred" == "gradle" ]] && tool_available mvn; then
                echo "mvn"
                return 0
            fi
            ;;
        haskell)
            # Fallback: stack <-> cabal
            if [[ "$preferred" == "stack" ]] && tool_available cabal; then
                echo "cabal"
                return 0
            elif [[ "$preferred" == "cabal" ]] && tool_available stack; then
                echo "stack"
                return 0
            fi
            ;;
    esac

    echo ""
    return 1
}

# =============================================================================
# PROJECT DETECTION
# =============================================================================

# Detect project type in directory
# Usage: result=$(detect_project "/path/to/project")
# Returns: "language:tool" or "language:tool:missing" if tool not available
detect_project() {
    local dir="${1:-.}"
    local best_match=""
    local best_priority=999

    # Source config if available
    if [[ -f "$HOME/.gitd/config.json" ]]; then
        source "${GITD_INSTALL:-$HOME/.gitd}/src/lib/config.sh" 2>/dev/null
    fi

    for detection in "${DETECTIONS[@]}"; do
        IFS=':' read -r pattern lang tool priority <<< "$detection"

        # Check if file exists (handle glob patterns)
        local found=false
        if [[ "$pattern" == *"*"* ]]; then
            # Glob pattern - use ls instead of compgen for better compatibility
            if ls "${dir}"/${pattern} >/dev/null 2>&1; then
                found=true
            fi
        else
            # Exact file
            if [[ -f "${dir}/${pattern}" ]]; then
                found=true
            fi
        fi

        if $found && ((priority < best_priority)); then
            best_priority=$priority
            best_match="${lang}:${tool}"
        fi
    done

    if [[ -z "$best_match" ]]; then
        echo "unknown:none"
        return 2
    fi

    local lang="${best_match%%:*}"
    local tool="${best_match##*:}"

    # Handle 'auto' - use config default or smart detection
    if [[ "$tool" == "auto" ]]; then
        tool=$(resolve_auto_tool "$lang" "$dir")
    fi

    # Check if tool is available
    if tool_available "$tool"; then
        echo "${lang}:${tool}"
        return 0
    else
        # Try fallback
        local fallback
        fallback=$(get_fallback_tool "$lang" "$tool")
        if [[ -n "$fallback" ]]; then
            echo "${lang}:${fallback}:fallback"
            return 0
        fi
        echo "${lang}:${tool}:missing"
        return 1
    fi
}

# Resolve 'auto' tool selection
resolve_auto_tool() {
    local lang="$1"
    local dir="$2"

    # Try config first
    local config_tool=""
    if type config_get &>/dev/null; then
        config_tool=$(config_get "packageManagers.${lang}" "")
    fi

    if [[ -n "$config_tool" ]] && tool_available "$config_tool"; then
        echo "$config_tool"
        return
    fi

    # Smart detection based on language
    case "$lang" in
        javascript|typescript)
            # Check for lockfiles to determine preferred manager
            if [[ -f "${dir}/bun.lockb" ]]; then
                echo "bun"
            elif [[ -f "${dir}/pnpm-lock.yaml" ]]; then
                echo "pnpm"
            elif [[ -f "${dir}/yarn.lock" ]]; then
                echo "yarn"
            elif [[ -f "${dir}/package-lock.json" ]]; then
                echo "npm"
            else
                # Default: bun if available, otherwise npm
                if tool_available bun; then
                    echo "bun"
                elif tool_available pnpm; then
                    echo "pnpm"
                else
                    echo "npm"
                fi
            fi
            ;;
        python)
            # Check for lockfiles
            if [[ -f "${dir}/uv.lock" ]]; then
                echo "uv"
            elif [[ -f "${dir}/poetry.lock" ]]; then
                echo "poetry"
            elif [[ -f "${dir}/Pipfile.lock" ]]; then
                echo "pipenv"
            else
                # Default: uv if available
                if tool_available uv; then
                    echo "uv"
                else
                    echo "pip"
                fi
            fi
            ;;
        *)
            # Return empty for other languages (will use detected tool)
            echo ""
            ;;
    esac
}

# =============================================================================
# INSTALL COMMANDS
# =============================================================================

# Get install command for a tool
get_install_command() {
    local tool="$1"
    local dir="${2:-.}"

    case "$tool" in
        # JavaScript/TypeScript
        bun)        echo "bun install" ;;
        pnpm)       echo "pnpm install" ;;
        yarn)       echo "yarn install" ;;
        npm)        echo "npm install" ;;

        # Rust
        cargo)      echo "cargo build --release" ;;

        # Go
        go)         echo "go build ./..." ;;

        # Python
        uv)
            if [[ -f "${dir}/pyproject.toml" ]]; then
                echo "uv sync"
            else
                echo "uv pip install -r requirements.txt"
            fi
            ;;
        pip)
            if [[ -f "${dir}/pyproject.toml" ]]; then
                echo "pip install -e ."
            else
                echo "pip install -r requirements.txt"
            fi
            ;;
        poetry)     echo "poetry install" ;;
        pipenv)     echo "pipenv install" ;;

        # Ruby
        bundle)     echo "bundle install" ;;

        # Java
        mvn)        echo "mvn clean install -DskipTests" ;;
        gradle)     echo "gradle build -x test" ;;
        sbt)        echo "sbt compile" ;;

        # PHP
        composer)   echo "composer install" ;;

        # Elixir
        mix)        echo "mix deps.get && mix compile" ;;
        rebar3)     echo "rebar3 compile" ;;

        # .NET
        dotnet)     echo "dotnet restore && dotnet build" ;;

        # Zig
        zig)        echo "zig build" ;;

        # Swift
        swift)      echo "swift build" ;;

        # Haskell
        stack)      echo "stack build" ;;
        cabal)      echo "cabal update && cabal build" ;;

        # Lua
        luarocks)   echo "luarocks install --only-deps *.rockspec" ;;

        # Dart
        dart)       echo "dart pub get" ;;

        # Nim
        nimble)     echo "nimble install -y" ;;

        # OCaml
        dune)       echo "dune build" ;;
        opam)       echo "opam install . --deps-only" ;;

        # Clojure
        clojure)    echo "clojure -P" ;;
        lein)       echo "lein deps" ;;

        # C/C++
        cmake)      echo "cmake -B build && cmake --build build" ;;
        meson)      echo "meson setup build && meson compile -C build" ;;
        make)       echo "make" ;;
        autotools)  echo "./configure && make" ;;

        # V
        v)          echo "v build" ;;

        *)          echo "" ;;
    esac
}

# Get build command (if different from install)
get_build_command() {
    local tool="$1"

    case "$tool" in
        bun)        echo "bun run build" ;;
        pnpm)       echo "pnpm run build" ;;
        yarn)       echo "yarn build" ;;
        npm)        echo "npm run build" ;;
        cargo)      echo "cargo build --release" ;;
        go)         echo "go build" ;;
        mvn)        echo "mvn package" ;;
        gradle)     echo "gradle build" ;;
        dotnet)     echo "dotnet build --configuration Release" ;;
        *)          echo "" ;;
    esac
}

# =============================================================================
# TOOL INSTALLATION
# =============================================================================

# Get command to install a missing tool
get_tool_install_command() {
    local tool="$1"
    local os
    os=$(uname -s)

    case "$tool" in
        # JavaScript
        bun)
            echo "curl -fsSL https://bun.sh/install | bash"
            ;;
        pnpm)
            if tool_available npm; then
                echo "npm install -g pnpm"
            else
                echo "curl -fsSL https://get.pnpm.io/install.sh | sh -"
            fi
            ;;
        yarn)
            if tool_available npm; then
                echo "npm install -g yarn"
            else
                echo "corepack enable"
            fi
            ;;
        npm)
            case "$os" in
                Darwin) echo "brew install node" ;;
                Linux)  echo "curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs" ;;
            esac
            ;;

        # Python
        uv)
            echo "curl -LsSf https://astral.sh/uv/install.sh | sh"
            ;;
        poetry)
            echo "curl -sSL https://install.python-poetry.org | python3 -"
            ;;
        pipenv)
            echo "pip install pipenv"
            ;;

        # Rust
        cargo)
            echo "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
            ;;

        # Go
        go)
            case "$os" in
                Darwin) echo "brew install go" ;;
                Linux)  echo "sudo apt-get install golang" ;;
            esac
            ;;

        # Ruby
        bundle)
            echo "gem install bundler"
            ;;

        # Java
        mvn)
            case "$os" in
                Darwin) echo "brew install maven" ;;
                Linux)  echo "sudo apt-get install maven" ;;
            esac
            ;;
        gradle)
            case "$os" in
                Darwin) echo "brew install gradle" ;;
                Linux)  echo "sudo apt-get install gradle" ;;
            esac
            ;;

        # PHP
        composer)
            echo "curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer"
            ;;

        # Elixir
        mix)
            case "$os" in
                Darwin) echo "brew install elixir" ;;
                Linux)  echo "sudo apt-get install elixir" ;;
            esac
            ;;

        # .NET
        dotnet)
            case "$os" in
                Darwin) echo "brew install dotnet" ;;
                Linux)  echo "sudo apt-get install dotnet-sdk-8.0" ;;
            esac
            ;;

        # Zig
        zig)
            case "$os" in
                Darwin) echo "brew install zig" ;;
                Linux)  echo "snap install zig --classic" ;;
            esac
            ;;

        # Swift
        swift)
            case "$os" in
                Darwin) echo "xcode-select --install" ;;
                Linux)  echo "# Visit https://swift.org/download/" ;;
            esac
            ;;

        # Haskell
        stack)
            echo "curl -sSL https://get.haskellstack.org/ | sh"
            ;;
        cabal)
            echo "ghcup install cabal"
            ;;

        *)
            echo ""
            ;;
    esac
}

# =============================================================================
# LANGUAGE INFO
# =============================================================================

# Get human-readable language name
get_language_name() {
    local lang="$1"

    case "$lang" in
        javascript)     echo "JavaScript" ;;
        typescript)     echo "TypeScript" ;;
        rust)           echo "Rust" ;;
        go)             echo "Go" ;;
        python)         echo "Python" ;;
        ruby)           echo "Ruby" ;;
        java)           echo "Java" ;;
        scala)          echo "Scala" ;;
        php)            echo "PHP" ;;
        elixir)         echo "Elixir" ;;
        erlang)         echo "Erlang" ;;
        dotnet)         echo ".NET" ;;
        zig)            echo "Zig" ;;
        swift)          echo "Swift" ;;
        haskell)        echo "Haskell" ;;
        lua)            echo "Lua" ;;
        dart)           echo "Dart/Flutter" ;;
        nim)            echo "Nim" ;;
        ocaml)          echo "OCaml" ;;
        clojure)        echo "Clojure" ;;
        cpp)            echo "C/C++" ;;
        vlang)          echo "V" ;;
        unknown)        echo "Unknown" ;;
        *)              echo "$lang" ;;
    esac
}

# Get language icon/emoji
get_language_icon() {
    local lang="$1"

    case "$lang" in
        javascript|typescript)  echo "📦" ;;
        rust)                   echo "🦀" ;;
        go)                     echo "🐹" ;;
        python)                 echo "🐍" ;;
        ruby)                   echo "💎" ;;
        java|scala)             echo "☕" ;;
        php)                    echo "🐘" ;;
        elixir|erlang)          echo "💧" ;;
        dotnet)                 echo "🔷" ;;
        swift)                  echo "🐦" ;;
        haskell)                echo "λ" ;;
        cpp)                    echo "⚙️" ;;
        *)                      echo "📁" ;;
    esac
}
