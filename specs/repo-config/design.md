# Design: Per-Repository Configuration System

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        GITD Configuration Flow                       │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  CLI Flags   │───▶│ .gitdrc      │───▶│ User Config  │───▶│   Defaults   │
│  (Highest)   │    │ (Repo)       │    │ (~/.gitd/)   │    │  (Lowest)    │
└──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
       │                   │                   │                   │
       └───────────────────┴───────────────────┴───────────────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │   Merged Config      │
                         │   (Runtime)          │
                         └──────────────────────┘
```

## Component Diagram

```
src/lib/
├── config.sh              # Existing: Global config (~/.gitd/config.json)
├── config-repo.sh         # NEW: Repo config (.gitdrc) loader
├── config-merge.sh        # NEW: Configuration merger
├── config-validator.sh    # NEW: JSON Schema validator
├── hooks.sh               # NEW: Hook executor
├── security.sh            # NEW: Command security checker
├── env-vars.sh            # NEW: Environment variable handler
├── workflows.sh           # NEW: Workflow executor
└── utils.sh               # Existing: Shared utilities
```

## Data Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                          gitd -s <repo>                              │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 1. Parse CLI Arguments                                               │
│    - Extract: repo_url, branch, setup flag, dry-run                 │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 2. Clone Repository                                                  │
│    - git clone --depth 1 -b <branch> <url> <target>                 │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 3. Load .gitdrc (if exists)                                          │
│    - Search: .gitdrc, .gitdrc.json, .gitd.json                      │
│    - Validate against JSON Schema                                    │
│    - Display security analysis                                       │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 4. User Confirmation                                                 │
│    - Show hooks summary                                              │
│    - Display security warnings                                       │
│    - Prompt: "Execute repository configuration? [Y/n]"              │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 5. Merge Configurations                                              │
│    - CLI flags > .gitdrc > ~/.gitd/config.json > defaults           │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 6. Execute post-clone Hooks                                          │
│    - Validate each command (security check)                          │
│    - Execute with timeout                                            │
│    - Handle errors based on continueOnError                         │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 7. Prompt for Environment Variables                                  │
│    - Required variables (abort if not provided)                      │
│    - Optional variables with defaults                                │
│    - Secret input (hidden)                                           │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 8. Execute pre-setup Hooks                                           │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 9. Run Setup                                                         │
│    - If setup.commands: run custom commands                          │
│    - Else: auto-detect and run default setup                        │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 10. Execute post-setup Hooks                                         │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 11. Open Editor (if configured)                                      │
│     - Open workspace file or directory                              │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 12. Complete                                                         │
└─────────────────────────────────────────────────────────────────────┘
```

## API Contracts

### config-repo.sh

```bash
# Load and validate .gitdrc from repository
# Returns: path to config file or empty string
# Usage: config_path=$(load_repo_config "/path/to/repo")
load_repo_config() {
    local repo_dir="$1"
    # Search order: .gitdrc > .gitdrc.json > .gitd.json
}

# Check if repo has configuration
# Returns: 0 if exists, 1 if not
# Usage: if has_repo_config "/path/to/repo"; then ...
has_repo_config() {
    local repo_dir="$1"
}

# Get value from repo config
# Usage: value=$(repo_config_get "hooks.post-clone.commands" "[]")
repo_config_get() {
    local key="$1"
    local default="$2"
}

# Get array from repo config
# Usage: commands=($(repo_config_get_array "hooks.post-clone.commands"))
repo_config_get_array() {
    local key="$1"
}
```

### config-merge.sh

```bash
# Merge configurations with precedence
# Usage: merged_config=$(merge_configs "$cli_json" "$repo_config" "$user_config")
merge_configs() {
    local cli_overrides="$1"
    local repo_config="$2"
    local user_config="$3"
}

# Get effective value after merge
# Usage: value=$(get_effective_config "setup.skip" "false")
get_effective_config() {
    local key="$1"
    local default="$2"
}
```

### hooks.sh

```bash
# Execute lifecycle hooks
# Usage: execute_hooks "/path/to/.gitdrc" "post-clone" "/path/to/repo"
execute_hooks() {
    local config_path="$1"
    local hook_type="$2"  # post-clone, pre-setup, post-setup
    local working_dir="$3"
}

# Execute single command with safety checks
# Returns: 0 on success, 1 on failure, 2 on timeout
execute_hook_command() {
    local cmd="$1"
    local timeout="$2"
    local working_dir="$3"
}
```

### security.sh

```bash
# Check if command is safe to execute
# Returns: 0 if safe, 1 if dangerous
is_command_safe() {
    local cmd="$1"
    local config_path="$2"
}

# Analyze config for security risks
# Returns: risk level (0=none, 1+=warnings)
analyze_config_security() {
    local config_path="$1"
}

# Get user confirmation for command execution
# Returns: 0 if approved, 1 if denied
confirm_command_execution() {
    local cmd="$1"
    local context="$2"
}
```

### env-vars.sh

```bash
# Prompt for required environment variables
# Usage: prompt_env_vars "/path/to/.gitdrc"
prompt_env_vars() {
    local config_path="$1"
}

# Export environment variables from config
# Usage: export_env_defaults "/path/to/.gitdrc"
export_env_defaults() {
    local config_path="$1"
}
```

### workflows.sh

```bash
# List available workflows
# Usage: list_workflows "/path/to/.gitdrc"
list_workflows() {
    local config_path="$1"
}

# Execute a named workflow
# Usage: execute_workflow "/path/to/.gitdrc" "dev" "/path/to/repo"
execute_workflow() {
    local config_path="$1"
    local workflow_name="$2"
    local working_dir="$3"
}
```

## Database Schema (Config Structure)

### .gitdrc (Repository Config)

```json
{
  "$schema": "https://raw.githubusercontent.com/Obed0101/gitd/main/gitdrc.schema.json",
  "version": "1.0",

  "detection": {
    "language": "javascript",
    "tool": "pnpm",
    "skip": false
  },

  "hooks": {
    "post-clone": {
      "commands": ["cp .env.example .env"],
      "timeout": 30000,
      "continueOnError": true
    },
    "pre-setup": {
      "commands": ["echo 'Starting setup...'"],
      "timeout": 10000
    },
    "post-setup": {
      "commands": ["npm run build", "npm test"],
      "timeout": 300000,
      "continueOnError": false
    }
  },

  "setup": {
    "skip": false,
    "commands": ["pnpm install", "pnpm build"],
    "workdir": "."
  },

  "env": {
    "required": ["DATABASE_URL", "API_KEY"],
    "optional": ["DEBUG"],
    "defaults": {
      "NODE_ENV": "development",
      "PORT": "3000"
    },
    "prompts": {
      "DATABASE_URL": {
        "description": "PostgreSQL connection string",
        "default": "postgresql://localhost:5432/mydb"
      },
      "API_KEY": {
        "description": "API key for external service",
        "secret": true
      }
    }
  },

  "workflows": {
    "dev": {
      "description": "Start development server",
      "steps": ["pnpm dev"]
    },
    "test": {
      "description": "Run test suite",
      "steps": ["pnpm test"]
    },
    "build": {
      "description": "Production build",
      "steps": ["pnpm build"]
    }
  },

  "security": {
    "requireConfirmation": true,
    "allowSudo": false,
    "restrictedCommands": ["rm -rf /", "curl | sh"]
  },

  "editor": {
    "open": "code",
    "workspace": ".vscode/project.code-workspace"
  },

  "git": {
    "keepGitDir": false,
    "createBranch": "feature/initial-setup"
  }
}
```

### ~/.gitd/config.json (User Config)

Existing structure, extended with:

```json
{
  "version": "2.0.0",
  "repos": { ... },
  "packageManagers": { ... },
  "setup": {
    "autoInstallDeps": true,
    "autoDetectProject": true,
    "confirmBeforeInstall": true,
    "showProjectInfo": true,
    "trustRepoConfigs": false,      // NEW: Auto-trust .gitdrc files
    "defaultTimeout": 300000        // NEW: Default hook timeout
  },
  "security": {                      // NEW: Global security settings
    "allowSudo": false,
    "restrictedCommands": []
  }
}
```

## Security Model

```
┌─────────────────────────────────────────────────────────────────────┐
│                       Security Layers                                │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│ Layer 1: Command Blacklist                                           │
│ - Built-in dangerous patterns (rm -rf /, fork bombs, etc.)          │
│ - User-defined restricted commands                                   │
│ - Repo-defined restricted commands                                   │
└──────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────────┐
│ Layer 2: Sudo Protection                                             │
│ - Default: Block all sudo commands                                   │
│ - Can be enabled per-repo with allowSudo: true                      │
│ - Always shows warning when sudo is used                            │
└──────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────────┐
│ Layer 3: User Confirmation                                           │
│ - Default: Prompt before each hook command                          │
│ - Can be disabled with requireConfirmation: false                   │
│ - Always shows commands before execution                            │
└──────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────────┐
│ Layer 4: Timeout Protection                                          │
│ - Default: 300 seconds per command                                   │
│ - Prevents infinite loops and hangs                                  │
│ - Configurable per-hook                                              │
└──────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────────┐
│ Layer 5: Error Handling                                              │
│ - Default: Abort on command failure                                  │
│ - Can continue with continueOnError: true                           │
│ - Always reports errors clearly                                      │
└──────────────────────────────────────────────────────────────────────┘
```

## Dangerous Commands Blacklist

```bash
DANGEROUS_PATTERNS=(
    # Destructive file operations
    "rm -rf /"
    "rm -rf ~"
    "rm -rf /*"
    "> /dev/sd"

    # System manipulation
    "mkfs"
    "dd if=/dev/zero"
    "dd if=/dev/random"

    # Fork bombs
    ":(){ :|:& };:"
    "./$0|./$0&"

    # Remote code execution
    "curl.*|.*sh"
    "wget.*|.*sh"
    "curl.*|.*bash"
    "wget.*|.*bash"

    # Privilege escalation
    "chmod 777 /"
    "chmod -R 777"
    "chown -R.*/"

    # Network attacks
    "nc -l"
    "nmap"

    # Crypto miners
    "xmrig"
    "minerd"
)
```

## File Locations

| File | Purpose | Precedence |
|------|---------|------------|
| CLI flags | Runtime overrides | Highest |
| `.gitdrc` | Repository configuration | High |
| `.gitdrc.json` | Alternative repo config | High |
| `.gitd.json` | Alternative repo config | High |
| `~/.gitd/config.json` | User preferences | Medium |
| Built-in defaults | Fallback values | Lowest |

## Error Handling

| Error Type | Action | User Message |
|------------|--------|--------------|
| Invalid JSON | Fall back to auto-detect | "Invalid .gitdrc: falling back to auto-detection" |
| Missing required env | Abort setup | "Required environment variable not provided: X" |
| Blocked command | Skip command | "Blocked dangerous command: X" |
| Hook timeout | Kill process | "Hook timed out after X seconds" |
| Hook failure | Abort or continue | "Hook failed (exit code X)" |
| Unknown workflow | Show available | "Workflow 'X' not found. Available: dev, test, build" |

## Extension Points

1. **Custom Validators**: Add validation functions in `config-validator.sh`
2. **New Hook Types**: Extend `hooks.sh` with new lifecycle points
3. **Security Rules**: Add patterns to `DANGEROUS_PATTERNS` array
4. **Workflow Actions**: Implement new workflow step types
5. **Editor Support**: Add new editors in `editor.open` handler
