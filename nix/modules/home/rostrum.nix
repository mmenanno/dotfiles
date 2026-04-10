{ config, ... }:
{
  # Symlink rostrum CLI from local dev checkout
  home.file.".local/bin/rostrum".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dev/rostrum/bin/rostrum";
}
