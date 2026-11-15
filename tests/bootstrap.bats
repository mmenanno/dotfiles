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

# A dotfiles clone whose origin is a local bare repo with one newer commit
make_clone() {
    export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
    BARE="$BATS_TEST_TMPDIR/origin.git"
    git init -q --bare -b main "$BARE"
    git clone -q "$BARE" "$BATS_TEST_TMPDIR/seed" 2>/dev/null
    git -C "$BATS_TEST_TMPDIR/seed" commit -q --allow-empty -m one
    git -C "$BATS_TEST_TMPDIR/seed" push -q origin HEAD:main
    git clone -q "file://$BARE" "$HOME/dotfiles"
    git -C "$BATS_TEST_TMPDIR/seed" commit -q --allow-empty -m two
    git -C "$BATS_TEST_TMPDIR/seed" push -q origin HEAD:main
    # shellcheck disable=SC2034  # read by setup_dotfiles
    DOTFILES_DIR="$HOME/dotfiles"
}

@test "the update check ignores git URL rewrites from the user's config" {
    make_clone
    # Like git.nix's https -> ssh rewrite, before any SSH key is set up
    git config --global url."file:///nonexistent/".insteadOf "file://"
    run setup_dotfiles
    [ "$status" -eq 0 ]
    [ "$(git -C "$HOME/dotfiles" log -1 --format=%s)" = "two" ]
}

@test "a failed update check warns and carries on with the current clone" {
    make_clone
    git -C "$HOME/dotfiles" remote set-url origin "file:///nonexistent/repo.git"
    run setup_dotfiles
    [ "$status" -eq 0 ]
    [[ "$output" == *"Couldn't check for updates"* ]]
    [[ "$output" == *"Dotfiles ready"* ]]
}

@test "a failure inside a function reports the error instead of exiting silently" {
    run bash -c 'BOOTSTRAP_SOURCE_ONLY=1 source "$1"; set -e; trap cleanup_on_error ERR; fails() { false; }; fails' _ "$REPO_ROOT/bootstrap.sh"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Script failed"* ]]
}

@test "a fresh clone also ignores git URL rewrites from the user's config" {
    make_clone
    rm -rf "$HOME/dotfiles"
    git config --global url."file:///nonexistent/".insteadOf "file://"
    # shellcheck disable=SC2034  # read by setup_dotfiles
    DOTFILES_REPO="file://$BARE"
    run setup_dotfiles
    [ "$status" -eq 0 ]
    [ "$(git -C "$HOME/dotfiles" log -1 --format=%s)" = "two" ]
}
