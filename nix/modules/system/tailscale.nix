_:

{
  # Tailscale configuration
  system.defaults.CustomUserPreferences."io.tailscale.ipn.macsys" = {
    # Start Tailscale on login
    TailscaleStartOnLogin = true;
    
    # Enable automatic updates
    SUAutomaticallyUpdate = true;
    
    # Disable unstable updates
    UnstableUpdatesEnabled = false;
    
    # VPN on demand is user configured
    VPNOnDemandIsUserConfigured = true;
    DidSetVPNOnDemandIsUserConfigured = true;
    
    # Onboarding flow preference
    OnboardingFlow = "hide";
    
    # Don't restart after Sparkle updates
    restartAfterSparkleUpdate = false;
    
    # Set restart state
    "com.tailscale.ipn.restartState" = "restartVPNIfNeeded";
  };
}