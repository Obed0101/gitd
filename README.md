<p align="center">
  <a href="https://github.com/Obed0101/gitd">
    <img src="https://i.imgur.com/NxZCmoU.png" alt="GITD Logo" width="200">
  </a>

  <h1 align="center">GITD - Git Download Tool</h1>

  <p align="center">
    Clone, configure, and set up repositories in seconds with intelligent project detection.
    <br/>
    <br/>
    <a href="#-quick-start">Quick Start</a>
    ·
    <a href="#-features">Features</a>
    ·
    <a href="#-configuration">Configuration</a>
    ·
    <a href="https://github.com/Obed0101/gitd/issues">Report Bug</a>
  </p>
</p>

<div align="center">

![Version](https://img.shields.io/badge/version-2.0.0-blue)
![Shell](https://img.shields.io/badge/shell-bash%20%7C%20zsh-green)
![License](https://img.shields.io/github/license/Obed0101/gitd)
![Stars](https://img.shields.io/github/stars/Obed0101/gitd?style=social)

</div>

---

## What is GITD?

GITD is a CLI tool that streamlines the process of cloning and setting up Git repositories. Instead of manually running `git clone`, installing dependencies, and configuring your environment, GITD does it all in one command.

```bash
# Traditional workflow
git clone https://github.com/user/project.git
cd project
npm install  # or yarn, pnpm, cargo, pip...
cp .env.example .env
# ... more setup steps

# With GITD
gitd -s https://github.com/user/project
# Done! Dependencies installed, environment configured.
```

---

## Quick Start

### Installation

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Obed0101/gitd/main/install.sh)"
```

The installer will:
- Detect your shell (Bash/Zsh)
- Configure your preferred package managers
- Set up the base directory for cloned repos

### Basic Usage

```bash
# Clone a repository
gitd https://github.com/user/repo

# Clone and auto-setup (install dependencies)
gitd -s https://github.com/user/repo

# Clone a specific branch
gitd -b develop https://github.com/user/repo

# Clone, setup, and specify branch
gitd -s -b main https://github.com/user/repo
```

---

## Features

### Intelligent Project Detection

GITD automatically detects your project type and uses the appropriate package manager:

| Language | Detected Files | Package Managers |
|----------|---------------|------------------|
| JavaScript/TypeScript | `package.json`, lockfiles | bun, pnpm, yarn, npm |
| Rust | `Cargo.toml` | cargo |
| Go | `go.mod` | go |
| Python | `pyproject.toml`, `requirements.txt` | uv, poetry, pipenv, pip |
| Ruby | `Gemfile` | bundler |
| Java | `pom.xml`, `build.gradle` | maven, gradle |
| PHP | `composer.json` | composer |
| Elixir | `mix.exs` | mix |
| .NET | `*.csproj`, `*.fsproj` | dotnet |
| Zig | `build.zig` | zig |
| Swift | `Package.swift` | swift |
| Haskell | `stack.yaml`, `*.cabal` | stack, cabal |
| C/C++ | `CMakeLists.txt`, `Makefile` | cmake, make |

### Smart Lockfile Priority

GITD respects your lockfiles to ensure reproducible builds:

```
bun.lockb       → Uses Bun
pnpm-lock.yaml  → Uses pnpm
yarn.lock       → Uses Yarn
package-lock.json → Uses npm
```

### Interactive Setup

- Confirmation prompts before operations
- Repository size display before cloning
- Colored output for better readability
- Loading spinners for long operations

### Automatic Tool Installation

If a required tool isn't installed, GITD offers to install it:

```
⚠ Bun is not installed. Install it? [Y/n]
```

---

## Configuration

### Global Configuration (`~/.gitd/config.json`)

GITD stores user preferences in `~/.gitd/config.json`:

```json
{
  "version": "2.0.0",
  "repos": {
    "baseDir": "~/Repos",
    "removeGitDir": true
  },
  "packageManagers": {
    "javascript": "bun",
    "python": "uv",
    "rust": "cargo"
  },
  "setup": {
    "autoInstallDeps": true,
    "confirmBeforeInstall": true
  }
}
```

### Per-Repository Configuration (`.gitdrc`)

Projects can include a `.gitdrc` file for custom setup:

```json
{
  "version": "1.0",
  "detection": {
    "language": "javascript",
    "tool": "pnpm"
  },
  "hooks": {
    "post-clone": {
      "commands": ["cp .env.example .env"]
    },
    "post-setup": {
      "commands": ["npm run build", "npm test"]
    }
  },
  "env": {
    "required": ["DATABASE_URL"],
    "defaults": {
      "NODE_ENV": "development"
    }
  },
  "workflows": {
    "dev": {
      "description": "Start development server",
      "steps": ["pnpm dev"]
    }
  }
}
```

See [.gitdrc Configuration Guide](docs/gitdrc-configuration.md) for full documentation.

---

## CLI Reference

### Commands

```bash
gitd [options] <repository_url>
```

### Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help message |
| `-v, --version` | Display version |
| `-s, --setup` | Run setup after cloning (install dependencies) |
| `-b, --branch <name>` | Clone a specific branch |

### Examples

```bash
# Basic clone
gitd https://github.com/facebook/react

# Clone and setup a Next.js project
gitd -s https://github.com/vercel/next.js

# Clone a specific branch with setup
gitd -s -b canary https://github.com/vercel/next.js

# Clone a Rust project
gitd -s https://github.com/rust-lang/rust
```

---

## Advanced Usage

### Customizing Repository Location

By default, repositories are cloned to `~/Repos`. Change this in the installer or edit `~/.gitd/config.json`:

```json
{
  "repos": {
    "baseDir": "~/Projects"
  }
}
```

### Upgrading GITD

```bash
# Using the installer
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Obed0101/gitd/main/install.sh)" -- --upgrade

# Or if already installed
cd ~/.gitd && git pull
```

### Uninstalling

```bash
bash ~/.gitd/uninstall.sh
```

---

## Roadmap

### v2.0 (Current)
- [x] Multi-language project detection (22+ languages)
- [x] Package manager preferences
- [x] Interactive installer with rollback
- [x] Bash and Zsh support
- [x] Automatic tool installation

### v2.1 (In Progress)
- [ ] Per-repository configuration (`.gitdrc`)
- [ ] Lifecycle hooks (post-clone, pre-setup, post-setup)
- [ ] Environment variable prompts
- [ ] Named workflows
- [ ] Editor integration

### v2.2 (Planned)
- [ ] Fish shell support
- [ ] Organize repos by owner (`~/Repos/owner/repo`)
- [ ] GitHub Actions integration
- [ ] VS Code extension
- [ ] `gitd update` command

### v3.0 (Future)
- [ ] Plugin system
- [ ] Template repositories
- [ ] Team/organization configurations
- [ ] CI/CD integration
- [ ] Web dashboard

---

## Security

GITD includes multiple security layers when executing repository configurations:

1. **Command Blacklist**: Blocks dangerous commands (`rm -rf /`, fork bombs, etc.)
2. **Sudo Protection**: Blocks sudo by default
3. **User Confirmation**: Prompts before executing hooks
4. **Timeout Protection**: Prevents infinite loops
5. **Error Handling**: Fails safely on errors

---

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

### Development Setup

```bash
# Clone the repository
git clone https://github.com/Obed0101/gitd.git
cd gitd

# Run tests
./tests/gitd.bats

# Test changes locally
source src/bash/gitd.bash
gitd -s https://github.com/your-test-repo
```

### Creating a Pull Request

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## Requirements

- **Shell**: Bash 4.0+ or Zsh 5.0+
- **Git**: For cloning repositories
- **GitHub CLI** (`gh`): For repository metadata
- **jq** (optional): For advanced JSON parsing

---

## License

Distributed under the Apache License 2.0. See [LICENSE](LICENSE) for more information.

---

## Authors

- **Obed0101** - [GitHub](https://github.com/Obed0101)
- **AlphaTechnolog** - [GitHub](https://github.com/AlphaTechnolog)

---

<p align="center">
  Made with determination in Mexico
  <br/>
  <a href="https://github.com/Obed0101/gitd">Star this repo</a> if you find it useful!
</p>
