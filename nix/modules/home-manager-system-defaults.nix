{ config, ... }:
let
  appsDir = "/Applications";
  localAppsDir = "${config.home.homeDirectory}${appsDir}";
  systemAppsDir = "/System${appsDir}";
  systemUtilitiesDir = "${systemAppsDir}/Utilities";
in
{
  targets.darwin.defaults = {
    com.apple.desktopservices = {
      DSDontWriteNetworkStores = true;
      DSDontWriteUSBStores = true;
    };

    NSGlobalDomain = {
      NSDocumentSaveNewDocumentsToCloud = false;
    };

    com.apple.finder = {
      FXRemoveOldTrashItems = true;
    };

    com.apple.controlcenter = {
      "NSStatusItem Visible Bluetooth" = true;
      "NSStatusItem Visible ScreenMirroring" = true;
      "NSStatusItem Visible Sound" = true;
      "NSStatusItem Visible WiFi" = true;
    };

    com.apple.Terminal = {
      Font = "MesloLGSNerdFontMono-Regular 12";
    };


  };
}
