# Requirements: Per-Repository Configuration (.gitdrc)

## User Story

**As a** developer cloning repositories with GITD
**I want** to define custom setup configurations in my repository
**So that** collaborators can automatically set up the project with the correct tools, commands, and environment

## Acceptance Criteria (EARS Format)

### Core Detection Override

1. **WHEN** a `.gitdrc` file exists in the cloned repository root **THEN** GITD shall parse and validate it before running setup
2. **IF** `detection.language` is specified **THEN** GITD shall use that language instead of auto-detection
3. **IF** `detection.tool` is specified **THEN** GITD shall use that package manager instead of auto-detection
4. **IF** `detection.skip` is true **THEN** GITD shall skip all automatic detection and setup
5. **WHEN** `.gitdrc` contains invalid JSON **THEN** GITD shall display an error and fall back to auto-detection

### Lifecycle Hooks

6. **WHEN** `hooks.post-clone` is defined **THEN** GITD shall execute those commands immediately after cloning
7. **WHEN** `hooks.pre-setup` is defined **THEN** GITD shall execute those commands before package installation
8. **WHEN** `hooks.post-setup` is defined **THEN** GITD shall execute those commands after setup completes
9. **IF** a hook command fails and `continueOnError` is false **THEN** GITD shall abort and display the error
10. **IF** a hook command exceeds `timeout` milliseconds **THEN** GITD shall terminate it and show a timeout error

### Custom Setup Commands

11. **WHEN** `setup.commands` is defined **THEN** GITD shall execute those commands instead of default setup
12. **IF** `setup.skip` is true **THEN** GITD shall skip all setup steps (hooks and commands)
13. **WHEN** `setup.workdir` is specified **THEN** GITD shall execute setup commands from that directory

### Environment Variables

14. **WHEN** `env.required` contains variable names **THEN** GITD shall prompt the user for values before setup
15. **WHEN** `env.defaults` contains key-value pairs **THEN** GITD shall export those variables during setup
16. **IF** a required environment variable is not provided **THEN** GITD shall abort setup with an error
17. **WHEN** `env.prompts[key].secret` is true **THEN** GITD shall hide user input (like passwords)

### Workflows

18. **WHEN** the user runs `gitd workflow <name>` **THEN** GITD shall execute the steps defined in `workflows[name]`
19. **IF** the workflow name doesn't exist **THEN** GITD shall display available workflows and exit
20. **WHEN** listing workflows **THEN** GITD shall show the `description` field for each workflow

### Security

21. **WHEN** `security.requireConfirmation` is true (default) **THEN** GITD shall prompt before executing each hook command
22. **IF** a command contains sudo and `security.allowSudo` is false **THEN** GITD shall block execution
23. **WHEN** `security.restrictedCommands` contains patterns **THEN** GITD shall block matching commands
24. **WHEN** a blocked command is detected **THEN** GITD shall display a security warning

### Configuration Precedence

25. **WHEN** both CLI flags and `.gitdrc` specify settings **THEN** CLI flags shall take precedence
26. **WHEN** both `.gitdrc` and `~/.gitd/config.json` specify settings **THEN** `.gitdrc` shall take precedence
27. **WHEN** no configuration exists **THEN** GITD shall use built-in defaults

### Editor Integration

28. **WHEN** `editor.open` is specified **THEN** GITD shall open the project in that editor after setup
29. **IF** `editor.workspace` is specified **THEN** GITD shall open that workspace file instead of the directory

### Git Configuration

30. **IF** `git.keepGitDir` is true **THEN** GITD shall NOT remove the `.git` directory after cloning
31. **WHEN** `git.createBranch` is specified **THEN** GITD shall create and checkout that branch after setup

## Success Metrics

- [ ] **Adoption Rate**: 10% of cloned repositories have `.gitdrc` within 3 months
- [ ] **Zero Security Incidents**: No reported code execution vulnerabilities
- [ ] **Setup Time Reduction**: Average setup time reduced by 50% for configured repos
- [ ] **User Satisfaction**: 90% positive feedback on configuration experience

## Out of Scope

- Remote configuration fetching (`.gitdrc` must be in repo)
- GUI configuration editor (CLI only for v1.0)
- Windows PowerShell support (Bash/Zsh only)
- Encrypted secrets storage (use environment variables or external tools)
- Plugin/extension system (custom hooks only)

## Dependencies

- `jq` for JSON parsing (optional, with grep fallback)
- `yq` for YAML parsing (if YAML support added)
- Bash 4.0+ or Zsh 5.0+ for array/associative array support

## Related Documents

- [Design: System Architecture](./design.md)
- [Tasks: Implementation Sprint](./tasks.md)
- [JSON Schema: gitdrc.schema.json](../../gitdrc.schema.json)
