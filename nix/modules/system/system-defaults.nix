{ username, homeDirectory, isWorkMachine ? false, ... }:
# Scope: System (nix-darwin). Configures macOS defaults and Dock.
# Behavior: Applies preferences (including the Dock layout) via system.defaults.
let
  appsDir = "/Applications";
  localAppsDir = "${homeDirectory}${appsDir}";
  systemAppsDir = "/System${appsDir}";
  cryptexAppsDir = "/System/Cryptexes/App/System/Applications";
  chromeAppsDir = "${localAppsDir}/Chrome Apps.localized";

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
    "${appsDir}/iTerm.app"
    "${appsDir}/Conductor.app"
    "${appsDir}/Visual Studio Code.app"
  ];

  workDockApps = [
    "${appsDir}/Google Chrome.app"
    "${chromeAppsDir}/Gmail.app"
    "${chromeAppsDir}/Google Meet.app"
    "${chromeAppsDir}/Calendar.app"
    "${appsDir}/Slack.app"
    "${appsDir}/iTerm.app"
    "${appsDir}/Conductor.app"
    "${appsDir}/Visual Studio Code.app"
    "${appsDir}/1Password.app"
    "${appsDir}/Self Service.app"
  ];

  activeDockApps = if isWorkMachine then workDockApps else dockApps;
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

    dock = {
      show-recents = false;
      tilesize = 64;
      largesize = 16;
      orientation = "left";
      autohide = false;
      persistent-apps = activeDockApps;
      persistent-others = [
        {
          folder = {
            path = "${homeDirectory}/Downloads";
            arrangement = "date-added";
            displayas = "stack";
            showas = "fan";
          };
        }
      ];
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

  system.activationScripts.extraActivation.text = ''
    # iTerm2: Set profile defaults
    ITERM_PLIST="${homeDirectory}/Library/Preferences/com.googlecode.iterm2.plist"
    if [ -f "$ITERM_PLIST" ]; then
      su ${username} -c "/usr/libexec/PlistBuddy -c \"Set ':New Bookmarks:0:Custom Directory' Recycle\" '$ITERM_PLIST'" 2>/dev/null || true
      su ${username} -c "/usr/libexec/PlistBuddy -c \"Set ':New Bookmarks:0:Normal Font' MesloLGSNFM-Regular\ 11\" '$ITERM_PLIST'" 2>/dev/null || true
      echo -e "\033[0;32m✓\033[0m iTerm2 profile updated: font and directory settings"
    fi

    # Terminal.app: Set font to MesloLGS Nerd Font 11pt
    # Terminal stores fonts as serialized NSFont objects, so we use osascript to generate the data
    TERMINAL_PLIST="${homeDirectory}/Library/Preferences/com.apple.Terminal.plist"
    if [ -f "$TERMINAL_PLIST" ]; then
      FONT_SCRIPT=$(mktemp)
      chmod 644 "$FONT_SCRIPT"
      cat > "$FONT_SCRIPT" << 'FONTSCRIPT'
    use framework "Foundation"
    use framework "AppKit"
    on run argv
      set plistPath to item 1 of argv
      set theFont to current application's NSFont's fontWithName:"MesloLGSNFM-Regular" |size|:11
      if theFont is missing value then
        set theFont to current application's NSFont's fontWithName:"MesloLGSNF-Regular" |size|:11
      end if
      if theFont is not missing value then
        set theData to current application's NSKeyedArchiver's archivedDataWithRootObject:theFont requiringSecureCoding:false |error|:(missing value)
        set thePlist to current application's NSMutableDictionary's dictionaryWithContentsOfFile:plistPath
        set windowSettings to (thePlist's objectForKey:"Window Settings")'s mutableCopy()
        set basicProfile to (windowSettings's objectForKey:"Basic")'s mutableCopy()
        basicProfile's setObject:theData forKey:"Font"
        windowSettings's setObject:basicProfile forKey:"Basic"
        thePlist's setObject:windowSettings forKey:"Window Settings"
        thePlist's writeToURL:(current application's NSURL's fileURLWithPath:plistPath) |error|:(missing value)
      end if
    end run
    FONTSCRIPT
      su ${username} -c "osascript '$FONT_SCRIPT' '$TERMINAL_PLIST'" >/dev/null 2>&1 || true
      rm -f "$FONT_SCRIPT"
      echo -e "\033[0;32m✓\033[0m Terminal.app profile updated: font set to MesloLGS Nerd Font 11pt"
    fi

    # Force reload of preference cache to apply natural scrolling setting
    echo -e "\033[0;34mℹ\033[0m Reloading trackpad preferences..."
    killall cfprefsd 2>/dev/null || true
  '';
}
