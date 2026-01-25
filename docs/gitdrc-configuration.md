# .gitdrc Configuration Guide

## Overview

The `.gitdrc` file allows per-repository configuration of GITD behavior. Place this file in the root of your repository to customize how GITD handles cloning, setup, and environment configuration.

## Schema Validation

The configuration follows the JSON Schema defined in `gitdrc.schema.json`. Most editors with JSON Schema support will provide autocomplete and validation.

Add this to the top of your `.gitdrc` file for editor support:

```json
{
  "$schema": "https://raw.githubusercontent.com/Obed0101/gitd/main/gitdrc.schema.json",
  "version": "1.0"
}
```

## Configuration Reference

### version (required)

**Type:** `string`
**Allowed values:** `"1.0"`

Configuration file format version.

```json
{
  "version": "1.0"
}
```

---

### detection

**Type:** `object`

Override automatic project detection.

#### Properties:

- **language** (`string`): Force specific language detection
  - Values: `javascript`, `typescript`, `rust`, `go`, `python`, `ruby`, `java`, etc.

- **tool** (`string`): Force specific package manager/build tool
  - Values: `bun`, `pnpm`, `yarn`, `npm`, `cargo`, `uv`, `pip`, etc.

- **skip** (`boolean`): Skip detection entirely

**Example:**

```json
{
  "detection": {
    "language": "javascript",
    "tool": "bun"
  }
}
```

---

### hooks

**Type:** `object`

Lifecycle hooks for repository operations.

#### Available hooks:

- **post-clone**: Run immediately after cloning
- **pre-setup**: Run before dependency installation
- **post-setup**: Run after dependency installation

#### Hook configuration:

Each hook is an object with:

- **commands** (`array` of `string`, required): Commands to execute
- **timeout** (`integer`, default: `300000`): Max execution time in milliseconds
- **continueOnError** (`boolean`, default: `false`): Continue if command fails
- **workdir** (`string`): Working directory for commands

**Example:**

```json
{
  "hooks": {
    "post-clone": {
      "commands": [
        "cp .env.example .env",
        "chmod +x scripts/*.sh"
      ],
      "timeout": 10000,
      "continueOnError": false
    },
    "pre-setup": {
      "commands": ["echo 'Preparing environment...'"],
      "continueOnError": true
    },
    "post-setup": {
      "commands": [
        "npm run db:migrate",
        "npm run seed"
      ],
      "timeout": 60000
    }
  }
}
```

---

### setup

**Type:** `object`

Configure the dependency installation process.

#### Properties:

- **skip** (`boolean`): Skip setup entirely
- **commands** (`array` of `string`): Custom setup commands (overrides auto-detection)
- **workdir** (`string`): Working directory for setup commands

**Examples:**

Skip setup:
```json
{
  "setup": {
    "skip": true
  }
}
```

Custom setup:
```json
{
  "setup": {
    "commands": ["make install", "make build"],
    "workdir": "backend"
  }
}
```

---

### env

**Type:** `object`

Environment variable configuration.

#### Properties:

- **required** (`array` of `string`): Variables that must be set (setup fails if missing)
- **optional** (`array` of `string`): Variables that are optional (warning if missing)
- **defaults** (`object`): Default values for environment variables
- **prompts** (`object`): Variables that require user input

#### Prompt configuration:

Each prompt is an object with:

- **description** (`string`, required): Prompt message
- **default** (`string`): Default value
- **secret** (`boolean`, default: `false`): Hide input
- **validate** (`string`): Regex pattern for validation

**Example:**

```json
{
  "env": {
    "required": ["DATABASE_URL", "API_KEY"],
    "optional": ["REDIS_URL", "SENTRY_DSN"],
    "defaults": {
      "NODE_ENV": "development",
      "PORT": "3000",
      "LOG_LEVEL": "info"
    },
    "prompts": {
      "DATABASE_URL": {
        "description": "Enter PostgreSQL connection string",
        "default": "postgresql://localhost:5432/mydb"
      },
      "API_KEY": {
        "description": "Enter your API key",
        "secret": true,
        "validate": "^[a-zA-Z0-9]{32}$"
      }
    }
  }
}
```

---

### workflows

**Type:** `object`

Predefined command workflows for common tasks.

Each workflow has:

- **description** (`string`): Human-readable description
- **steps** (`array` of `string`, required): Commands to execute
- **workdir** (`string`): Working directory for workflow

Workflow names must match pattern: `^[a-z][a-z0-9-]*$`

**Example:**

```json
{
  "workflows": {
    "dev": {
      "description": "Start development server",
      "steps": ["npm run dev"]
    },
    "test": {
      "description": "Run test suite",
      "steps": [
        "npm run lint",
        "npm test",
        "npm run test:e2e"
      ]
    },
    "deploy": {
      "description": "Deploy to production",
      "steps": [
        "npm run build",
        "npm run db:migrate",
        "pm2 restart app"
      ],
      "workdir": "backend"
    }
  }
}
```

**Usage:**

```bash
gitd run dev    # Run the 'dev' workflow
gitd run test   # Run the 'test' workflow
```

---

### security

**Type:** `object`

Security and safety settings.

#### Properties:

- **requireConfirmation** (`boolean`, default: `true`): Require confirmation before running setup
- **allowSudo** (`boolean`, default: `false`): Allow commands requiring sudo
- **restrictedCommands** (`array` of `string`): Blocked commands

**Example:**

```json
{
  "security": {
    "requireConfirmation": true,
    "allowSudo": false,
    "restrictedCommands": [
      "rm -rf /",
      "sudo rm",
      "dd if=",
      "mkfs",
      "format"
    ]
  }
}
```

---

### editor

**Type:** `object`

Editor integration settings.

#### Properties:

- **open** (`string`): Editor command to open the project
  - Values: `code`, `vim`, `nvim`, `emacs`, `idea`, `webstorm`, etc.

- **workspace** (`string`): Path to workspace file (relative to repository root)

**Example:**

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

### git

**Type:** `object`

Git-specific configuration.

#### Properties:

- **keepGitDir** (`boolean`, default: `false`): Preserve `.git` directory after cloning
- **createBranch** (`string`): Create and switch to new branch after cloning

**Example:**

```json
{
  "git": {
    "keepGitDir": true,
    "createBranch": "dev"
  }
}
```

---

## Complete Examples

### JavaScript Project (Bun)

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
    }
  },
  "workflows": {
    "dev": {
      "description": "Start dev server",
      "steps": ["bun run dev"]
    }
  },
  "editor": {
    "open": "code"
  }
}
```

### Rust Project

```json
{
  "$schema": "https://raw.githubusercontent.com/Obed0101/gitd/main/gitdrc.schema.json",
  "version": "1.0",
  "detection": {
    "language": "rust",
    "tool": "cargo"
  },
  "hooks": {
    "pre-setup": {
      "commands": ["rustup update stable"],
      "timeout": 120000
    }
  },
  "workflows": {
    "build": {
      "description": "Build release binary",
      "steps": ["cargo build --release"]
    },
    "test": {
      "description": "Run tests and linting",
      "steps": [
        "cargo test",
        "cargo clippy -- -D warnings"
      ]
    }
  }
}
```

### Python ML Project (uv)

```json
{
  "$schema": "https://raw.githubusercontent.com/Obed0101/gitd/main/gitdrc.schema.json",
  "version": "1.0",
  "detection": {
    "language": "python",
    "tool": "uv"
  },
  "hooks": {
    "post-clone": {
      "commands": [
        "mkdir -p data/raw data/processed models"
      ]
    }
  },
  "env": {
    "required": ["DATASET_PATH"],
    "defaults": {
      "PYTHONPATH": "src"
    },
    "prompts": {
      "DATASET_PATH": {
        "description": "Path to training dataset",
        "default": "./data/raw"
      }
    }
  },
  "workflows": {
    "train": {
      "description": "Train model",
      "steps": ["uv run python src/train.py"]
    },
    "notebook": {
      "description": "Launch Jupyter",
      "steps": ["uv run jupyter notebook"]
    }
  }
}
```

### Minimal Configuration

```json
{
  "$schema": "https://raw.githubusercontent.com/Obed0101/gitd/main/gitdrc.schema.json",
  "version": "1.0",
  "setup": {
    "skip": true
  }
}
```

### Custom Setup Script

```json
{
  "$schema": "https://raw.githubusercontent.com/Obed0101/gitd/main/gitdrc.schema.json",
  "version": "1.0",
  "detection": {
    "skip": true
  },
  "setup": {
    "commands": [
      "make setup",
      "./scripts/bootstrap.sh"
    ]
  },
  "security": {
    "allowSudo": true
  }
}
```

---

## Best Practices

### 1. Always specify version

```json
{
  "version": "1.0"
}
```

### 2. Use hooks for environment preparation

```json
{
  "hooks": {
    "post-clone": {
      "commands": [
        "cp .env.example .env",
        "mkdir -p tmp logs"
      ]
    }
  }
}
```

### 3. Set reasonable timeouts

```json
{
  "hooks": {
    "post-setup": {
      "commands": ["npm run db:migrate"],
      "timeout": 60000  // 1 minute
    }
  }
}
```

### 4. Prompt for sensitive data

```json
{
  "env": {
    "prompts": {
      "API_KEY": {
        "description": "Enter your API key",
        "secret": true
      }
    }
  }
}
```

### 5. Use security restrictions

```json
{
  "security": {
    "requireConfirmation": true,
    "allowSudo": false,
    "restrictedCommands": ["rm -rf /"]
  }
}
```

### 6. Define common workflows

```json
{
  "workflows": {
    "dev": {
      "description": "Start development",
      "steps": ["npm run dev"]
    },
    "test": {
      "description": "Run tests",
      "steps": ["npm test"]
    }
  }
}
```

---

## Validation

Validate your `.gitdrc` file against the schema:

```bash
# Using ajv-cli
npm install -g ajv-cli
ajv validate -s gitdrc.schema.json -d .gitdrc

# Using VS Code
# Install "JSON Schema Validator" extension
# Add $schema property to your .gitdrc file
```

---

## Migration Guide

### From manual setup to .gitdrc

**Before (manual):**
```bash
git clone https://github.com/user/repo
cd repo
cp .env.example .env
npm install
npm run db:migrate
npm run dev
```

**After (with .gitdrc):**
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
      "description": "Start dev server",
      "steps": ["npm run dev"]
    }
  }
}
```

---

## Troubleshooting

### Schema validation fails

**Problem:** Editor shows validation errors

**Solution:** Ensure `$schema` property points to correct schema URL:
```json
{
  "$schema": "./gitdrc.schema.json"
}
```

### Hook timeout

**Problem:** Hook commands timeout

**Solution:** Increase timeout value:
```json
{
  "hooks": {
    "post-setup": {
      "commands": ["long-running-command"],
      "timeout": 600000  // 10 minutes
    }
  }
}
```

### Environment variable not set

**Problem:** Required env var missing

**Solution:** Add to prompts or provide default:
```json
{
  "env": {
    "prompts": {
      "DATABASE_URL": {
        "description": "Database connection string",
        "default": "postgresql://localhost/db"
      }
    }
  }
}
```

---

## See Also

- [GITD Installation Guide](../README.md)
- [Package Detection Reference](../src/lib/package-detect.sh)
- [Examples](../examples/gitdrc/)
