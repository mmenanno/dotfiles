{ username, homeDirectory, lib, ... }:
# Scope: System (nix-darwin). Configures macOS defaults and Dock.
# Behavior: Applies preferences via system.defaults and runs Dock setup during activation.
let
  appsDir = "/Applications";
  localAppsDir = "${homeDirectory}${appsDir}";
  systemAppsDir = "/System${appsDir}";
  systemUtilitiesDir = "${systemAppsDir}/Utilities";
  cryptexAppsDir = "/System/Cryptexes/App/System/Applications";

  # Define dock apps in order
  dockApps = [
    "${cryptexAppsDir}/Safari.app"
    "${localAppsDir}/Gmail.app"
    "${localAppsDir}/Google Calendar.app"
    "${appsDir}/Proton Mail.app"
    "${systemAppsDir}/Calendar.app"
    "${systemAppsDir}/Messages.app"
    "${systemAppsDir}/Music.app"
    "${appsDir}/Downie 4.app"
    "${appsDir}/Steam.app"
    "${systemAppsDir}/Photos.app"
    "${systemAppsDir}/TextEdit.app"
    "${appsDir}/Discord.app"
    "${appsDir}/Signal.app"
    "${systemAppsDir}/Notes.app"
    "${appsDir}/Transmit.app"
    "${appsDir}/1Password.app"
    "${systemAppsDir}/iPhone Mirroring.app"
    "${systemUtilitiesDir}/Terminal.app"
    "${appsDir}/Cursor.app"
    "${appsDir}/Session.app"
  ];

  # Optimized dock setup - batch operations for better performance
  dockPlistEntries = map (app: ''
    <dict>
      <key>tile-data</key>
      <dict>
        <key>file-data</key>
        <dict>
          <key>_CFURLString</key>
          <string>file://${app}/</string>
          <key>_CFURLStringType</key>
          <integer>15</integer>
        </dict>
      </dict>
      <key>tile-type</key>
      <string>file-tile</string>
    </dict>'') dockApps;

  # Create complete dock plist in one operation
  dockSetupCommand = ''
    # Clear existing dock apps
    defaults write com.apple.dock persistent-apps -array

    # Write all dock entries as a single plist
    defaults write com.apple.dock persistent-apps -array ${lib.concatStringsSep " " (map (entry: "'" + entry + "'") dockPlistEntries)}'';
in
{
  system.defaults = {
    finder = {
      FXDefaultSearchScope = "SCcf";
      FXPreferredViewStyle = "icnv";
      ShowStatusBar = true;
      AppleShowAllExtensions = true;
      FXEnableExtensionChangeWarning = false;
      _FXSortFoldersFirst = false;
    };

    menuExtraClock = {
      ShowAMPM = true;
      ShowDate = 1;
      ShowDayOfMonth = true;
      ShowDayOfWeek = true;
      FlashDateSeparators = true;
    };

    NSGlobalDomain = {
      "com.apple.swipescrolldirection" = false;
      AppleInterfaceStyle = "Dark";
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      NSAutomaticCapitalizationEnabled = true;
      NSAutomaticPeriodSubstitutionEnabled = true;
    };

    SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;

    WindowManager.EnableStandardClickToShowDesktop = false;

    controlcenter = {
      BatteryShowPercentage = true;
    };

    CustomUserPreferences = {
      "NSGlobalDomain" = {
        NSQuitAlwaysKeepsWindows = true; # "Close windows when quitting" = off
      };

      "com.apple.TextEdit" = {
        RichText = false;
        SmartQuotes = false;
      };

      "com.apple.ImageCapture" = {
        disableHotPlug = true;
      };

      "com.apple.dock" = {
        show-recents = false;
        tilesize = 64;
        largesize = 16;
        orientation = "left";
        autohide = false;
        persistent-apps = [];
      };

      "com.apple.trackpad" = {
        forceClick = true;
        scaling = "1.5";
      };

      "com.apple.sound.beep" = {
        flash = false;
      };

      "com.googlecode.iterm2" = {
        EnableAPIServer = true;
        DimInactiveSplitPanes = false;
      };

    };
  };

  # Create a dock setup script that runs as the user
  system.activationScripts.extraActivation.text = ''
    echo "Creating dock setup script"

    # Create the script with the actual paths expanded
    cat > /usr/local/bin/setup-dock << 'SCRIPT_END'
    #!/bin/bash
    echo "Setting up dock for user $(whoami)"

    # Optimized dock setup - batch operation
    ${dockSetupCommand}

    # Set Downloads folder
    defaults write com.apple.dock persistent-others -array '
    <dict>
      <key>tile-data</key>
      <dict>
        <key>arrangement</key>
        <integer>2</integer>
        <key>displayas</key>
        <integer>0</integer>
        <key>file-data</key>
        <dict>
          <key>_CFURLString</key>
          <string>file://${homeDirectory}/Downloads/</string>
          <key>_CFURLStringType</key>
          <integer>15</integer>
        </dict>
        <key>showas</key>
        <integer>1</integer>
      </dict>
      <key>tile-type</key>
      <string>directory-tile</string>
    </dict>
    '

    # Restart Dock to apply changes
    killall Dock 2>/dev/null || true
    echo "Dock setup complete with all ${username}'s apps!"
    SCRIPT_END

    # Make script executable
    chmod +x /usr/local/bin/setup-dock

    # Run the script as the user
    su ${username} -c "/usr/local/bin/setup-dock"

    echo "Dock setup script created and executed"
    echo "You can re-run it anytime with: setup-dock"

    # iTerm2: Set profile to reuse previous session's working directory
    ITERM_PLIST="${homeDirectory}/Library/Preferences/com.googlecode.iterm2.plist"
    if [ -f "$ITERM_PLIST" ]; then
      su ${username} -c "/usr/libexec/PlistBuddy -c \"Set ':New Bookmarks:0:Custom Directory' Recycle\" '$ITERM_PLIST'" 2>/dev/null || true
      echo "iTerm2 profile updated: reuse previous session directory"
    fi

    # Force reload of preference cache to apply natural scrolling setting
    echo "Reloading trackpad preferences..."
    killall cfprefsd 2>/dev/null || true
  '';
}
