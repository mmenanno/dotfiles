#!/usr/bin/env bats

load helpers

# A throwaway preferences domain shaped like com.apple.Terminal's
setup() {
    DOMAIN="nx.test.terminal.$$.$BATS_TEST_NUMBER"
    SCRIPT="$REPO_ROOT/nix/files/terminal-font.js"
}

teardown() {
    defaults delete "$DOMAIN" >/dev/null 2>&1 || true
}

with_profiles() {
    defaults write "$DOMAIN" "Default Window Settings" -string "$1"
    defaults write "$DOMAIN" "Window Settings" -dict \
        "Clear Dark" '<dict><key>name</key><string>Clear Dark</string></dict>' \
        "Basic" '<dict><key>name</key><string>Basic</string></dict>'
}

# Print the font a profile in $DOMAIN would use, as "<name> <size>"
profile_font() {
    osascript -l JavaScript -e '
        ObjC.import("AppKit");
        function run(argv) {
            var p = $.NSUserDefaults.alloc.initWithSuiteName(argv[0]).dictionaryForKey("Window Settings").objectForKey(argv[1]);
            var data = p.objectForKey("Font");
            if (data.isNil()) return "none";
            var f = $.NSKeyedUnarchiver.unarchivedObjectOfClassFromDataError($.NSFont, data, null);
            return ObjC.unwrap(f.fontName) + " " + f.pointSize;
        }' "$DOMAIN" "$1"
}

@test "sets the font on the default profile, not Basic" {
    with_profiles "Clear Dark"
    run osascript -l JavaScript "$SCRIPT" "$DOMAIN" MesloLGSNFM-Regular 11
    [ "$status" -eq 0 ]
    [ "$output" = "Clear Dark" ]
    [ "$(profile_font "Clear Dark")" = "MesloLGSNFM-Regular 11" ]
    [ "$(profile_font Basic)" = "none" ]
}

@test "reports when Terminal has no saved profiles yet" {
    run osascript -l JavaScript "$SCRIPT" "$DOMAIN" MesloLGSNFM-Regular 11
    [ "$status" -eq 0 ]
    [ "$output" = "no-profiles" ]
}

@test "reports when the font isn't installed" {
    with_profiles "Clear Dark"
    run osascript -l JavaScript "$SCRIPT" "$DOMAIN" NoSuchFont-Regular 11
    [ "$status" -eq 0 ]
    [ "$output" = "no-font" ]
    [ "$(profile_font "Clear Dark")" = "none" ]
}
