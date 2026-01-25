# Tasks: Per-Repository Configuration Implementation

## Sprint Overview

| Sprint | Focus | Duration |
|--------|-------|----------|
| Sprint 1 | Core Infrastructure | Week 1 |
| Sprint 2 | Hooks & Security | Week 2 |
| Sprint 3 | Environment & Workflows | Week 3 |
| Sprint 4 | Polish & Documentation | Week 4 |

---

## Sprint 1: Core Infrastructure

### Goal: Basic .gitdrc detection and parsing

- [ ] **Task 1.1**: Create `config-repo.sh` module
  - Implement `load_repo_config()` function
  - Search for: `.gitdrc`, `.gitdrc.json`, `.gitd.json`
  - Return path to found config or empty string
  - **Acceptance**: Can detect .gitdrc in test repo

- [ ] **Task 1.2**: Create `config-validator.sh` module
  - Implement JSON syntax validation (using jq)
  - Implement schema validation (version field required)
  - Return validation errors as structured output
  - **Acceptance**: Invalid JSON returns clear error

- [ ] **Task 1.3**: Create `config-merge.sh` module
  - Implement `merge_configs()` function
  - Handle precedence: CLI > Repo > User > Defaults
  - Deep merge nested objects
  - **Acceptance**: CLI flags override repo config

- [ ] **Task 1.4**: Integrate into `gitd.bash`
  - Call `load_repo_config()` after clone
  - Display config detection status
  - Pass config to setup.sh
  - **Acceptance**: Shows "Found .gitdrc" message

- [ ] **Task 1.5**: Integrate into `gitd.zsh`
  - Mirror changes from gitd.bash
  - Ensure Zsh compatibility
  - **Acceptance**: Works identically in Zsh

- [ ] **Task 1.6**: Implement detection override
  - Read `detection.language` from config
  - Read `detection.tool` from config
  - Override auto-detection if specified
  - **Acceptance**: Config tool overrides lockfile detection

---

## Sprint 2: Hooks & Security

### Goal: Safe execution of lifecycle hooks

- [ ] **Task 2.1**: Create `security.sh` module
  - Implement `DANGEROUS_PATTERNS` blacklist
  - Implement `is_command_safe()` function
  - Implement `analyze_config_security()` function
  - **Acceptance**: Blocks "rm -rf /" commands

- [ ] **Task 2.2**: Create `hooks.sh` module
  - Implement `execute_hooks()` function
  - Support hook types: post-clone, pre-setup, post-setup
  - Implement timeout handling
  - Implement continueOnError logic
  - **Acceptance**: Hooks execute in order with timeout

- [ ] **Task 2.3**: Implement user confirmation flow
  - Show hooks summary before execution
  - Display security analysis results
  - Prompt for confirmation (default: yes)
  - **Acceptance**: User can approve/deny hook execution

- [ ] **Task 2.4**: Integrate hooks into main flow
  - Execute post-clone after git clone
  - Execute pre-setup before package install
  - Execute post-setup after package install
  - **Acceptance**: Full lifecycle hooks work

- [ ] **Task 2.5**: Add sudo protection
  - Detect sudo in commands
  - Block if `allowSudo: false` (default)
  - Show warning even if allowed
  - **Acceptance**: sudo commands blocked by default

- [ ] **Task 2.6**: Add restricted commands support
  - Read `security.restrictedCommands` from config
  - Add to blacklist dynamically
  - **Acceptance**: Custom blocked commands work

---

## Sprint 3: Environment & Workflows

### Goal: Environment variables and workflow execution

- [ ] **Task 3.1**: Create `env-vars.sh` module
  - Implement `prompt_env_vars()` function
  - Support required/optional distinction
  - Support default values
  - Support secret input (hidden)
  - **Acceptance**: Prompts for required vars

- [ ] **Task 3.2**: Implement env prompts with validation
  - Read `env.prompts[key].validate` regex
  - Validate user input
  - Re-prompt on invalid input
  - **Acceptance**: Invalid input shows error

- [ ] **Task 3.3**: Create `workflows.sh` module
  - Implement `list_workflows()` function
  - Implement `execute_workflow()` function
  - Support workdir per workflow
  - **Acceptance**: Can run named workflow

- [ ] **Task 3.4**: Add workflow CLI command
  - Add `gitd workflow <name>` subcommand
  - Add `gitd workflow --list` option
  - Show descriptions in list
  - **Acceptance**: `gitd workflow dev` runs dev workflow

- [ ] **Task 3.5**: Implement editor integration
  - Read `editor.open` setting
  - Open editor after setup
  - Support workspace files
  - **Acceptance**: VS Code opens after setup

- [ ] **Task 3.6**: Implement git configuration
  - Read `git.keepGitDir` setting
  - Read `git.createBranch` setting
  - Create branch if specified
  - **Acceptance**: Can keep .git and create branch

---

## Sprint 4: Polish & Documentation

### Goal: Production-ready release

- [ ] **Task 4.1**: Write comprehensive tests
  - Test config loading
  - Test validation
  - Test hook execution
  - Test security blocking
  - **Acceptance**: All tests pass

- [ ] **Task 4.2**: Update README.md
  - Add .gitdrc section
  - Add configuration examples
  - Update feature list
  - Add roadmap section
  - **Acceptance**: README is complete

- [ ] **Task 4.3**: Create example .gitdrc files
  - Minimal example
  - Node.js project
  - Rust project
  - Python ML project
  - Monorepo example
  - **Acceptance**: 5+ examples in /examples

- [ ] **Task 4.4**: Add --dry-run flag
  - Show what would execute without running
  - Display merged configuration
  - **Acceptance**: Dry run shows commands

- [ ] **Task 4.5**: Add verbose logging
  - Add --verbose flag
  - Log each step with details
  - Log security decisions
  - **Acceptance**: Verbose shows full trace

- [ ] **Task 4.6**: Performance optimization
  - Cache config parsing
  - Minimize file reads
  - Parallelize independent hooks
  - **Acceptance**: No noticeable slowdown

---

## Risks & Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Security vulnerability in hook execution | Critical | Medium | Multiple security layers, user confirmation |
| jq not available on all systems | Medium | High | Grep fallback for basic parsing |
| Breaking changes to existing users | Medium | Low | Version field for migration |
| Performance impact from config loading | Low | Medium | Lazy loading, caching |
| Complex error messages confuse users | Medium | Medium | Clear, actionable error messages |

---

## Definition of Done

Each task is complete when:

1. Code is written and follows existing style
2. Works in both Bash and Zsh
3. Has error handling for edge cases
4. Has at least one test case
5. Documentation is updated
6. Code reviewed (self or peer)

---

## Dependencies

```
Sprint 1 (Core) ──────────────────────┐
                                      │
Sprint 2 (Hooks) ─────────────────────┼───▶ Sprint 4 (Polish)
                                      │
Sprint 3 (Env/Workflows) ─────────────┘
```

- Sprint 2 depends on Sprint 1 (config loading)
- Sprint 3 depends on Sprint 1 (config loading)
- Sprint 4 depends on all previous sprints

---

## Milestones

| Milestone | Target Date | Deliverable |
|-----------|-------------|-------------|
| M1: Config Loading | Week 1 | .gitdrc detection and parsing |
| M2: Secure Hooks | Week 2 | Hook execution with security |
| M3: Full Features | Week 3 | Env vars, workflows, editor |
| M4: v2.1 Release | Week 4 | Production-ready release |
