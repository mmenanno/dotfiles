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
        # The Nix dynamic profile (nix/modules/home/iterm.nix)
        "Default Bookmark Guid" = "nix-managed-profile";
      };

    };
  };

  # Terminal.app: MesloLGS Nerd Font 11pt on the default profile (whichever it
  # is: Basic on older macOS, Clear Dark on newer). Runs after the fonts step,
  # so the font exists on a fresh Mac
  system.activationScripts.postActivation.text = ''
    terminal_profiles=$(su ${username} -c "osascript -l JavaScript '${../../files/terminal-font.js}' com.apple.Terminal MesloLGSNFM-Regular 11" 2>/dev/null || echo "error")
    case "$terminal_profiles" in
      no-profiles) echo -e "\033[0;34mℹ\033[0m Terminal.app has no saved profiles yet; open it once and run nx up again to set its font" ;;
      no-font|error) echo -e "\033[1;33m!\033[0m Couldn't set Terminal.app's font ($terminal_profiles)" ;;
      *) echo -e "\033[0;32m✓\033[0m Terminal.app font set to MesloLGS Nerd Font 11pt ($terminal_profiles)" ;;
    esac
  '';

  system.activationScripts.extraActivation.text = ''
    # Force reload of preference cache to apply natural scrolling setting
    echo -e "\033[0;34mℹ\033[0m Reloading trackpad preferences..."
    killall cfprefsd 2>/dev/null || true
  '';
}
