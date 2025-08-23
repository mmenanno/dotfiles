{ config, lib, pkgs, ... }:

{
  # Rectangle window manager configuration
  system.defaults.CustomUserPreferences."com.knollsoft.Rectangle" = {
    # Enable automatic update checks
    SUEnableAutomaticChecks = true;

    # Launch on login
    launchOnLogin = true;

    # Hide menu bar icon
    hideMenubarIcon = true;

    # Use alternate default shortcuts
    alternateDefaultShortcuts = false;

    # Subsequent execution mode (0 = Resize, 1 = Move to next display)
    subsequentExecutionMode = 0;

    # Custom keyboard shortcuts
    # Todo reflow shortcut (Cmd+N)
    reflowTodo = {
      keyCode = 45;
      modifierFlags = 786432; # Cmd key
    };

    # Toggle todo shortcut (Cmd+B)
    toggleTodo = {
      keyCode = 11;
      modifierFlags = 786432; # Cmd key
    };

    # Mark that internal tiling has been notified about
    internalTilingNotified = true;
  };
}
