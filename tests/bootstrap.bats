#!/usr/bin/env bats

load helpers

setup() {
    setup_home
    export TERM_PROGRAM=Apple_Terminal
    # shellcheck disable=SC1091
    BOOTSTRAP_SOURCE_ONLY=1 source "$REPO_ROOT/bootstrap.sh"
}

clt_missing() {
    # shellcheck disable=SC2329  # called by start_xcode_tools_install
    xcode-select() { [[ "$1" == -p ]] && return 2; echo "install requested"; }
}

@test "only the Command Line Tools install: re-run once it finishes, no Terminal restart" {
    clt_missing
    # shellcheck disable=SC2329  # called by check_user_actions
    needs_app_management() { return 1; }
    run check_user_actions
    [ "$status" -eq 0 ]
    [[ "$output" == *"Command Line Tools finish installing"*"re-run this script"* ]]
    [[ "$output" != *"⌘Q"* ]]
}

@test "App Management needs a Terminal restart before re-running" {
    # shellcheck disable=SC2329  # called by start_xcode_tools_install
    xcode-select() { [[ "$1" == -p ]] && return 0; }
    # shellcheck disable=SC2329  # called by check_user_actions
    needs_app_management() { return 0; }
    run check_user_actions
    [ "$status" -eq 0 ]
    [[ "$output" == *"quit Terminal with ⌘Q"* ]]
}

@test "nothing to do: carries on without stopping" {
    # shellcheck disable=SC2329  # called by start_xcode_tools_install
    xcode-select() { [[ "$1" == -p ]] && return 0; }
    # shellcheck disable=SC2329  # called by check_user_actions
    needs_app_management() { return 1; }
    check_user_actions
    echo "continued"
}
