{ config, lib, homeDirectory, ... }:

let
  mutablePaths = [
    ".claude/settings.json"
    "Library/Application Support/Code/User/settings.json"
    "Library/Application Support/Code/User/mcp.json"
  ];

  mutableFiles = map (path: {
    inherit path;
    storePath = config.home.file.${path}.source;
  }) mutablePaths;

  deployCommands = lib.concatMapStringsSep "\n" (file:
    "deploy_mutable_file ${lib.escapeShellArg file.path} ${lib.escapeShellArg (toString file.storePath)}"
  ) mutableFiles;
in
{
  # Disable Home Manager symlink creation for these paths — we deploy writable copies instead
  home.file = lib.mkMerge (map (path:
    { ${path}.enable = lib.mkForce false; }
  ) mutablePaths);

  # Deploy writable copies with conflict detection
  home.activation.deployMutableFiles = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    deploy_mutable_file() {
      local rel_path="$1"
      local store_path="$2"
      local target="${homeDirectory}/$rel_path"
      local baseline_dir="${homeDirectory}/.local/share/nix-managed-baselines"
      local baseline="$baseline_dir/$rel_path"

      mkdir -p "$(dirname "$target")"
      mkdir -p "$(dirname "$baseline")"

      # Case 1: Target is a symlink (first-run conversion from HM)
      if [ -L "$target" ]; then
        rm "$target"
        install -m 644 "$store_path" "$target"
        install -m 644 "$store_path" "$baseline"
        echo "mutable-files: converted symlink to writable copy: $rel_path"
        return
      fi

      # Case 2: Target doesn't exist
      if [ ! -f "$target" ]; then
        install -m 644 "$store_path" "$target"
        install -m 644 "$store_path" "$baseline"
        echo "mutable-files: created writable copy: $rel_path"
        return
      fi

      # Case 3: Target content matches Nix content — no conflict, update baseline
      if cmp -s "$target" "$store_path"; then
        install -m 644 "$store_path" "$baseline"
        return
      fi

      # Case 4: Target matches baseline — app didn't change, safe to overwrite
      if [ -f "$baseline" ] && cmp -s "$target" "$baseline"; then
        install -m 644 "$store_path" "$target"
        install -m 644 "$store_path" "$baseline"
        echo "mutable-files: updated writable copy: $rel_path"
        return
      fi

      # Case 5: No baseline exists — first run with existing file
      if [ ! -f "$baseline" ]; then
        install -m 644 "$store_path" "$baseline"
        echo "mutable-files WARNING: existing file differs from Nix config: $rel_path"
        echo "  Keeping existing file. Run 'nx managed diff' to compare."
        return
      fi

      # Case 6: Conflict — both app and Nix changed
      echo "mutable-files WARNING: conflict detected in $rel_path"
      echo "  Both the application and Nix config have changed."
      echo "  Keeping application's version."
      echo "  Run 'nx managed diff' to see differences."
      echo "  Run 'nx managed accept $rel_path' to accept the Nix version."
    }

    ${deployCommands}
  '';
}
