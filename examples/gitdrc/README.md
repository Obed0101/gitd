# .gitdrc Configuration Examples

This directory contains example `.gitdrc` configurations for various project types and use cases.

## Quick Start

Copy an example to your repository root as `.gitdrc`:

```bash
cp examples/gitdrc/rust-project.gitdrc /path/to/your/repo/.gitdrc
```

Edit to match your project's needs.

## Available Examples

### 1. **minimal.gitdrc** - Minimal Configuration
Bare minimum configuration that skips setup.

**Use case:** Projects with no dependencies or custom setup scripts.

```json
{
  "version": "1.0",
  "setup": {
    "skip": true
  }
}
```

---

### 2. **rust-project.gitdrc** - Rust Project
Complete Rust project setup with cargo, clippy, and rustfmt.

**Features:**
- Updates Rust toolchain before setup
- Installs clippy and rustfmt
- Builds release binary after setup
- Includes dev, test, build, and bench workflows

**Use case:** Rust applications and libraries.

---

### 3. **python-ml.gitdrc** - Python ML/Data Science
Python machine learning project with uv package manager.

**Features:**
- Creates data and models directories
- Sets up pre-commit hooks
- Configures Jupyter notebook extensions
- Environment variable prompts for dataset paths
- Workflows for training, notebooks, and testing

**Use case:** Machine learning, data science projects.

---

### 4. **monorepo.gitdrc** - Monorepo (pnpm)
Multi-package JavaScript/TypeScript monorepo configuration.

**Features:**
- Copies `.env` files for each package
- Builds shared packages first
- Runs database migrations
- Separate workflows for each service
- Workspace file integration

**Use case:** Monorepos with pnpm workspaces.

---

### 5. **custom-setup.gitdrc** - Custom Setup Script
Project with custom bootstrap and setup scripts.

**Features:**
- Skips auto-detection
- Runs custom bootstrap script
- Uses Makefile commands
- Allows sudo for system-level setup

**Use case:** Projects with existing setup infrastructure.

---

## Example Structure

All examples follow this pattern:

```json
{
  "$schema": "../../gitdrc.schema.json",  // Schema reference
  "version": "1.0",                        // Required version
  "detection": { },                        // Language/tool detection
  "hooks": { },                            // Lifecycle hooks
  "setup": { },                            // Setup configuration
  "env": { },                              // Environment variables
  "workflows": { },                        // Command workflows
  "security": { },                         // Security settings
  "editor": { },                           // Editor integration
  "git": { }                               // Git settings
}
```

## Usage

### 1. Clone with automatic setup

```bash
gitd https://github.com/user/repo -s
```

### 2. Run workflows

```bash
cd repo
gitd run dev      # Start development
gitd run test     # Run tests
gitd run build    # Build project
```

### 3. Open in editor

```bash
gitd open
```

## Customization Tips

### Override Language Detection

Force a specific language and tool:

```json
{
  "detection": {
    "language": "javascript",
    "tool": "bun"
  }
}
```

### Add Post-Clone Hooks

Run commands after cloning:

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

### Configure Environment Variables

Prompt users for required configuration:

```json
{
  "env": {
    "required": ["DATABASE_URL"],
    "prompts": {
      "DATABASE_URL": {
        "description": "Database connection string",
        "default": "postgresql://localhost/mydb"
      }
    }
  }
}
```

### Create Workflows

Define common development tasks:

```json
{
  "workflows": {
    "dev": {
      "description": "Start development server",
      "steps": ["npm run dev"]
    }
  }
}
```

## Language-Specific Examples

### JavaScript/TypeScript

- **Tool options:** `bun`, `pnpm`, `yarn`, `npm`
- **Common workflows:** `dev`, `test`, `build`, `lint`
- **Typical hooks:** Copy `.env`, run migrations

### Rust

- **Tool:** `cargo`
- **Common workflows:** `build`, `test`, `bench`, `clippy`
- **Typical hooks:** Update toolchain, install components

### Python

- **Tool options:** `uv`, `pip`, `poetry`, `pipenv`
- **Common workflows:** `train`, `notebook`, `test`
- **Typical hooks:** Create data directories, install pre-commit

### Go

- **Tool:** `go`
- **Common workflows:** `build`, `test`, `run`
- **Typical hooks:** Download dependencies

## Best Practices

1. **Always validate against schema**
   - Add `$schema` property for editor support

2. **Set appropriate timeouts**
   - Default: 300000ms (5 minutes)
   - Long builds: Increase timeout

3. **Use security settings**
   - Enable `requireConfirmation` for safety
   - Restrict dangerous commands

4. **Provide helpful prompts**
   - Clear descriptions
   - Sensible defaults
   - Mark secrets as `secret: true`

5. **Document workflows**
   - Add `description` to each workflow
   - Use clear, actionable names

## Testing Your Configuration

1. **Validate JSON syntax:**
   ```bash
   cat .gitdrc | jq .
   ```

2. **Validate against schema:**
   ```bash
   ajv validate -s gitdrc.schema.json -d .gitdrc
   ```

3. **Test with gitd:**
   ```bash
   gitd https://github.com/user/repo -s
   ```

## See Also

- [Full Documentation](../../docs/gitdrc-configuration.md)
- [JSON Schema](../../gitdrc.schema.json)
- [Main README](../../README.md)
