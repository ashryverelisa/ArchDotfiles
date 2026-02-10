#!/bin/bash

pacman_packages=(
	# Enviroment
	hyprlock waybar rofi rofi-emoji zsh	stow
	
	# System
  brightnessctl network-manager-applet bluez bluez-utils blueman pipewire wireplumber pavucontrol
)

aur_packages=(
    # Environment
    wlogout
            
    # Communication
    vesktop
)

set -e

# Function to show usage
show_usage() {
    echo "Usage: $0 <option>"
    echo "Options:"
    echo "  need-packages  - Install essential packages"
    exit 1
}

# Check if an argument is provided
if [ $# -eq 0 ]; then
    show_usage
fi

# Determine dotfiles dir and a sensible default stow target
dotfiles_dir="$HOME/ArchDotfiles"
if [ -d "$dotfiles_dir/.config" ]; then
    # Repo contains a .config package; stow should target $HOME so that
    config_target="$HOME"
else
    # Repo doesn't use a top-level .config package, use ~/.config by default
    config_target="$HOME/.config"
fi

echo "=== Package Installation Script ==="

# Function to show/install yay (if needed)
install_yay() {
    if ! command -v yay &> /dev/null; then
        echo "Installing yay..."
        # Install base-devel and git if not present (required for building yay)
        sudo pacman -S --needed --noconfirm base-devel git

        # Clone and build yay
        temp_dir=$(mktemp -d)
        git clone https://aur.archlinux.org/yay.git "$temp_dir/yay"
        cd "$temp_dir/yay"
        makepkg -si --noconfirm
        cd -
        rm -rf "$temp_dir"

        echo "yay installed successfully!"
    else
        echo "yay is already installed."
    fi
}

# Function to set zsh as default shell
set_zsh_default() {
    if [ "$SHELL" != "$(which zsh)" ]; then
        echo "Setting zsh as default shell..."
        chsh -s "$(which zsh)"
        echo "zsh set as default shell. Please log out and back in for changes to take effect."
    else
        echo "zsh is already the default shell."
    fi
}

install_dotfiles() {
    echo "Stowing dotfiles..."

    cd "$dotfiles_dir"

    # Ensure ~/.config exists
    mkdir -p "$HOME/.config"

    # Stow the .config package into $HOME
    stow --adopt -t "$HOME/.config" -v .config

    echo "Dotfiles stowed successfully!"
}

case "$1" in
    need-packages)
        install_yay
        echo "Installing essential packages."
	sudo pacman -S --noconfirm "${pacman_packages[@]}"
	yay -S --noconfirm "${aur_packages[@]}"
	set_zsh_default
	install_dotfiles
        echo "=== Essential packages installed successfully! ==="
        echo "NOTE: The installer sets zsh as your default shell. You must log out and log back in (re-login) for this to take effect in new sessions."
        ;;
    *)
        show_usage
        ;;
esac
