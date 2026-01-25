# GITD Configuration Schema Overview

## Introduction

The `.gitdrc` configuration system allows repository maintainers to define setup procedures, environment requirements, and development workflows that GITD executes automatically.

## File Location

Place `.gitdrc` in the **root directory** of your repository:

```
my-repo/
├── .gitdrc              ← Configuration file
├── .env.example
├── package.json
└── src/
```

## Schema Version

Current version: **1.0**

- **Schema file:** `gitdrc.schema.json`
- **Location:** https://github.com/Obed0101/gitd/blob/main/gitdrc.schema.json
- **Draft:** JSON Schema Draft 07

## Structure Overview

```json
{
  "version": "1.0",           // Required: Schema version
  "detection": { },           // Optional: Override auto-detection
  "hooks": { },               // Optional: Lifecycle hooks
  "setup": { },               // Optional: Setup configuration
  "env": { },                 // Optional: Environment variables
  "workflows": { },           // Optional: Command shortcuts
  "security": { },            // Optional: Security settings
  "editor": { },              // Optional: Editor integration
  "git": { }                  // Optional: Git configuration
}
```

## Property Reference

### version (required)

**Type:** String
**Value:** `"1.0"`
**Purpose:** Identifies the configuration file format version

```json
{
  "version": "1.0"
}
```

---

### detection (optional)

**Type:** Object
**Purpose:** Override automatic project detection

**Properties:**
- `language`: Force language detection (e.g., `"javascript"`, `"rust"`, `"python"`)
- `tool`: Force package manager/build tool (e.g., `"bun"`, `"cargo"`, `"uv"`)
- `skip`: Skip auto-detection entirely

**When to use:**
- Multi-language repositories
- Custom build systems
- Override default tool selection

```json
{
  "detection": {
    "language": "javascript",
    "tool": "bun"
  }
}
```

---

### hooks (optional)

**Type:** Object
**Purpose:** Execute commands at specific lifecycle stages

**Available hooks:**
1. `post-clone`: After repository is cloned
2. `pre-setup`: Before dependency installation
3. `post-setup`: After dependency installation

**Hook configuration:**
- `commands`: Array of shell commands
- `timeout`: Max execution time (ms)
- `continueOnError`: Don't fail if command errors
- `workdir`: Working directory (relative to repo root)

**Common use cases:**
- Copy environment templates
- Create directories
- Run database migrations
- Install system dependencies

```json
{
  "hooks": {
    "post-clone": {
      "commands": ["cp .env.example .env"],
      "timeout": 10000
    },
    "post-setup": {
      "commands": ["npm run db:migrate"],
      "timeout": 60000
    }
  }
}
```

---

### setup (optional)

**Type:** Object
**Purpose:** Configure dependency installation process

**Properties:**
- `skip`: Skip setup entirely (no dependency installation)
- `commands`: Custom setup commands (replaces auto-detected commands)
- `workdir`: Working directory for setup

**When to use:**
- Skip setup for documentation-only repos
- Custom build systems (Makefile, custom scripts)
- Monorepo with specific setup order

```json
{
  "setup": {
    "commands": ["make install", "make build"],
    "workdir": "backend"
  }
}
```

---

### env (optional)

**Type:** Object
**Purpose:** Define environment variable requirements

**Properties:**
- `required`: Must be set (setup fails if missing)
- `optional`: Should be set (warning if missing)
- `defaults`: Default values
- `prompts`: Interactive user input

**Prompt configuration:**
- `description`: User-facing prompt text
- `default`: Pre-filled value
- `secret`: Hide input (for passwords/tokens)
- `validate`: Regex pattern for validation

**Use cases:**
- Database connection strings
- API keys and secrets
- Feature flags
- Service URLs

```json
{
  "env": {
    "required": ["DATABASE_URL"],
    "optional": ["REDIS_URL"],
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
        "description": "API key",
        "secret": true,
        "validate": "^[a-zA-Z0-9]{32}$"
      }
    }
  }
}
```

---

### workflows (optional)

**Type:** Object
**Purpose:** Define reusable command sequences

**Workflow properties:**
- `description`: Human-readable explanation
- `steps`: Array of commands to execute
- `workdir`: Working directory

**Naming rules:**
- Must match pattern: `^[a-z][a-z0-9-]*$`
- Use lowercase letters, numbers, and hyphens
- Start with a letter
- No colons, underscores, or spaces

**Common workflows:**
- `dev`: Start development server
- `test`: Run test suite
- `build`: Build for production
- `lint`: Run linters
- `deploy`: Deploy to production

```json
{
  "workflows": {
    "dev": {
      "description": "Start development server",
      "steps": ["npm run dev"]
    },
    "test": {
      "description": "Run tests and linting",
      "steps": [
        "npm run lint",
        "npm test"
      ]
    }
  }
}
```

**Usage:**
```bash
gitd run dev     # Execute 'dev' workflow
gitd run test    # Execute 'test' workflow
```

---

### security (optional)

**Type:** Object
**Purpose:** Configure safety and security settings

**Properties:**
- `requireConfirmation`: Prompt before running commands (default: `true`)
- `allowSudo`: Allow commands requiring root (default: `false`)
- `restrictedCommands`: Blocked command patterns

**Recommended settings:**
- Always enable `requireConfirmation` for public repos
- Only enable `allowSudo` if absolutely necessary
- Block dangerous commands (`rm -rf /`, `dd`, `format`)

```json
{
  "security": {
    "requireConfirmation": true,
    "allowSudo": false,
    "restrictedCommands": [
      "rm -rf /",
      "dd if=",
      "mkfs"
    ]
  }
}
```

---

### editor (optional)

**Type:** Object
**Purpose:** Configure editor/IDE integration

**Properties:**
- `open`: Editor command (`code`, `vim`, `idea`, etc.)
- `workspace`: Path to workspace file

**Supported editors:**
- VS Code: `code`, `code-insiders`
- Vim/Neovim: `vim`, `nvim`
- JetBrains IDEs: `idea`, `webstorm`, `pycharm`, `rubymine`, etc.
- Others: `emacs`, `sublime`, `atom`, `zed`

```json
{
  "editor": {
    "open": "code",
    "workspace": "monorepo.code-workspace"
  }
}
```

**Usage:**
```bash
gitd open    # Opens project in configured editor
```

---

### git (optional)

**Type:** Object
**Purpose:** Git-specific configuration

**Properties:**
- `keepGitDir`: Don't remove `.git` directory (default: `false`)
- `createBranch`: Create and checkout new branch after cloning

**Use cases:**
- Keep git history for contribution
- Automatically start on development branch
- Fork and start feature branch

```json
{
  "git": {
    "keepGitDir": true,
    "createBranch": "dev"
  }
}
```

---

## Language Support

### Supported Languages

| Language | Detection Files | Tools |
|----------|----------------|-------|
| JavaScript | `package.json`, `*.lock` | `bun`, `pnpm`, `yarn`, `npm` |
| TypeScript | `tsconfig.json`, `package.json` | `bun`, `pnpm`, `yarn`, `npm` |
| Rust | `Cargo.toml`, `Cargo.lock` | `cargo` |
| Go | `go.mod`, `go.sum` | `go` |
| Python | `pyproject.toml`, `requirements.txt` | `uv`, `pip`, `poetry`, `pipenv` |
| Ruby | `Gemfile`, `Gemfile.lock` | `bundle` |
| Java | `pom.xml`, `build.gradle` | `mvn`, `gradle` |
| PHP | `composer.json`, `composer.lock` | `composer` |
| Elixir | `mix.exs`, `mix.lock` | `mix` |
| .NET | `*.sln`, `*.csproj` | `dotnet` |
| Zig | `build.zig` | `zig` |
| Swift | `Package.swift` | `swift` |
| Haskell | `stack.yaml`, `*.cabal` | `stack`, `cabal` |

### Full Language List

`javascript`, `typescript`, `rust`, `go`, `python`, `ruby`, `java`, `scala`, `php`, `elixir`, `erlang`, `dotnet`, `zig`, `swift`, `haskell`, `lua`, `dart`, `nim`, `ocaml`, `clojure`, `cpp`, `vlang`

---

## Validation

### Manual Validation

```bash
# Install validation script
curl -o validate-gitdrc.sh https://raw.githubusercontent.com/Obed0101/gitd/main/scripts/validate-gitdrc.sh
chmod +x validate-gitdrc.sh

# Validate your .gitdrc file
./validate-gitdrc.sh .gitdrc

# Verbose output
./validate-gitdrc.sh -v .gitdrc

# Validate all examples
./validate-gitdrc.sh --examples
```

### Editor Validation

Add `$schema` property for automatic validation in VS Code, WebStorm, etc:

```json
{
  "$schema": "https://raw.githubusercontent.com/Obed0101/gitd/main/gitdrc.schema.json",
  "version": "1.0"
}
```

---

## Examples

See the [examples directory](../examples/gitdrc/) for complete configurations:

- **minimal.gitdrc** - Bare minimum configuration
- **rust-project.gitdrc** - Rust project with cargo
- **python-ml.gitdrc** - Python ML project with uv
- **monorepo.gitdrc** - JavaScript monorepo with pnpm
- **custom-setup.gitdrc** - Custom setup scripts

---

## Best Practices

### 1. Start Minimal

Begin with only what you need:

```json
{
  "version": "1.0",
  "hooks": {
    "post-clone": {
      "commands": ["cp .env.example .env"]
    }
  }
}
```

### 2. Use Descriptive Workflow Names

```json
{
  "workflows": {
    "dev": { "description": "Start development server" },
    "test-unit": { "description": "Run unit tests only" },
    "test-integration": { "description": "Run integration tests" }
  }
}
```

### 3. Set Appropriate Timeouts

```json
{
  "hooks": {
    "post-setup": {
      "commands": ["npm run build"],
      "timeout": 300000  // 5 minutes for large builds
    }
  }
}
```

### 4. Validate Before Committing

```bash
./scripts/validate-gitdrc.sh .gitdrc
```

### 5. Document Complex Workflows

Add clear descriptions:

```json
{
  "workflows": {
    "deploy-staging": {
      "description": "Deploy to staging environment (requires AWS credentials)",
      "steps": ["npm run build", "npm run deploy:staging"]
    }
  }
}
```

### 6. Use Security Settings

Always enable security features for public repos:

```json
{
  "security": {
    "requireConfirmation": true,
    "allowSudo": false,
    "restrictedCommands": ["rm -rf /"]
  }
}
```

---

## Migration Guide

### From Manual Setup

**Before:**
```bash
git clone https://github.com/user/repo
cd repo
cp .env.example .env
npm install
npm run db:migrate
npm run dev
```

**After:**
```bash
gitd https://github.com/user/repo -s
cd repo
gitd run dev
```

**Configuration:**
```json
{
  "version": "1.0",
  "hooks": {
    "post-clone": {
      "commands": ["cp .env.example .env"]
    },
    "post-setup": {
      "commands": ["npm run db:migrate"]
    }
  },
  "workflows": {
    "dev": {
      "description": "Start development server",
      "steps": ["npm run dev"]
    }
  }
}
```

---

## Troubleshooting

### Common Issues

1. **Invalid JSON syntax**
   - Use a JSON validator or editor with syntax highlighting
   - Check for missing commas, quotes, brackets

2. **Unknown property warnings**
   - Verify property names against schema
   - Check for typos

3. **Workflow validation errors**
   - Ensure workflow names match `^[a-z][a-z0-9-]*$`
   - Use hyphens instead of colons or underscores

4. **Hook timeouts**
   - Increase `timeout` value for long-running commands
   - Split into multiple hooks if needed

---

## Resources

- **Full Documentation:** [gitdrc-configuration.md](./gitdrc-configuration.md)
- **JSON Schema:** [gitdrc.schema.json](../gitdrc.schema.json)
- **Examples:** [examples/gitdrc/](../examples/gitdrc/)
- **Validator Script:** [scripts/validate-gitdrc.sh](../scripts/validate-gitdrc.sh)

---

## Contributing

Found an issue or have a suggestion? Please open an issue on GitHub:
https://github.com/Obed0101/gitd/issues
