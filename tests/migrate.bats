#!/usr/bin/env bats

load helpers

setup() {
    setup_home
    source_script migrate
}

@test "entry_field splits a path containing spaces" {
    entry="Library/Application Support/Paradox Interactive||"
    [ "$(entry_field "$entry" path)" = "Library/Application Support/Paradox Interactive" ]
    [ "$(entry_field "$entry" process)" = "" ]
    [ "$(entry_field "$entry" excludes)" = "" ]
}

@test "entry_field returns the process and excludes" {
    entry="Library/Application Support/com.conductor.app|Conductor|agent-binaries,bin,cache.db*"
    [ "$(entry_field "$entry" process)" = "Conductor" ]
    [ "$(entry_field "$entry" excludes)" = "agent-binaries,bin,cache.db*" ]
}

@test "nix_managed_excludes lists Nix symlinks and mutable baselines inside the path" {
    mkdir -p "$HOME/.claude/projects" "$BASELINE_DIR/.claude"
    ln -s /nix/store/x-claude-md "$HOME/.claude/CLAUDE.md"
    ln -s /tmp/not-nix "$HOME/.claude/other-link"
    touch "$BASELINE_DIR/.claude/settings.json" "$HOME/.claude/projects/a.jsonl"
    run nix_managed_excludes .claude
    [ "$status" -eq 0 ]
    [ "$output" = "$(printf 'CLAUDE.md\nsettings.json')" ]
}

@test "nix_managed_excludes prints nothing when the path doesn't exist yet" {
    run nix_managed_excludes "Library/RenPy"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "syncthing_folder_paths expands ~ to HOME" {
    cat > "$BATS_TEST_TMPDIR/config.xml" <<'XML'
<configuration version="37">
    <folder id="a" label="documents" path="~/Documents" type="sendonly"></folder>
    <folder id="b" label="dev" path="/Users/someone/dev" type="sendonly"></folder>
</configuration>
XML
    run syncthing_folder_paths "$BATS_TEST_TMPDIR/config.xml"
    [ "$status" -eq 0 ]
    [ "$output" = "$(printf '%s\n%s' "$HOME/Documents" "/Users/someone/dev")" ]
}

@test "inside_synced_folder matches paths inside a folder, not siblings with a shared prefix" {
    inside_synced_folder "Documents/x" "$HOME/Documents"
    inside_synced_folder "Documents" "$HOME/Documents"
    run inside_synced_folder "Library/RenPy" "$HOME/Documents"
    [ "$status" -eq 1 ]
    run inside_synced_folder "Documents-old/x" "$HOME/Documents"
    [ "$status" -eq 1 ]
}

@test "MIGRATE_ENTRIES covers every path in the spec" {
    paths="$(for e in "${MIGRATE_ENTRIES[@]}"; do entry_field "$e" path; done)"
    for p in \
        "Library/Application Support/Paradox Interactive" \
        "Library/Containers/com.pocketpair.palworld.mac" \
        "Library/RenPy" \
        "Library/Application Support/Transmit" \
        "Library/Application Support/com.charliemonroe.Downie-4" \
        "Library/Containers/com.charliemonroe.Downie-4" \
        "Library/Application Support/com.conductor.app" \
        "conductor" \
        ".claude" \
        ".claude.json" \
        ".zsh_history" \
        ".ssh/known_hosts" \
        ".local/share/cyberdrop-dl" \
        ".local/state/cyberdrop-dl" \
        ".config/openlogi" \
        ".local/share/openlogi" \
        ".local/state/openlogi" \
        ".config/scriptbin/cookies.txt"; do
        grep -qxF "$p" <<< "$paths" || { echo "missing: $p"; return 1; }
    done
}

# --- Task 2: checks, preview and copy -------------------------------------

# The "old Mac" is a directory: the ssh stub runs each remote command there.
# Paths containing $STUB_DENY fail like macOS privacy protection does
setup_remote() {
    export OLD_HOME="$BATS_TEST_TMPDIR/old"
    export CALLS="$BATS_TEST_TMPDIR/calls"
    export CONTROL_PATH="$BATS_TEST_TMPDIR/ctl"
    mkdir -p "$OLD_HOME"
    : > "$CALLS"
    ssh() {
        local args=("$@") cmd
        printf 'ssh %s\n' "${args[*]}" >> "$CALLS"
        if [[ " ${args[*]} " == *" -O exit "* ]]; then rm -f "$CONTROL_PATH"; return 0; fi
        if [[ -n "${STUB_SSH_ERR:-}" ]]; then echo "$STUB_SSH_ERR" >&2; return 255; fi
        touch "$CONTROL_PATH"
        cmd="${args[-1]}"
        if [[ -n "${STUB_DENY:-}" && "$cmd" == *"$STUB_DENY"* ]]; then
            echo "ls: $STUB_DENY: Operation not permitted" >&2
            return 1
        fi
        [[ -n "${STUB_NOISE:-}" ]] && echo "$STUB_NOISE"
        (cd "$OLD_HOME" && HOME="$OLD_HOME" bash -c "$cmd")
    }
    rsync() {
        printf 'rsync' >> "$CALLS"
        printf ' [%s]' "$@" >> "$CALLS"
        printf '\n' >> "$CALLS"
        # Fail only real copies, so a failure lands partway through the run
        [[ " $* " == *" --dry-run "* ]] && return 0
        return "${STUB_RSYNC_EXIT:-0}"
    }
    pgrep() { return 1; }
    caffeinate() { :; }
    export -f ssh rsync pgrep caffeinate
}

only_entry() {
    MIGRATE_ENTRIES=("$@")
}

@test "ssh_failure_reason classifies ssh errors" {
    [ "$(ssh_failure_reason 'ssh: Could not resolve hostname x: nodename nor servname provided')" = resolve ]
    [ "$(ssh_failure_reason 'ssh: connect to host x port 22: Connection refused')" = refused ]
    [ "$(ssh_failure_reason 'ssh: connect to host x port 22: Operation timed out')" = timeout ]
    [ "$(ssh_failure_reason 'x: Permission denied (publickey,password,keyboard-interactive).')" = auth ]
    [ "$(ssh_failure_reason 'something else')" = other ]
}

@test "remote_read_problem classifies read errors" {
    [ "$(remote_read_problem 'ls: x: No such file or directory')" = missing ]
    [ "$(remote_read_problem 'ls: x: Operation not permitted')" = denied ]
    [ "$(remote_read_problem 'ls: x: Permission denied')" = other ]
}

@test "nearest_existing_dir walks up to a directory that exists" {
    mkdir -p "$HOME/Library"
    [ "$(nearest_existing_dir "$HOME/Library/Containers/new.app/Data")" = "$HOME/Library" ]
}

@test "check_local_writable passes for a destination whose folders don't exist yet" {
    mkdir -p "$HOME/Library"
    run check_local_writable "Library/Containers/com.pocketpair.palworld.mac"
    [ "$status" -eq 0 ]
}

@test "a denied path stops the run with Full Disk Access instructions and no rsync" {
    setup_remote
    mkdir -p "$OLD_HOME/Library/Containers/com.pocketpair.palworld.mac" "$OLD_HOME/Library/RenPy"
    only_entry "Library/Containers/com.pocketpair.palworld.mac|Palworld|" "Library/RenPy||"
    STUB_DENY="com.pocketpair.palworld.mac"
    export STUB_DENY
    run main oldmac --dry-run
    [ "$status" -ne 0 ]
    [[ "$output" == *"Allow full disk access for remote users"* ]]
    refute grep -q '^rsync' "$CALLS"
}

@test "an unreachable host explains how to turn on Remote Login" {
    setup_remote
    STUB_SSH_ERR="ssh: connect to host oldmac port 22: Connection refused"
    export STUB_SSH_ERR
    run main oldmac --dry-run
    [ "$status" -ne 0 ]
    [[ "$output" == *"Remote Login"* ]]
}

@test "--dry-run only previews, and a path with spaces reaches rsync as one argument" {
    setup_remote
    mkdir -p "$OLD_HOME/Library/Application Support/Paradox Interactive"
    only_entry "Library/Application Support/Paradox Interactive||"
    run main oldmac --dry-run
    [ "$status" -eq 0 ]
    grep -q '^rsync' "$CALLS"
    refute grep -q '^rsync' <(grep -vF '[--dry-run]' "$CALLS")
    grep -qF '[oldmac:Library/Application Support/Paradox Interactive/]' "$CALLS"
    grep -qF "[$HOME/Library/Application Support/Paradox Interactive/]" "$CALLS"
}

@test "missing paths on the old Mac are skipped with a note" {
    setup_remote
    mkdir -p "$OLD_HOME/Library/RenPy"
    only_entry "Library/RenPy||" "Library/Application Support/Transmit|Transmit|Logs"
    run main oldmac --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"Library/Application Support/Transmit"*"not on"* ]]
    refute grep -qF 'Transmit/]' "$CALLS"
}

@test "Nix-managed files and entry excludes become anchored rsync excludes" {
    setup_remote
    mkdir -p "$OLD_HOME/.claude" "$HOME/.claude"
    ln -s /nix/store/x "$HOME/.claude/CLAUDE.md"
    only_entry ".claude||projects/tmp"
    run main oldmac --dry-run
    [ "$status" -eq 0 ]
    grep -qF '[--exclude=/CLAUDE.md]' "$CALLS"
    grep -qF '[--exclude=/projects/tmp]' "$CALLS"
}

@test "entries inside a Syncthing folder on the old Mac are dropped" {
    setup_remote
    mkdir -p "$OLD_HOME/Library/Application Support/Syncthing" "$OLD_HOME/Library/RenPy"
    cat > "$OLD_HOME/Library/Application Support/Syncthing/config.xml" <<XML
<configuration><folder id="r" path="~/Library/RenPy"></folder></configuration>
XML
    only_entry "Library/RenPy||"
    run main oldmac --dry-run
    [[ "$output" == *"Syncthing"* ]]
    refute grep -qF 'RenPy/]' "$CALLS"
}

@test "an open app on either Mac stops the run" {
    setup_remote
    mkdir -p "$OLD_HOME/Library/RenPy"
    only_entry "Library/RenPy|conductor|"
    pgrep() { [[ "$*" == *conductor* ]]; }
    export -f pgrep
    run main oldmac --dry-run
    [ "$status" -ne 0 ]
    [[ "$output" == *"conductor"* ]]
    refute grep -q '^rsync' "$CALLS"
}

@test "sqlite_orphans reports a local WAL whose database is being replaced" {
    setup_remote
    HOST=oldmac
    mkdir -p "$OLD_HOME/app" "$HOME/app"
    touch "$OLD_HOME/app/conductor.db" "$HOME/app/conductor.db" "$HOME/app/conductor.db-wal" "$HOME/app/other.db-shm"
    run sqlite_orphans app ""
    [ "$status" -eq 0 ]
    [ "$output" = "$HOME/app/conductor.db-wal" ]
}

@test "an rsync failure exits non-zero and closes the shared connection" {
    setup_remote
    mkdir -p "$OLD_HOME/Library/RenPy"
    only_entry "Library/RenPy||"
    STUB_RSYNC_EXIT=255
    export STUB_RSYNC_EXIT
    run main oldmac --yes
    [ "$status" -ne 0 ]
    [ ! -e "$CONTROL_PATH" ]
    grep -q -- '-O exit' "$CALLS"
}

# --- Task 3: Tailscale host picker ----------------------------------------

tailscale_fixture() {
    cat > "$BATS_TEST_TMPDIR/tailscale" <<'SH'
#!/usr/bin/env bash
cat <<'JSON'
{
  "Self": {"DNSName": "new-mac.tail.ts.net.", "OS": "macOS", "Online": true},
  "Peer": {
    "a": {"HostName": "Michael’s M1 MacBook Pro", "DNSName": "macbook-pro-michael.tail.ts.net.", "OS": "macOS", "Online": true},
    "b": {"HostName": "old", "DNSName": "old-imac.tail.ts.net.", "OS": "macOS", "Online": false},
    "c": {"HostName": "unraid", "DNSName": "unraid.tail.ts.net.", "OS": "linux", "Online": true}
  }
}
JSON
SH
    chmod +x "$BATS_TEST_TMPDIR/tailscale"
    export TAILSCALE_BIN="$BATS_TEST_TMPDIR/tailscale"
}

@test "tailscale_macs lists only online macOS peers, by their SSH-able name" {
    tailscale_fixture
    run tailscale_macs
    [ "$status" -eq 0 ]
    [ "$output" = "macbook-pro-michael" ]
}

@test "with no host and no Macs online, main says how to pass a host" {
    export TAILSCALE_BIN="$BATS_TEST_TMPDIR/missing-tailscale"
    run main --dry-run
    [ "$status" -ne 0 ]
    [[ "$output" == *"nx migrate <host>"* ]]
}

# --- Final review fixes ---------------------------------------------------

@test "the shared connection outlives a long confirm prompt, and rsync's ssh is bounded" {
    setup_remote
    mkdir -p "$OLD_HOME/Library/RenPy"
    only_entry "Library/RenPy||"
    run main oldmac --dry-run
    grep -q 'ControlPersist=yes' "$CALLS"
    grep -q '^rsync.*\[ssh [^]]*ServerAliveInterval=15[^]]*\]' "$CALLS"
}

@test "sqlite_orphans leaves alone a database the entry excludes" {
    setup_remote
    HOST=oldmac
    mkdir -p "$OLD_HOME/app" "$HOME/app"
    touch "$OLD_HOME/app/cache.db" "$HOME/app/cache.db" "$HOME/app/cache.db-wal"
    run sqlite_orphans app "agent-binaries,cache.db*"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "files vanishing during a copy (rsync 24) warn but don't stop later entries" {
    setup_remote
    mkdir -p "$OLD_HOME/.claude" "$OLD_HOME/Library/RenPy"
    only_entry ".claude||" "Library/RenPy||"
    STUB_RSYNC_EXIT=24
    export STUB_RSYNC_EXIT
    run main oldmac --yes
    [ "$status" -eq 0 ]
    [[ "$output" == *"changed while"* ]]
    [ "$(grep -v -- '--dry-run' "$CALLS" | grep -c '^rsync')" -eq 2 ]
}

@test "unexpected output from the old Mac's shell is reported, not guessed at" {
    setup_remote
    mkdir -p "$OLD_HOME/Library/RenPy"
    only_entry "Library/RenPy||"
    STUB_NOISE="Welcome to zsh"
    export STUB_NOISE
    run main oldmac --dry-run
    [ "$status" -ne 0 ]
    [[ "$output" == *"Library/RenPy"*"unexpected"* ]]
    refute grep -q '^rsync' "$CALLS"
}
