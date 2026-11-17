{ lib, ... }:
# Scope: Home Manager (personal Mac). "Require password after screen saver
# begins or display is turned off" (System Settings → Lock Screen).
# Behavior: macOS keeps this grace period in the user's keybag, not in
# com.apple.screensaver (nix-darwin's askForPasswordDelay no longer works), and
# only sysadminctl with the login password can change it. Reading it needs no
# password, so this only prompts when the value is wrong, e.g. on a fresh Mac.
let
  delaySeconds = 4 * 60 * 60;
in
{
  home.activation.screenLockDelay = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    screen_lock_delay() {
      /usr/sbin/sysadminctl -screenLock status 2>&1 | sed -n 's/.*screenLock delay is \([0-9]*\) seconds.*/\1/p'
    }
    current=$(screen_lock_delay)
    if [ "$current" = "${toString delaySeconds}" ]; then
      echo -e "\033[0;32m✓\033[0m Screen lock delay is up to date"
    elif [ -n "''${DRY_RUN:-}" ]; then
      echo -e "\033[0;34mℹ\033[0m Would set the screen lock delay to ${toString delaySeconds}s"
    elif [ -r /dev/tty ] && [ -w /dev/tty ]; then
      echo -e "\033[0;34mℹ\033[0m Setting the password delay after sleep/screen saver to 4 hours (needs your login password)"
      /usr/sbin/sysadminctl -screenLock ${toString delaySeconds} -password - </dev/tty >/dev/tty 2>&1 || true
      if [ "$(screen_lock_delay)" = "${toString delaySeconds}" ]; then
        echo -e "\033[0;32m✓\033[0m Screen lock delay set to 4 hours"
      else
        echo -e "\033[1;33m!\033[0m Couldn't set the screen lock delay (wrong password?). Run: sysadminctl -screenLock ${toString delaySeconds} -password -"
      fi
    else
      echo -e "\033[1;33m!\033[0m Screen lock delay is ''${current:-unknown}, not 4 hours. Run: sysadminctl -screenLock ${toString delaySeconds} -password -"
    fi
  '';
}
