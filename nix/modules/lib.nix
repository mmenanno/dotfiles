# Shared utility functions for dotfiles configuration
let
  # Helper function for environment variables with bootstrap and fallback values
  getEnvOrFallback = envVar: bootstrapVal: fallbackVal:
    let
      isBootstrap = builtins.getEnv "NIX_BOOTSTRAP_MODE" == "1";
    in
      if isBootstrap then bootstrapVal else
        let envValue = builtins.getEnv envVar;
        in if envValue != "" then envValue else fallbackVal;
in
{
  inherit getEnvOrFallback;

  # True during the bootstrap build, before 1Password (and so any secret or
  # SSH key) is available
  isBootstrap = builtins.getEnv "NIX_BOOTSTRAP_MODE" == "1";

  # Like getEnvOrFallback, but returns "" on work machines (personal-only secrets)
  getPersonalEnvOrFallback = isWorkMachine: envVar: bootstrapVal: fallbackVal:
    if isWorkMachine then "" else getEnvOrFallback envVar bootstrapVal fallbackVal;
}
