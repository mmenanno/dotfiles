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
