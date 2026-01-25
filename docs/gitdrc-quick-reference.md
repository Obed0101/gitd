# .gitdrc Quick Reference

## Minimal Configuration

```json
{
  "version": "1.0"
}
```

## Common Patterns

### Copy Environment File

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

### Run Database Migrations

```json
{
  "version": "1.0",
  "hooks": {
    "post-setup": {
      "commands": ["npm run db:migrate"],
      "timeout": 60000
    }
  }
}
```

### Force Package Manager

```json
{
  "version": "1.0",
  "detection": {
    "tool": "bun"
  }
}
```

### Skip Auto-Setup

```json
{
  "version": "1.0",
  "setup": {
    "skip": true
  }
}
```

### Custom Setup Commands

```json
{
  "version": "1.0",
  "setup": {
    "commands": ["make install", "make build"]
  }
}
```

### Define Workflows

```json
{
  "version": "1.0",
  "workflows": {
    "dev": {
      "description": "Start development server",
      "steps": ["npm run dev"]
    },
    "test": {
      "description": "Run tests",
      "steps": ["npm test"]
    }
  }
}
```

### Prompt for Environment Variables

```json
{
  "version": "1.0",
  "env": {
    "prompts": {
      "DATABASE_URL": {
        "description": "Database connection string",
        "default": "postgresql://localhost:5432/mydb"
      },
      "API_KEY": {
        "description": "API key",
        "secret": true
      }
    }
  }
}
```

### Set Default Environment Variables

```json
{
  "version": "1.0",
  "env": {
    "defaults": {
      "NODE_ENV": "development",
      "PORT": "3000"
    }
  }
}
```

### Configure Editor

```json
{
  "version": "1.0",
  "editor": {
    "open": "code"
  }
}
```

### Keep Git History

```json
{
  "version": "1.0",
  "git": {
    "keepGitDir": true,
    "createBranch": "dev"
  }
}
```

### Security Settings

```json
{
  "version": "1.0",
  "security": {
    "requireConfirmation": true,
    "allowSudo": false,
    "restrictedCommands": ["rm -rf /"]
  }
}
```

## Complete Example

```json
{
  "$schema": "https://raw.githubusercontent.com/Obed0101/gitd/main/gitdrc.schema.json",
  "version": "1.0",
  "detection": {
    "language": "javascript",
    "tool": "bun"
  },
  "hooks": {
    "post-clone": {
      "commands": ["cp .env.example .env"]
    },
    "post-setup": {
      "commands": ["bun run db:migrate"],
      "timeout": 60000
    }
  },
  "env": {
    "required": ["DATABASE_URL"],
    "defaults": {
      "NODE_ENV": "development",
      "PORT": "3000"
    },
    "prompts": {
      "DATABASE_URL": {
        "description": "PostgreSQL connection string",
        "default": "postgresql://localhost:5432/mydb"
      }
    }
  },
  "workflows": {
    "dev": {
      "description": "Start development server",
      "steps": ["bun run dev"]
    },
    "test": {
      "description": "Run tests",
      "steps": ["bun test"]
    }
  },
  "security": {
    "requireConfirmation": true,
    "allowSudo": false
  },
  "editor": {
    "open": "code"
  }
}
```

## Property Reference

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `version` | string | Yes | Schema version (`"1.0"`) |
| `detection` | object | No | Override auto-detection |
| `detection.language` | string | No | Force language detection |
| `detection.tool` | string | No | Force package manager |
| `detection.skip` | boolean | No | Skip detection entirely |
| `hooks` | object | No | Lifecycle hooks |
| `hooks.post-clone` | object | No | After clone commands |
| `hooks.pre-setup` | object | No | Before setup commands |
| `hooks.post-setup` | object | No | After setup commands |
| `setup` | object | No | Setup configuration |
| `setup.skip` | boolean | No | Skip setup |
| `setup.commands` | array | No | Custom setup commands |
| `setup.workdir` | string | No | Working directory |
| `env` | object | No | Environment variables |
| `env.required` | array | No | Required env vars |
| `env.optional` | array | No | Optional env vars |
| `env.defaults` | object | No | Default values |
| `env.prompts` | object | No | Interactive prompts |
| `workflows` | object | No | Command workflows |
| `security` | object | No | Security settings |
| `security.requireConfirmation` | boolean | No | Require confirmation (default: `true`) |
| `security.allowSudo` | boolean | No | Allow sudo (default: `false`) |
| `security.restrictedCommands` | array | No | Blocked commands |
| `editor` | object | No | Editor integration |
| `editor.open` | string | No | Editor command |
| `editor.workspace` | string | No | Workspace file path |
| `git` | object | No | Git configuration |
| `git.keepGitDir` | boolean | No | Keep .git directory |
| `git.createBranch` | string | No | Create new branch |

## Hook Configuration

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `commands` | array | Yes | - | Commands to execute |
| `timeout` | integer | No | `300000` | Max execution time (ms) |
| `continueOnError` | boolean | No | `false` | Continue on failure |
| `workdir` | string | No | - | Working directory |

## Workflow Configuration

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `description` | string | No | Human-readable description |
| `steps` | array | Yes | Commands to execute |
| `workdir` | string | No | Working directory |

## Prompt Configuration

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `description` | string | Yes | Prompt message |
| `default` | string | No | Default value |
| `secret` | boolean | No | Hide input (default: `false`) |
| `validate` | string | No | Regex validation pattern |

## Supported Languages

`javascript`, `typescript`, `rust`, `go`, `python`, `ruby`, `java`, `scala`, `php`, `elixir`, `erlang`, `dotnet`, `zig`, `swift`, `haskell`, `lua`, `dart`, `nim`, `ocaml`, `clojure`, `cpp`, `vlang`

## Supported Tools

**JavaScript/TypeScript:** `bun`, `pnpm`, `yarn`, `npm`
**Python:** `uv`, `pip`, `poetry`, `pipenv`
**Rust:** `cargo`
**Go:** `go`
**Ruby:** `bundle`
**Java:** `mvn`, `gradle`, `sbt`
**PHP:** `composer`
**Elixir:** `mix`
**.NET:** `dotnet`
**Others:** `zig`, `swift`, `stack`, `cabal`, and more

## Validation

```bash
# Validate .gitdrc file
./scripts/validate-gitdrc.sh .gitdrc

# Verbose output
./scripts/validate-gitdrc.sh -v .gitdrc

# Validate all examples
./scripts/validate-gitdrc.sh --examples
```

## Usage

```bash
# Clone with setup
gitd https://github.com/user/repo -s

# Run workflow
gitd run dev

# Open in editor
gitd open
```

## Resources

- **Full Docs:** [gitdrc-configuration.md](./gitdrc-configuration.md)
- **Schema:** [gitdrc.schema.json](../gitdrc.schema.json)
- **Examples:** [examples/gitdrc/](../examples/gitdrc/)
