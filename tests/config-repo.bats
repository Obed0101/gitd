#!/usr/bin/env bats
# Tests for config-repo.sh module

setup() {
    # Load the module
    export GITD_INSTALL="${BATS_TEST_DIRNAME}/.."
    source "$GITD_INSTALL/src/lib/utils.sh"
    source "$GITD_INSTALL/src/lib/config-repo.sh"

    # Create temp directory for tests
    TEST_DIR=$(mktemp -d)
}

teardown() {
    # Cleanup
    rm -rf "$TEST_DIR"
}

@test "load_repo_config finds .gitdrc file" {
    # Create test config
    echo '{"version": "1.0"}' > "$TEST_DIR/.gitdrc"

    result=$(load_repo_config "$TEST_DIR")
    [ "$result" = "$TEST_DIR/.gitdrc" ]
}

@test "load_repo_config finds .gitdrc.json file" {
    echo '{"version": "1.0"}' > "$TEST_DIR/.gitdrc.json"

    result=$(load_repo_config "$TEST_DIR")
    [ "$result" = "$TEST_DIR/.gitdrc.json" ]
}

@test "load_repo_config prefers .gitdrc over .gitdrc.json" {
    echo '{"version": "1.0", "type": "gitdrc"}' > "$TEST_DIR/.gitdrc"
    echo '{"version": "1.0", "type": "json"}' > "$TEST_DIR/.gitdrc.json"

    result=$(load_repo_config "$TEST_DIR")
    [ "$result" = "$TEST_DIR/.gitdrc" ]
}

@test "load_repo_config returns empty for missing config" {
    result=$(load_repo_config "$TEST_DIR")
    [ -z "$result" ]
}

@test "has_repo_config returns true when config exists" {
    echo '{"version": "1.0"}' > "$TEST_DIR/.gitdrc"

    run has_repo_config "$TEST_DIR"
    [ "$status" -eq 0 ]
}

@test "has_repo_config returns false when config missing" {
    run has_repo_config "$TEST_DIR"
    [ "$status" -eq 1 ]
}

@test "repo_config_get reads simple value" {
    echo '{"version": "1.0", "detection": {"language": "javascript"}}' > "$TEST_DIR/.gitdrc"
    load_repo_config "$TEST_DIR" > /dev/null

    if command -v jq &>/dev/null; then
        result=$(repo_config_get "detection.language" "")
        [ "$result" = "javascript" ]
    else
        skip "jq not installed"
    fi
}

@test "repo_config_get returns default for missing key" {
    echo '{"version": "1.0"}' > "$TEST_DIR/.gitdrc"
    load_repo_config "$TEST_DIR" > /dev/null

    result=$(repo_config_get "nonexistent.key" "default_value")
    [ "$result" = "default_value" ]
}

@test "repo_config_get_bool returns true for true value" {
    echo '{"version": "1.0", "setup": {"skip": true}}' > "$TEST_DIR/.gitdrc"
    load_repo_config "$TEST_DIR" > /dev/null

    if command -v jq &>/dev/null; then
        run repo_config_get_bool "setup.skip" "false"
        [ "$status" -eq 0 ]
    else
        skip "jq not installed"
    fi
}

@test "repo_config_get_bool returns false for false value" {
    echo '{"version": "1.0", "setup": {"skip": false}}' > "$TEST_DIR/.gitdrc"
    load_repo_config "$TEST_DIR" > /dev/null

    if command -v jq &>/dev/null; then
        run repo_config_get_bool "setup.skip" "true"
        [ "$status" -eq 1 ]
    else
        skip "jq not installed"
    fi
}

@test "repo_config_get_detection_language reads override" {
    echo '{"version": "1.0", "detection": {"language": "rust", "tool": "cargo"}}' > "$TEST_DIR/.gitdrc"
    load_repo_config "$TEST_DIR" > /dev/null

    if command -v jq &>/dev/null; then
        result=$(repo_config_get_detection_language)
        [ "$result" = "rust" ]
    else
        skip "jq not installed"
    fi
}

@test "repo_config_get_detection_tool reads override" {
    echo '{"version": "1.0", "detection": {"language": "javascript", "tool": "bun"}}' > "$TEST_DIR/.gitdrc"
    load_repo_config "$TEST_DIR" > /dev/null

    if command -v jq &>/dev/null; then
        result=$(repo_config_get_detection_tool)
        [ "$result" = "bun" ]
    else
        skip "jq not installed"
    fi
}

@test "repo_config_should_skip_setup returns correct value" {
    echo '{"version": "1.0", "setup": {"skip": true}}' > "$TEST_DIR/.gitdrc"
    load_repo_config "$TEST_DIR" > /dev/null

    if command -v jq &>/dev/null; then
        run repo_config_should_skip_setup
        [ "$status" -eq 0 ]
    else
        skip "jq not installed"
    fi
}

@test "repo_config_has_hook detects hooks" {
    echo '{"version": "1.0", "hooks": {"post-clone": {"commands": ["echo test"]}}}' > "$TEST_DIR/.gitdrc"
    load_repo_config "$TEST_DIR" > /dev/null

    if command -v jq &>/dev/null; then
        run repo_config_has_hook "post-clone"
        [ "$status" -eq 0 ]
    else
        skip "jq not installed"
    fi
}

@test "repo_config_has_hook returns false for missing hooks" {
    echo '{"version": "1.0"}' > "$TEST_DIR/.gitdrc"
    load_repo_config "$TEST_DIR" > /dev/null

    run repo_config_has_hook "post-clone"
    [ "$status" -eq 1 ]
}

@test "repo_config_get_hook_commands returns commands" {
    echo '{"version": "1.0", "hooks": {"post-clone": {"commands": ["echo one", "echo two"]}}}' > "$TEST_DIR/.gitdrc"
    load_repo_config "$TEST_DIR" > /dev/null

    if command -v jq &>/dev/null; then
        result=$(repo_config_get_hook_commands "post-clone" | wc -l | tr -d ' ')
        [ "$result" -eq 2 ]
    else
        skip "jq not installed"
    fi
}

@test "repo_config_has_workflow detects workflows" {
    echo '{"version": "1.0", "workflows": {"dev": {"steps": ["npm run dev"]}}}' > "$TEST_DIR/.gitdrc"
    load_repo_config "$TEST_DIR" > /dev/null

    if command -v jq &>/dev/null; then
        run repo_config_has_workflow "dev"
        [ "$status" -eq 0 ]
    else
        skip "jq not installed"
    fi
}

@test "repo_config_list_workflows returns workflow names" {
    echo '{"version": "1.0", "workflows": {"dev": {"steps": ["a"]}, "build": {"steps": ["b"]}}}' > "$TEST_DIR/.gitdrc"
    load_repo_config "$TEST_DIR" > /dev/null

    if command -v jq &>/dev/null; then
        result=$(repo_config_list_workflows | wc -l | tr -d ' ')
        [ "$result" -eq 2 ]
    else
        skip "jq not installed"
    fi
}

@test "repo_config_get_version returns version" {
    echo '{"version": "1.0"}' > "$TEST_DIR/.gitdrc"
    load_repo_config "$TEST_DIR" > /dev/null

    result=$(repo_config_get_version)
    [ "$result" = "1.0" ]
}
