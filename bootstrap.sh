#!/usr/bin/env bash

# macOS Dotfiles Bootstrap Script
# Sets up a complete development environment using nix-darwin
#
# Runs before the repo is cloned (via curl), so it can't source bin/shared
# and must stay compatible with macOS's stock bash 3.2

set -euo pipefail  # Exit on error, undefined vars, pipe failures

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
NC=$'\033[0m'

NIX_DAEMON_PROFILE="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"

# Configuration
DOTFILES_REPO="https://github.com/mmenanno/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"


# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if running on macOS
check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        log_error "This script is designed for macOS only."
        exit 1
    fi
}

APP_MANAGEMENT_MARKER="$HOME/.local/state/dotfiles/app-management-granted"

terminal_app_name() {
    case "${TERM_PROGRAM:-}" in
        Apple_Terminal) echo "Terminal" ;;
        iTerm.app) echo "iTerm" ;;
        ghostty) echo "Ghostty" ;;
        WezTerm) echo "WezTerm" ;;
        vscode) echo "Visual Studio Code" ;;
        *) echo "your terminal app" ;;
    esac
}

# Start the Command Line Tools install if needed. Returns 0 if it was started
start_xcode_tools_install() {
    xcode-select -p >/dev/null 2>&1 && return 1
    log_warning "Xcode Command Line Tools not found. Starting the installer..."
    xcode-select --install
    log_info "Finish the Command Line Tools install in the popup."
    return 0
}

# Any app in /Applications the user owns (in practice, a Homebrew cask). App
# Store apps are root-owned, so a write there fails on plain file permissions
# and says nothing about App Management
find_probe_app() {
    local app
    for app in /Applications/*.app; do
        if [[ -d "$app" && ! -L "$app" && -w "$app/Contents" ]]; then
            echo "$app"
            return 0
        fi
    done
    return 1
}

# Try a write inside an app bundle. macOS answers "Operation not permitted"
# when the terminal lacks App Management, and shows a notification that leads
# to the toggle. Returns 0 if granted, 1 if denied, 2 if there's nothing to test
probe_app_management() {
    local app probe err
    app="$(find_probe_app)" || return 2
    probe="$app/Contents/.dotfiles-app-management-probe"
    if err="$(mkdir "$probe" 2>&1)"; then
        rmdir "$probe"
        return 0
    fi
    [[ "$err" == *"Operation not permitted"* ]] && return 1
    return 2
}

open_app_management_settings() {
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_AppBundles" || true
}

# Homebrew installs and updates apps in /Applications, which macOS blocks
# unless the terminal has App Management permission. Granting it mid-run only
# takes effect after the terminal restarts, so the casks being installed at
# the time fail. Returns 0 if the user still has to grant it and restart.
needs_app_management() {
    local app status=0
    app="$(terminal_app_name)"

    probe_app_management || status=$?
    case "$status" in
        0)
            log_success "$app has App Management permission."
            return 1
            ;;
        1)
            open_app_management_settings
            log_warning "macOS blocked $app from modifying an app: it needs App Management permission."
            log_info "Turn on $app in the System Settings window that just opened (or click the macOS notification)."
            return 0
            ;;
    esac

    # Nothing to test against (a fresh Mac has no user-owned apps yet), so ask
    [[ -f "$APP_MANAGEMENT_MARKER" || -e /run/current-system ]] && return 1

    if [[ ! -t 0 ]]; then
        log_warning "Can't ask about App Management without a terminal. If casks fail to install, give $app App Management permission, restart it and re-run."
        return 1
    fi

    log_info "Homebrew needs $app to have App Management permission to install apps."
    local reply=""
    read -r -p "Is $app already turned on in System Settings → Privacy & Security → App Management (and restarted since)? [y/N] " reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
        mkdir -p "$(dirname "$APP_MANAGEMENT_MARKER")"
        touch "$APP_MANAGEMENT_MARKER"
        return 1
    fi

    open_app_management_settings
    log_warning "Opened App Management in System Settings. Turn on $app there (use + to add it if it isn't listed)."
    return 0
}

# Batch the steps that need the user to act outside the script, so there's
# only one stop-and-re-run on a fresh machine
check_user_actions() {
    local rerun_needed=false
    start_xcode_tools_install && rerun_needed=true
    needs_app_management && rerun_needed=true

    if [[ "$rerun_needed" == true ]]; then
        echo
        log_info "When that's done, quit $(terminal_app_name) with ⌘Q, reopen it, and re-run this script."
        exit 0
    fi
}

# Function to batch check required commands
check_required_commands() {
    local missing_commands=()
    
    # Check all required commands in batch
    command_exists git || missing_commands+=("Git")
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log_error "Missing required commands: ${missing_commands[*]}"
        log_info "Install missing commands using: xcode-select --install"
        exit 1
    fi
    
    log_success "All required commands available."
}

needs_reboot_for_nix() {
    [[ ! -d /nix ]] && grep -qE '^nix([[:space:]]|$)' /etc/synthetic.conf 2>/dev/null
}

# Function to install Nix
install_nix() {
    # A re-run from the same terminal that installed Nix won't have it on PATH yet
    if ! command_exists nix && [[ -f "$NIX_DAEMON_PROFILE" ]]; then
        # shellcheck source=/dev/null
        source "$NIX_DAEMON_PROFILE"
    fi

    if command_exists nix; then
        log_success "Nix is already installed."
        return 0
    fi

    # The installer adds nix to /etc/synthetic.conf, then asks macOS to create
    # /nix right away. That fails when FileVault is on (as Setup Assistant
    # leaves a new Mac); a reboot creates it from synthetic.conf instead
    if needs_reboot_for_nix; then
        log_warning "/etc/synthetic.conf has a /nix entry but /nix doesn't exist yet."
        log_info "Reboot, then re-run this script to finish installing Nix."
        exit 1
    fi

    log_info "Installing Nix package manager..."

    if ! curl -fsSL https://nixos.org/nix/install | sh -s -- --daemon; then
        if needs_reboot_for_nix; then
            log_warning "macOS couldn't create /nix until it reboots (a known issue with FileVault)."
            log_info "Reboot, then re-run this script to finish installing Nix."
        else
            log_error "Failed to install Nix."
        fi
        exit 1
    fi

    # Source the Nix environment
    if [[ -f "$NIX_DAEMON_PROFILE" ]]; then
        # shellcheck source=/dev/null
        source "$NIX_DAEMON_PROFILE"
    else
        log_error "Nix installation completed but environment setup failed."
        log_info "Please restart your terminal and re-run this script."
        exit 1
    fi

    log_success "Nix installed successfully."
}

# Function to clone or update dotfiles
setup_dotfiles() {
    local clone_url="$DOTFILES_REPO"
    
    if [[ -d "$DOTFILES_DIR" ]]; then
        log_info "Dotfiles directory exists. Checking for updates..."
        cd "$DOTFILES_DIR"
        
        # Check if repository needs updating
        git fetch origin main >/dev/null 2>&1
        local local_commit
        local remote_commit
        local_commit=$(git rev-parse HEAD)
        remote_commit=$(git rev-parse origin/main 2>/dev/null || echo "")
        
        if [[ -n "$remote_commit" && "$local_commit" != "$remote_commit" ]]; then
            log_info "Updates available. Pulling changes..."
            if ! git pull origin main; then
                log_warning "Failed to update dotfiles. Continuing with existing version..."
            fi
        else
            log_success "Dotfiles already up to date."
        fi
    else
        log_info "Cloning dotfiles repository..."
        if ! git clone "$clone_url" "$DOTFILES_DIR"; then
            log_error "Failed to clone dotfiles repository."
            exit 1
        fi
    fi
    log_success "Dotfiles ready."
}

# Function to enable Nix flakes
enable_flakes() {
    local nix_config_dir="$HOME/.config/nix"
    local nix_config_file="$nix_config_dir/nix.conf"
    
    # Check if flakes are already enabled by checking config file (faster than nix show-config)
    if [[ -f "$nix_config_file" ]] && grep -q "experimental-features.*flakes" "$nix_config_file"; then
        log_success "Nix flakes already enabled."
        return 0
    fi

    log_info "Enabling Nix flakes..."
    mkdir -p "$nix_config_dir"
    
    # Add flakes configuration
    if [[ ! -f "$nix_config_file" ]] || ! grep -q "experimental-features.*flakes" "$nix_config_file"; then
        echo "experimental-features = nix-command flakes" >> "$nix_config_file"
    fi
    
    log_success "Nix flakes enabled."
}

# Function to build and activate configuration
build_configuration() {
    cd "$DOTFILES_DIR"
    
    log_info "Building and activating nix-darwin configuration with secrets..."
    log_warning "This may take 15-20 minutes on first run (downloading applications)..."
    
    if ! "$DOTFILES_DIR/bin/nixup-with-secrets"; then
        log_error "Failed to build nix-darwin configuration."
        log_info "You can try running manually: cd $DOTFILES_DIR && ./bin/nixup-with-secrets"
        exit 1
    fi
    
    log_success "Configuration activated successfully!"
}

# Function to display post-installation instructions
show_completion_message() {
    echo
    log_success "🎉 macOS setup completed successfully!"
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. 🔄 Open a new terminal to load the new shell configuration"
    echo "2. 🔑 Sign into 1Password and enable its CLI integration"
    echo "   (1Password → Settings → Developer → Integrate with 1Password CLI)"
    echo "3. ⚡ Run 'nx up' to apply the full configuration with your secrets"
    echo
    echo -e "${BLUE}Useful commands:${NC}"
    echo "• nx up     - Rebuild and switch configuration"
    echo "• nx edit   - Open dotfiles in VS Code"
    echo "• mise list - Show installed development tools"
    echo
    echo -e "${GREEN}Configuration details: $DOTFILES_DIR/README.md${NC}"
}

# Function to handle cleanup on error
cleanup_on_error() {
    log_error "Script failed. Check the error messages above."
    log_info "You can run the script again to resume from where it failed."
    exit 1
}

# Main installation flow
main() {
    # Set up error handling and display header in one block
    trap cleanup_on_error ERR

    # Keep the Mac awake (not the display) until this script exits; the first
    # build downloads for a long time
    caffeinate -ims -w $$ &
    
    cat << EOF
${BLUE}🍎 macOS Dotfiles Bootstrap${NC}
${BLUE}================================${NC}

EOF

    # Batch all pre-flight and environment checks
    local checks=(
        "check_macos:macOS compatibility"
        "check_user_actions:setup steps that need you"
        "check_required_commands:required commands"
    )
    
    for check in "${checks[@]}"; do
        IFS=':' read -r func desc <<< "$check"
        log_info "Checking $desc..."
        $func
    done
    
    # Installation pipeline
    install_nix
    setup_dotfiles
    enable_flakes
    build_configuration
    show_completion_message
}

# Run main function
main "$@"