{ config, lib, pkgs, ... }:

{
  # 1Password CLI configuration
  home.file.".config/op/plugins.sh".text = ''
    export OP_PLUGIN_ALIASES_SOURCED=1
    alias gh="op plugin run -- gh"
  '';

  # Expose a canonical socket path location for reuse by other modules
  # Write to a file so other modules can read it if needed
  home.file.".config/op/agent-socket".text =
    "${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";

  # Provide a stable, no-spaces symlink for SSH IdentityAgent
  # This avoids quoting issues in ~/.ssh/config and works even if the target
  # path contains spaces.
  home.file.".ssh/1password-agent.sock".source =
    config.lib.file.mkOutOfStoreSymlink (
      "${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    );
}
