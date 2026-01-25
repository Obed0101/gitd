#!/usr/bin/env bats
# Tests for config-validator.sh module

setup() {
    export GITD_INSTALL="${BATS_TEST_DIRNAME}/.."
    source "$GITD_INSTALL/src/lib/utils.sh"
    source "$GITD_INSTALL/src/lib/config-validator.sh"

    TEST_DIR=$(mktemp -d)
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "validate_json_syntax passes valid JSON" {
    echo '{"version": "1.0"}' > "$TEST_DIR/config.json"

    run validate_json_syntax "$TEST_DIR/config.json"
    [ "$status" -eq 0 ]
}

@test "validate_json_syntax fails invalid JSON" {
    echo '{version: 1.0}' > "$TEST_DIR/config.json"

    run validate_json_syntax "$TEST_DIR/config.json"
    [ "$status" -eq 1 ]
}

@test "validate_json_syntax fails on missing file" {
    run validate_json_syntax "$TEST_DIR/nonexistent.json"
    [ "$status" -eq 1 ]
}

@test "validate_required_fields warns on missing version" {
    echo '{}' > "$TEST_DIR/config.json"

    result=$(validate_required_fields "$TEST_DIR/config.json")
    echo "$result" | grep -q "warning.*version"
}

@test "validate_required_fields passes with version" {
    echo '{"version": "1.0"}' > "$TEST_DIR/config.json"

    run validate_required_fields "$TEST_DIR/config.json"
    [ "$status" -eq 0 ]
}

@test "validate_detection passes valid language" {
    echo '{"version": "1.0", "detection": {"language": "javascript"}}' > "$TEST_DIR/config.json"

    if command -v jq &>/dev/null; then
        run validate_detection "$TEST_DIR/config.json"
        [ "$status" -eq 0 ]
    else
        skip "jq not installed"
    fi
}

@test "validate_detection fails invalid language" {
    echo '{"version": "1.0", "detection": {"language": "invalid_lang"}}' > "$TEST_DIR/config.json"

    if command -v jq &>/dev/null; then
        result=$(validate_detection "$TEST_DIR/config.json")
        echo "$result" | grep -q "error.*invalid_lang"
    else
        skip "jq not installed"
    fi
}

@test "validate_detection passes valid tool" {
    echo '{"version": "1.0", "detection": {"tool": "pnpm"}}' > "$TEST_DIR/config.json"

    if command -v jq &>/dev/null; then
        run validate_detection "$TEST_DIR/config.json"
        [ "$status" -eq 0 ]
    else
        skip "jq not installed"
    fi
}

@test "validate_detection fails invalid tool" {
    echo '{"version": "1.0", "detection": {"tool": "invalid_tool"}}' > "$TEST_DIR/config.json"

    if command -v jq &>/dev/null; then
        result=$(validate_detection "$TEST_DIR/config.json")
        echo "$result" | grep -q "error.*invalid_tool"
    else
        skip "jq not installed"
    fi
}

@test "validate_hooks warns on unknown hook type" {
    echo '{"version": "1.0", "hooks": {"pre-unknown": {"commands": ["echo"]}}}' > "$TEST_DIR/config.json"

    if command -v jq &>/dev/null; then
        result=$(validate_hooks "$TEST_DIR/config.json")
        echo "$result" | grep -q "warning.*pre-unknown"
    else
        skip "jq not installed"
    fi
}

@test "validate_hooks passes valid hook types" {
    echo '{"version": "1.0", "hooks": {"post-clone": {"commands": ["echo"]}}}' > "$TEST_DIR/config.json"

    if command -v jq &>/dev/null; then
        run validate_hooks "$TEST_DIR/config.json"
        [ "$status" -eq 0 ]
    else
        skip "jq not installed"
    fi
}

@test "validate_hooks fails when commands is not array" {
    echo '{"version": "1.0", "hooks": {"post-clone": {"commands": "not an array"}}}' > "$TEST_DIR/config.json"

    if command -v jq &>/dev/null; then
        result=$(validate_hooks "$TEST_DIR/config.json")
        echo "$result" | grep -q "error.*array"
    else
        skip "jq not installed"
    fi
}

@test "validate_hooks fails when timeout is invalid" {
    echo '{"version": "1.0", "hooks": {"post-clone": {"commands": ["echo"], "timeout": -1}}}' > "$TEST_DIR/config.json"

    if command -v jq &>/dev/null; then
        result=$(validate_hooks "$TEST_DIR/config.json")
        echo "$result" | grep -q "error.*timeout"
    else
        skip "jq not installed"
    fi
}

@test "validate_workflows warns on bad workflow name" {
    echo '{"version": "1.0", "workflows": {"Bad_Name": {"steps": ["echo"]}}}' > "$TEST_DIR/config.json"

    if command -v jq &>/dev/null; then
        result=$(validate_workflows "$TEST_DIR/config.json")
        echo "$result" | grep -q "warning.*Bad_Name"
    else
        skip "jq not installed"
    fi
}

@test "validate_workflows passes valid workflow names" {
    echo '{"version": "1.0", "workflows": {"dev": {"steps": ["echo"]}}}' > "$TEST_DIR/config.json"

    if command -v jq &>/dev/null; then
        run validate_workflows "$TEST_DIR/config.json"
        [ "$status" -eq 0 ]
    else
        skip "jq not installed"
    fi
}

@test "validate_workflows warns on empty steps" {
    echo '{"version": "1.0", "workflows": {"dev": {"steps": []}}}' > "$TEST_DIR/config.json"

    if command -v jq &>/dev/null; then
        result=$(validate_workflows "$TEST_DIR/config.json")
        echo "$result" | grep -q "warning.*empty"
    else
        skip "jq not installed"
    fi
}

@test "validate_env passes valid env config" {
    echo '{"version": "1.0", "env": {"required": ["DATABASE_URL"], "optional": ["DEBUG"]}}' > "$TEST_DIR/config.json"

    if command -v jq &>/dev/null; then
        run validate_env "$TEST_DIR/config.json"
        [ "$status" -eq 0 ]
    else
        skip "jq not installed"
    fi
}

@test "validate_env fails when required is not array" {
    echo '{"version": "1.0", "env": {"required": "not array"}}' > "$TEST_DIR/config.json"

    if command -v jq &>/dev/null; then
        result=$(validate_env "$TEST_DIR/config.json")
        echo "$result" | grep -q "error.*array"
    else
        skip "jq not installed"
    fi
}

@test "validate_repo_config passes complete valid config" {
    cat > "$TEST_DIR/config.json" << 'EOF'
{
  "version": "1.0",
  "detection": {
    "language": "javascript",
    "tool": "pnpm"
  },
  "hooks": {
    "post-clone": {
      "commands": ["echo test"],
      "timeout": 30000
    }
  },
  "workflows": {
    "dev": {
      "description": "Start dev server",
      "steps": ["npm run dev"]
    }
  },
  "env": {
    "required": ["DATABASE_URL"],
    "defaults": {
      "NODE_ENV": "development"
    }
  }
}
EOF

    if command -v jq &>/dev/null; then
        run validate_repo_config "$TEST_DIR/config.json"
        [ "$status" -eq 0 ]
    else
        skip "jq not installed"
    fi
}

@test "is_config_valid returns true for valid config" {
    echo '{"version": "1.0"}' > "$TEST_DIR/config.json"

    run is_config_valid "$TEST_DIR/config.json"
    [ "$status" -eq 0 ]
}

@test "is_config_valid returns false for invalid JSON" {
    echo 'not valid json' > "$TEST_DIR/config.json"

    run is_config_valid "$TEST_DIR/config.json"
    [ "$status" -eq 1 ]
}
