# Shared bats helpers: an isolated $HOME and sourcing bin/ scripts without
# running their main

REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"

setup_home() {
    export HOME="$BATS_TEST_TMPDIR/home"
    export BASELINE_DIR="$HOME/.local/share/nix-managed-baselines"
    mkdir -p "$HOME" "$BASELINE_DIR"
}

source_script() {
    # shellcheck disable=SC1090
    source "$REPO_ROOT/bin/$1"
}
