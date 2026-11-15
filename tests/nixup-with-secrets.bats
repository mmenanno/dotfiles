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
