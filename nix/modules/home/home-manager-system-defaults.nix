{ config, ... }:
let
  appsDir = "/Applications";
  localAppsDir = "${config.home.homeDirectory}${appsDir}";
  systemAppsDir = "/System${appsDir}";
  systemUtilitiesDir = "${systemAppsDir}/Utilities";
in
{
  targets.darwin.defaults = {
    NSGlobalDomain = {
      NSDocumentSaveNewDocumentsToCloud = false;
    };

    com.apple = {
      desktopservices = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };

      finder = {
        FXRemoveOldTrashItems = true;
      };

      controlcenter = {
        "NSStatusItem Visible Bluetooth" = true;
        "NSStatusItem Visible ScreenMirroring" = true;
        "NSStatusItem Visible Sound" = true;
        "NSStatusItem Visible WiFi" = true;
      };

      Terminal = {
        Font = "MesloLGSNerdFontMono-Regular 12";
      };
    };
  };
}
