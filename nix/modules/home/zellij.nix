_:
# Scope: Home (Home Manager). Zellij's config. Deployed as a mutable file
# (see mutable-files.nix) because Zellij's settings screen rewrites it.
{
  home.file.".config/zellij/config.kdl".source = ../../files/zellij/config.kdl;
}
