{ lib, pkgs, homeDirectory, ... }:

# macOS has no built-in UTI for .torrent, so Finder synthesises a `dyn.*` type and
# falls back to the generic document icon. This module ships an app bundle that
# declares the type and supplies an icon, with CFBundleTypeRole = None so Launch
# Services never offers it as a way to open the file.

let
  appName = "Torrent File Icon";
  executableName = "torrent-file-icon";
  utiIdentifier = "org.bittorrent.torrent";
  iconFile = "torrent.icns";

  # png2icns takes the largest supported dimension it is given for each icns
  # element, so render every size the format has a slot for.
  iconSizes = [ 16 32 48 128 256 512 1024 ];

  torrentIcns = pkgs.runCommand iconFile {
    nativeBuildInputs = [ pkgs.resvg pkgs.libicns ];
  } ''
    for size in ${lib.concatMapStringsSep " " toString iconSizes}; do
      resvg --width "$size" --height "$size" ${../../files/icons/torrent.svg} "icon_$size.png"
    done
    png2icns "$out" ${lib.concatMapStringsSep " " (size: "icon_${toString size}.png") (lib.reverseList iconSizes)}
  '';

  infoPlist = pkgs.writeText "Info.plist" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>CFBundleDevelopmentRegion</key>
      <string>en</string>
      <key>CFBundleExecutable</key>
      <string>${executableName}</string>
      <key>CFBundleIdentifier</key>
      <string>com.menanno.${executableName}</string>
      <key>CFBundleInfoDictionaryVersion</key>
      <string>6.0</string>
      <key>CFBundleName</key>
      <string>${appName}</string>
      <key>CFBundlePackageType</key>
      <string>APPL</string>
      <key>CFBundleShortVersionString</key>
      <string>1.0</string>
      <key>CFBundleVersion</key>
      <string>1</string>
      <key>LSMinimumSystemVersion</key>
      <string>11.0</string>
      <key>LSUIElement</key>
      <true/>
      <key>UTImportedTypeDeclarations</key>
      <array>
        <dict>
          <key>UTTypeIdentifier</key>
          <string>${utiIdentifier}</string>
          <key>UTTypeDescription</key>
          <string>BitTorrent File</string>
          <key>UTTypeConformsTo</key>
          <array>
            <string>public.data</string>
          </array>
          <key>UTTypeIconFile</key>
          <string>${iconFile}</string>
          <key>UTTypeTagSpecification</key>
          <dict>
            <key>public.filename-extension</key>
            <array>
              <string>torrent</string>
            </array>
            <key>public.mime-type</key>
            <array>
              <string>application/x-bittorrent</string>
            </array>
          </dict>
        </dict>
      </array>
      <key>CFBundleDocumentTypes</key>
      <array>
        <dict>
          <key>CFBundleTypeName</key>
          <string>BitTorrent File</string>
          <key>CFBundleTypeRole</key>
          <string>None</string>
          <key>CFBundleTypeIconFile</key>
          <string>${iconFile}</string>
          <key>LSItemContentTypes</key>
          <array>
            <string>${utiIdentifier}</string>
          </array>
        </dict>
      </array>
    </dict>
    </plist>
  '';

  torrentIconApp = pkgs.runCommand "torrent-file-icon-app" { } ''
    contents="$out/${appName}.app/Contents"
    mkdir -p "$contents/MacOS" "$contents/Resources"

    cp ${infoPlist} "$contents/Info.plist"
    cp ${torrentIcns} "$contents/Resources/${iconFile}"
    printf 'APPL????' > "$contents/PkgInfo"

    # Launch Services expects a bundle to have an executable even when it will
    # never be asked to run one.
    printf '#!/bin/sh\nexit 0\n' > "$contents/MacOS/${executableName}"
    chmod +x "$contents/MacOS/${executableName}"
  '';

  targetApp = "${homeDirectory}/Applications/${appName}.app";
  stampFile = "${homeDirectory}/.local/share/nix-torrent-file-icon/store-path";
  lsregister = "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister";
in
{
  # Deployed as a copy rather than a symlink: Launch Services records the
  # resolved path, and a store path would go stale on the next rebuild and
  # eventually be garbage collected out from under the registration.
  home.activation.installTorrentFileIcon = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    source_app=${lib.escapeShellArg "${torrentIconApp}/${appName}.app"}
    target_app=${lib.escapeShellArg targetApp}
    stamp_file=${lib.escapeShellArg stampFile}

    if [ -d "$target_app" ] && [ "$(cat "$stamp_file" 2>/dev/null)" = "$source_app" ]; then
      echo -e "\033[0;32m✓\033[0m Torrent file icon is up to date"
    else
      # A pre-existing stamp means the artwork changed rather than this being a
      # first install, which is the case that hits the icon cache below.
      if [ -f "$stamp_file" ]; then is_update=1; else is_update=0; fi

      echo -e "\033[0;34mℹ\033[0m Installing torrent file icon..."
      $DRY_RUN_CMD mkdir -p "$(dirname "$target_app")" "$(dirname "$stamp_file")"
      $DRY_RUN_CMD rm -rf "$target_app"
      $DRY_RUN_CMD cp -R "$source_app" "$target_app"
      $DRY_RUN_CMD chmod -R u+w "$target_app"

      # Ad-hoc signature keeps Gatekeeper from quarantining the bundle; not fatal
      # if it fails, since the bundle is never launched.
      if ! $DRY_RUN_CMD /usr/bin/codesign --force --sign - "$target_app" 2>/dev/null; then
        echo -e "\033[1;33m!\033[0m Could not ad-hoc sign the torrent file icon bundle"
      fi

      if $DRY_RUN_CMD ${lsregister} -f "$target_app"; then
        $DRY_RUN_CMD sh -c "printf '%s' \"$source_app\" > \"$stamp_file\""
        $DRY_RUN_CMD killall Finder 2>/dev/null || true
        echo -e "\033[0;32m✓\033[0m Torrent file icon registered"

        # macOS caches the icon against the UTI in a root-owned store, and that
        # entry outlives re-registration, a bundle version bump and a new bundle
        # identifier alike. Only a first install renders immediately; replacing
        # the artwork needs the cache cleared, which Home Manager cannot do
        # unprivileged. Print the command rather than leaving a stale icon
        # looking like a failed build.
        if [ "$is_update" = "1" ]; then
          echo -e "\033[1;33m!\033[0m Artwork changed. macOS will keep serving the cached icon until you run:"
          echo "    sudo rm -rf /Library/Caches/com.apple.iconservices.store && killall Dock Finder"
        fi
      else
        echo -e "\033[0;31m✗\033[0m Failed to register torrent file icon with Launch Services"
      fi
    fi
  '';
}
