#!/bin/bash

# macOS Dotfiles Bootstrap Script
# Sets up a complete development environment using nix-darwin

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Function to check if Xcode Command Line Tools are installed
check_xcode_tools() {
    if ! xcode-select -p >/dev/null 2>&1; then
        log_warning "Xcode Command Line Tools not found. Installing..."
        xcode-select --install
        log_info "Please complete the Xcode Command Line Tools installation and re-run this script."
        exit 1
    fi
}

# Function to install Nix
install_nix() {
    if command_exists nix; then
        log_success "Nix is already installed."
        return 0
    fi

    log_info "Installing Nix package manager..."
    
    # Download and verify the Nix installer
    if ! curl -L https://nixos.org/nix/install | sh -s -- --daemon; then
        log_error "Failed to install Nix."
        exit 1
    fi

    # Source the Nix environment
    if [[ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]]; then
        # shellcheck source=/dev/null
        source "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
    else
        log_error "Nix installation completed but environment setup failed."
        log_info "Please restart your terminal and re-run this script."
        exit 1
    fi

    log_success "Nix installed successfully."
}

# Function to verify Git installation
check_git() {
    if ! command_exists git; then
        log_error "Git is required but not installed."
        log_info "Please install Git using: xcode-select --install"
        exit 1
    fi
    log_success "Git is available."
}

# Function to clone or update dotfiles
setup_dotfiles() {
    local clone_url="$DOTFILES_REPO"
    
    if [[ -d "$DOTFILES_DIR" ]]; then
        log_info "Dotfiles directory exists. Updating..."
        cd "$DOTFILES_DIR"
        
        
        if ! git pull origin main; then
            log_warning "Failed to update dotfiles. Continuing with existing version..."
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
    
    # Check if flakes are already enabled
    if nix show-config 2>/dev/null | grep -q "experimental-features.*flakes"; then
        log_success "Nix flakes already enabled."
        return 0
    fi

    log_info "Enabling Nix flakes..."
    mkdir -p "$nix_config_dir"
    
    # Add flakes configuration if not present
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
    echo "1. 🔄 Restart your terminal to load the new shell configuration"
    echo "2. 🔑 Sign into applications that require authentication"
    echo "3. 🛠  Configure 1Password for SSH/Git signing"
    echo "4. ⚡ Run 'nixup' to rebuild configuration anytime"
    echo
    echo -e "${BLUE}Useful commands:${NC}"
    echo "• nixup     - Rebuild and switch configuration"
    echo "• nixedit   - Open dotfiles in Cursor"
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
    # Set up error handling
    trap cleanup_on_error ERR

    echo -e "${BLUE}🍎 macOS Dotfiles Bootstrap${NC}"
    echo -e "${BLUE}================================${NC}"
    echo

    # Pre-flight checks
    check_macos
    check_xcode_tools
    
    # Installation steps
    install_nix
    check_git
    setup_dotfiles
    enable_flakes
    build_configuration
    
    # Completion
    show_completion_message
}

# Run main function
main "$@"