#!/usr/bin/env bats

# Setup: source the gitd function before each test
setup() {
    export GITD_INSTALL="${BATS_TEST_DIRNAME}/.."

    # Determine which shell script to source
    if [ -n "$ZSH_VERSION" ]; then
        source "$GITD_INSTALL/src/zsh/gitd.zsh"
    else
        source "$GITD_INSTALL/src/bash/gitd.bash"
    fi
}

@test "gitd --version returns version" {
    run gitd --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"0.2-beta"* ]]
}

@test "gitd -v returns version" {
    run gitd -v
    [ "$status" -eq 0 ]
    [[ "$output" == *"0.2-beta"* ]]
}

@test "gitd --help shows usage" {
    run gitd --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
    [[ "$output" == *"--help"* ]]
    [[ "$output" == *"--version"* ]]
    [[ "$output" == *"--setup"* ]]
    [[ "$output" == *"--branch"* ]]
}

@test "gitd -h shows usage" {
    run gitd -h
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "gitd without args shows error" {
    run gitd
    [ "$status" -ne 0 ]
    [[ "$output" == *"Error"* ]]
}

@test "gitd with invalid URL shows error" {
    # This test requires gh CLI to be available
    if ! command -v gh &>/dev/null; then
        skip "gh CLI not installed"
    fi

    run gitd https://github.com/nonexistent-user-12345/nonexistent-repo-67890
    [ "$status" -ne 0 ]
    [[ "$output" == *"Error"* ]] || [[ "$output" == *"does not exist"* ]]
}
