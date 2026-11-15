#!/usr/bin/env bats

load helpers

# nixup-with-secrets runs main when sourced, so load a copy without that line,
# next to the scripts it calls
setup() {
    setup_home
    BIN="$BATS_TEST_TMPDIR/bin"
    mkdir -p "$BIN"
    cp "$REPO_ROOT/bin/shared" "$REPO_ROOT/bin/syncthing-setup" "$BIN/"
    sed '/^main "\$@"/d' "$REPO_ROOT/bin/nixup-with-secrets" > "$BIN/nixup-with-secrets"
    # shellcheck disable=SC1091
    source "$BIN/nixup-with-secrets"
}

@test "run_syncthing_setup does nothing on the work machine" {
    mkdir -p "$HOME/.local/state/syncthing-setup"
    touch "$HOME/.local/state/syncthing-setup/a.pending"
    run run_syncthing_setup work_macbook
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "run_syncthing_setup never fails nx up, and reminds about pending folders" {
    printf '#!/usr/bin/env bash\nexit 3\n' > "$BIN/syncthing-setup"
    chmod +x "$BIN/syncthing-setup"
    mkdir -p "$HOME/.local/state/syncthing-setup"
    touch "$HOME/.local/state/syncthing-setup/a.pending" "$HOME/.local/state/syncthing-setup/b.pending"
    run run_syncthing_setup macbook_setup
    [ "$status" -eq 0 ]
    [[ "$output" == *"2 folders still receive-only"*"nx syncthing promote"* ]]
}

@test "run_syncthing_setup succeeds when setup skipped before creating its state folder" {
    printf '#!/usr/bin/env bash\nexit 0\n' > "$BIN/syncthing-setup"
    chmod +x "$BIN/syncthing-setup"
    # Under the script's own set -euo pipefail, which bats' `run` doesn't apply
    run bash -c 'set -euo pipefail; source "$1" >/dev/null; run_syncthing_setup macbook_setup; echo "nx up continued"' _ "$BIN/nixup-with-secrets"
    [ "$status" -eq 0 ]
    [[ "$output" == *"nx up continued"* ]]
}

@test "run_renpy_sdk_install installs on the personal Mac and never fails nx up" {
    printf '#!/usr/bin/env bash\necho "renpy-sdk $*"\nexit 1\n' > "$BIN/renpy-sdk"
    chmod +x "$BIN/renpy-sdk"
    run bash -c 'set -euo pipefail; source "$1" >/dev/null; run_renpy_sdk_install macbook_setup; echo "nx up continued"' _ "$BIN/nixup-with-secrets"
    [ "$status" -eq 0 ]
    [[ "$output" == *"renpy-sdk install"*"nx up continued"* ]]
}

@test "run_renpy_sdk_install does nothing on the work machine" {
    printf '#!/usr/bin/env bash\necho "renpy-sdk $*"\n' > "$BIN/renpy-sdk"
    chmod +x "$BIN/renpy-sdk"
    run run_renpy_sdk_install work_macbook
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "load_secrets stops with integration instructions when op has no account" {
    # shellcheck disable=SC2329  # called by load_secrets
    op() { [[ "$1 $2" == "account list" ]] && return 0; return 1; }
    run load_secrets
    [ "$status" -ne 0 ]
    [[ "$output" == *"Integrate with 1Password CLI"* ]]
    [[ "$output" != *"op signin"* ]]
}
