#!/usr/bin/env bats

load helpers

UNRAID=W5YSYTY-AAAAAAA-BBBBBBB-CCCCCCC-DDDDDDD-EEEEEEE-FFFFFFF-GGGGGGG

setup() {
    setup_home
    export CALLS="$BATS_TEST_TMPDIR/calls"
    export FIX="$BATS_TEST_TMPDIR/fix"
    export SYNCTHING_SPEC="$BATS_TEST_TMPDIR/syncthing.json"
    export SYNCTHING_CONFIG="$HOME/Library/Application Support/Syncthing/config.xml"
    mkdir -p "$FIX" "$(dirname "$SYNCTHING_CONFIG")"
    : > "$CALLS"
    cat > "$SYNCTHING_CONFIG" <<'XML'
<configuration><gui><address>127.0.0.1:8384</address><apikey>k</apikey></gui></configuration>
XML
    write_spec "$UNRAID"
    fixture GET /rest/config/folders '[]'
    fixture GET /rest/config/devices '[]'
    fixture GET /rest/config/defaults/folder '{"id":"","path":"","type":"sendreceive","devices":[],"minDiskFree":{"value":1,"unit":"%"}}'
    fixture GET /rest/config/defaults/device '{"deviceID":"","name":"","addresses":["dynamic"],"compression":"metadata"}'
    fixture GET /rest/system/ping '{"ping":"pong"}'
    fixture GET /rest/system/connections "{\"connections\":{\"$UNRAID\":{\"connected\":true}}}"
    source_script syncthing-setup
    # Answers from $FIX/<METHOD><path with / and ? as _>, and logs each call
    st_api() {
        local method="$1" path="$2" body="${3:-}" key
        printf '%s %s %s\n' "$method" "$path" "$body" >> "$CALLS"
        key="$method${path//[\/?=&]/_}"
        if [[ -f "$FIX/$key" ]]; then cat "$FIX/$key"; else echo '{}'; fi
    }
    open() { echo "open $*" >> "$CALLS"; }
}

fixture() {
    local key="$1${2//[\/?=&]/_}"
    printf '%s' "$3" > "$FIX/$key"
}

write_spec() {
    jq -n --arg id "$1" '{
        unraidDeviceId: $id,
        unraidName: "Unraid Server",
        folderDefaults: {fsWatcherEnabled: true, rescanIntervalS: 3600, order: "random"},
        folders: [
            {id: "michael-macbook-desktop", label: "desktop", path: "~/Desktop", ignores: [".DS_Store"]},
            {id: "michael-macbook-dev", label: "dev", path: "~/dev", ignores: []},
            {id: "michael-macbook-documents", label: "documents", path: "~/Documents", ignores: []},
            {id: "michael-macbook-downloads", label: "downloads", path: "~/Downloads", ignores: []},
            {id: "michael-macbook-minecraft", label: "minecraft", path: "~/minecraft", ignores: []},
            {id: "michael-macbook-movies", label: "movies", path: "~/Movies", ignores: [".DS_Store"]},
            {id: "michael-macbook-music", label: "music", path: "~/Music", ignores: [".DS_Store"]},
            {id: "michael-macbook-pictures", label: "pictures", path: "~/Pictures",
             ignores: [".DS_Store", "Photo Booth Library", "Photos Library.photoslibrary"]},
            {id: "michael-macbook-tasks", label: "tasks", path: "~/tasks", ignores: ["/bunkr/downloads", "/bunkr/logs"]},
            {id: "michael-macbook-writing", label: "writing", path: "~/writing", ignores: []}
        ]}' > "$SYNCTHING_SPEC"
}

pending_count() {
    find "$HOME/.local/state/syncthing-setup" -name '*.pending' 2>/dev/null | wc -l | tr -d ' '
}

folder_status() {
    fixture GET "/rest/db/status?folder=$1" "$2"
}

@test "apply with no Syncthing config exits 0 without calling the API" {
    rm "$SYNCTHING_CONFIG"
    run cmd_apply
    [ "$status" -eq 0 ]
    [[ "$output" == *"Syncthing isn't set up yet"* ]]
    [ ! -s "$CALLS" ]
}

@test "apply with no Unraid device ID skips, naming the variable" {
    write_spec ""
    run cmd_apply
    [ "$status" -eq 0 ]
    [[ "$output" == *"NIX_SYNCTHING_UNRAID_ID"* ]]
    refute grep -q '^PUT /rest/config/devices/' "$CALLS"
}

@test "apply on an empty Syncthing adds the device and all 10 folders as receive-only" {
    run cmd_apply
    [ "$status" -eq 0 ]
    grep -q "^PUT /rest/config/devices/$UNRAID .*\"name\":\"Unraid Server\"" "$CALLS"
    [ "$(grep -c '^PUT /rest/config/folders/' "$CALLS")" -eq 10 ]
    refute grep -qv '"type":"receiveonly"' <(grep '^PUT /rest/config/folders/' "$CALLS")
    grep -q "^PUT /rest/config/folders/michael-macbook-pictures .*\"deviceID\":\"$UNRAID\"" "$CALLS"
    grep -q '^PUT /rest/config/folders/michael-macbook-pictures .*"minDiskFree"' "$CALLS"
    grep -qF 'POST /rest/db/ignores?folder=michael-macbook-pictures {"ignore":[".DS_Store","Photo Booth Library","Photos Library.photoslibrary"]}' "$CALLS"
    [ "$(pending_count)" -eq 10 ]
}

@test "apply leaves a folder ID that already exists alone" {
    fixture GET /rest/config/folders '[{"id":"michael-macbook-dev","path":"~/dev","type":"sendonly"}]'
    fixture GET /rest/config/devices "[{\"deviceID\":\"$UNRAID\"}]"
    run cmd_apply
    [ "$status" -eq 0 ]
    refute grep -q '^PUT /rest/config/folders/michael-macbook-dev ' "$CALLS"
    refute grep -q '^PUT /rest/config/devices/' "$CALLS"
    [ "$(grep -c '^PUT /rest/config/folders/' "$CALLS")" -eq 9 ]
}

@test "apply warns and skips when another folder already uses the path" {
    fixture GET /rest/config/folders "[{\"id\":\"something-else\",\"path\":\"$HOME/Documents\"}]"
    run cmd_apply
    [ "$status" -eq 0 ]
    [[ "$output" == *"documents"*"already"* ]]
    refute grep -q '^PUT /rest/config/folders/michael-macbook-documents ' "$CALLS"
}

@test "promote switches a fully synced folder to send-only and clears its marker" {
    mark_pending michael-macbook-dev
    folder_status michael-macbook-dev '{"needFiles":0,"globalFiles":5,"receiveOnlyChangedFiles":0,"state":"idle"}'
    run cmd_promote --yes
    [ "$status" -eq 0 ]
    grep -qF 'PATCH /rest/config/folders/michael-macbook-dev {"type":"sendonly"}' "$CALLS"
    [ "$(pending_count)" -eq 0 ]
}

@test "promote holds a folder with local changes and says how to fix it" {
    mark_pending michael-macbook-music
    folder_status michael-macbook-music '{"needFiles":0,"globalFiles":5,"receiveOnlyChangedFiles":3,"state":"idle"}'
    run cmd_promote --yes
    [ "$status" -eq 0 ]
    [[ "$output" == *"music"* && "$output" == *"Revert Local Changes"* ]]
    refute grep -q '^PATCH' "$CALLS"
    [ "$(pending_count)" -eq 1 ]
}

@test "promote holds folders that are still syncing or while Unraid is offline" {
    mark_pending michael-macbook-dev
    folder_status michael-macbook-dev '{"needFiles":12,"globalFiles":20,"receiveOnlyChangedFiles":0,"state":"syncing"}'
    run cmd_promote --yes
    refute grep -q '^PATCH' "$CALLS"
    [[ "$output" == *"dev"*"syncing"* ]]
    fixture GET /rest/system/connections "{\"connections\":{\"$UNRAID\":{\"connected\":false}}}"
    folder_status michael-macbook-dev '{"needFiles":0,"globalFiles":20,"receiveOnlyChangedFiles":0,"state":"idle"}'
    run cmd_promote --yes
    refute grep -q '^PATCH' "$CALLS"
    [[ "$output" == *"Unraid"* ]]
}

@test "promote --revert reverts local changes and doesn't promote in the same run" {
    mark_pending michael-macbook-music
    folder_status michael-macbook-music '{"needFiles":0,"globalFiles":5,"receiveOnlyChangedFiles":3,"state":"idle"}'
    run cmd_promote --revert --yes
    [ "$status" -eq 0 ]
    grep -q '^POST /rest/db/revert?folder=michael-macbook-music' "$CALLS"
    refute grep -q '^PATCH' "$CALLS"
}

@test "status shows each managed folder's mode and progress" {
    mark_pending michael-macbook-dev
    fixture GET /rest/config/folders '[{"id":"michael-macbook-dev","type":"receiveonly"},{"id":"michael-macbook-music","type":"sendonly"}]'
    folder_status michael-macbook-dev '{"globalBytes":200,"needBytes":50,"state":"syncing"}'
    folder_status michael-macbook-music '{"globalBytes":100,"needBytes":0,"state":"idle"}'
    run cmd_status
    [ "$status" -eq 0 ]
    [[ "$output" == *"dev"*"receive-only (pending)"*"75%"* ]]
    [[ "$output" == *"music"*"send-only"*"100%"* ]]
}

mark_pending() {
    mkdir -p "$HOME/.local/state/syncthing-setup"
    touch "$HOME/.local/state/syncthing-setup/$1.pending"
}
