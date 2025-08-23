# Shared utility functions for dotfiles configuration
{
  # Helper function for environment variables with bootstrap and fallback values
  getEnvOrFallback = envVar: bootstrapVal: fallbackVal:
    let
      isBootstrap = builtins.getEnv "NIX_BOOTSTRAP_MODE" == "1";
    in
      if isBootstrap then bootstrapVal else
        let envValue = builtins.getEnv envVar;
        in if envValue != "" then envValue else fallbackVal;
}