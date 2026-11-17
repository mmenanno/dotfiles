_:
{
  targets.darwin.defaults = {
    NSGlobalDomain = {
      NSDocumentSaveNewDocumentsToCloud = false;
    };

    # Domains must be quoted: an unquoted com.apple.finder is a nested attrset
    # and lands in a bogus "com" domain
    "com.apple.desktopservices" = {
      DSDontWriteNetworkStores = true;
      DSDontWriteUSBStores = true;
    };

    "com.apple.finder" = {
      FXRemoveOldTrashItems = true;
      WarnOnEmptyTrash = false;
      ShowRecentTags = false; # Tags section in the sidebar
      FXPreferredGroupBy = "Kind"; # default "Group By" for folders without their own
    };

    # Menu bar items, under the keys Control Center itself writes
    "com.apple.controlcenter" = {
      "NSStatusItem VisibleCC Bluetooth" = true;
      "NSStatusItem VisibleCC ScreenMirroring" = true;
      "NSStatusItem VisibleCC Sound" = true;
      "NSStatusItem VisibleCC WiFi" = true;
    };
  };
}
