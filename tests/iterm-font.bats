#!/usr/bin/env bats

load helpers

# A throwaway preferences domain shaped like com.googlecode.iterm2's
setup() {
    DOMAIN="nx.test.iterm.$$.$BATS_TEST_NUMBER"
    SCRIPT="$REPO_ROOT/nix/files/iterm-font.js"
}

teardown() {
    defaults delete "$DOMAIN" >/dev/null 2>&1 || true
}

# Two regular profiles (Default first) and one dynamic profile
with_profiles() {
    defaults write "$DOMAIN" "New Bookmarks" -array \
        '<dict><key>Name</key><string>Default</string><key>Guid</key><string>AAA</string><key>Normal Font</key><string>Monaco 12</string></dict>' \
        '<dict><key>Name</key><string>Work</string><key>Guid</key><string>BBB</string><key>Normal Font</key><string>Monaco 12</string></dict>' \
        '<dict><key>Name</key><string>Nix</string><key>Guid</key><string>nix-managed-profile</string><key>Dynamic Profile Filename</key><string>/x/nix.json</string></dict>'
    [[ -n "${1:-}" ]] && defaults write "$DOMAIN" "Default Bookmark Guid" -string "$1"
    return 0
}

# Read through cfprefsd (the plist file on disk can lag behind)
profile_key() {
    defaults export "$DOMAIN" - | plutil -extract "New Bookmarks.$1.$2" raw -o - -
}

@test "sets the font and directory on the default profile" {
    with_profiles BBB
    run osascript -l JavaScript "$SCRIPT" "$DOMAIN" MesloLGSNFM-Regular 11
    [ "$status" -eq 0 ]
    [ "$output" = "Work" ]
    [ "$(profile_key 1 'Normal Font')" = "MesloLGSNFM-Regular 11" ]
    [ "$(profile_key 1 'Non Ascii Font')" = "MesloLGSNFM-Regular 11" ]
    [ "$(profile_key 1 'Custom Directory')" = "Recycle" ]
    [ "$(profile_key 0 'Normal Font')" = "Monaco 12" ]
}

@test "falls back to the first regular profile when the default is a dynamic profile" {
    with_profiles nix-managed-profile
    run osascript -l JavaScript "$SCRIPT" "$DOMAIN" MesloLGSNFM-Regular 11
    [ "$status" -eq 0 ]
    [ "$output" = "Default" ]
    [ "$(profile_key 0 'Normal Font')" = "MesloLGSNFM-Regular 11" ]
}

@test "reports when iTerm hasn't created its profiles yet" {
    run osascript -l JavaScript "$SCRIPT" "$DOMAIN" MesloLGSNFM-Regular 11
    [ "$status" -eq 0 ]
    [ "$output" = "no-profiles" ]
}

@test "reports when the font isn't installed" {
    with_profiles AAA
    run osascript -l JavaScript "$SCRIPT" "$DOMAIN" NoSuchFont-Regular 11
    [ "$status" -eq 0 ]
    [ "$output" = "no-font" ]
    [ "$(profile_key 0 'Normal Font')" = "Monaco 12" ]
}
