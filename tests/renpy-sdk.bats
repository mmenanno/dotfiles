#!/usr/bin/env bats

load helpers

setup() {
    setup_home
    export CALLS="$BATS_TEST_TMPDIR/calls"
    : > "$CALLS"
    # A stand-in release: a zip holding renpy-8.5.3-sdk/renpy.app
    local src="$BATS_TEST_TMPDIR/src"
    mkdir -p "$src/renpy-8.5.3-sdk/renpy.app/Contents/MacOS"
    echo binary > "$src/renpy-8.5.3-sdk/renpy.app/Contents/MacOS/python"
    (cd "$src" && zip -qr "$BATS_TEST_TMPDIR/sdk.zip" renpy-8.5.3-sdk)
    export FIXTURE_ZIP="$BATS_TEST_TMPDIR/sdk.zip"
    source_script renpy-sdk
    RENPY_SDK_SHA256="$(shasum -a 256 "$FIXTURE_ZIP" | cut -d' ' -f1)"
    # Writes the fixture wherever -o points, and logs the call
    # shellcheck disable=SC2329  # called by download_sdk
    curl() {
        echo "curl $*" >> "$CALLS"
        local out=""
        while (( $# )); do
            [[ "$1" == -o ]] && { out="$2"; shift; }
            shift
        done
        cp "$FIXTURE_ZIP" "$out"
    }
}

@test "install puts the SDK in ~/Applications/renpy-sdk with a version marker" {
    run install_sdk
    [ "$status" -eq 0 ]
    [ -f "$HOME/Applications/renpy-sdk/renpy.app/Contents/MacOS/python" ]
    [ "$(cat "$HOME/Applications/renpy-sdk/.dotfiles-renpy-version")" = "8.5.3" ]
}

@test "install does nothing when this version is already installed" {
    install_sdk
    : > "$CALLS"
    run install_sdk
    [ "$status" -eq 0 ]
    [ ! -s "$CALLS" ]
}

@test "a checksum mismatch fails and leaves no SDK behind" {
    # shellcheck disable=SC2034  # read by install_sdk
    RENPY_SDK_SHA256=0000000000000000000000000000000000000000000000000000000000000000
    run install_sdk
    [ "$status" -ne 0 ]
    [[ "$output" == *"checksum"* ]]
    [ ! -e "$HOME/Applications/renpy-sdk" ]
}

@test "an older installed version is replaced" {
    mkdir -p "$HOME/Applications/renpy-sdk"
    echo 8.4.0 > "$HOME/Applications/renpy-sdk/.dotfiles-renpy-version"
    touch "$HOME/Applications/renpy-sdk/old-file"
    run install_sdk
    [ "$status" -eq 0 ]
    [ "$(cat "$HOME/Applications/renpy-sdk/.dotfiles-renpy-version")" = "8.5.3" ]
    [ ! -e "$HOME/Applications/renpy-sdk/old-file" ]
}

@test "an SDK this script didn't install is left alone" {
    mkdir -p "$HOME/Applications/renpy-sdk"
    touch "$HOME/Applications/renpy-sdk/mine"
    run install_sdk
    [ "$status" -eq 0 ]
    [[ "$output" == *"didn't install"* ]]
    [ -e "$HOME/Applications/renpy-sdk/mine" ]
    [ ! -s "$CALLS" ]
}
