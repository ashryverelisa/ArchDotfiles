#!/usr/bin/env bash
set -Eeuo pipefail

### ======================
### Configuration
### ======================

readonly DOTFILES_DIR="$HOME/ArchDotfiles"

pacman_packages=(
    # Environment
    hyprlock
    waybar
    rofi
    rofi-emoji
    zsh
    stow

    # System
    brightnessctl
    network-manager-applet
    bluez
    bluez-utils
    blueman
    pipewire
    wireplumber
    pavucontrol
)

aur_packages=(
    # Environment
    wlogout

    # Communication
    vesktop
)

### ======================
### Helpers
### ======================

usage() {
    cat <<EOF
Usage: $(basename "$0") <option>

Options:
  need-packages   Install essential packages and dotfiles
EOF
    exit 1
}

command_exists() {
    command -v "$1" &>/dev/null
}

### ======================
### Installers
### ======================

install_yay() {
    if command_exists yay; then
        echo "yay is already installed."
        return
    fi

    echo "Installing yay..."
    sudo pacman -S --needed --noconfirm base-devel git

    local temp_dir
    temp_dir=$(mktemp -d)

    git clone https://aur.archlinux.org/yay.git "$temp_dir/yay"
    pushd "$temp_dir/yay" >/dev/null
    makepkg -si --noconfirm
    popd >/dev/null

    rm -rf "$temp_dir"
    echo "yay installed successfully!"
}

set_zsh_default() {
    local zsh_path
    zsh_path="$(command -v zsh)"

    if [[ "${SHELL:-}" != "$zsh_path" ]]; then
        echo "Setting zsh as default shell..."
        chsh -s "$zsh_path"
        echo "Log out and back in for the change to take effect."
    else
        echo "zsh is already the default shell."
    fi
}

install_dotfiles() {
    echo "Stowing dotfiles..."

    if [[ ! -d "$DOTFILES_DIR/.config" ]]; then
        echo "No .config directory found in $DOTFILES_DIR"
        return
    fi

    mkdir -p "$HOME/.config"

    pushd "$DOTFILES_DIR" >/dev/null
    stow --adopt -v -t "$HOME/.config" .config
    popd >/dev/null

    echo "Dotfiles stowed successfully!"
}

### ======================
### Main
### ======================

[[ $# -eq 1 ]] || usage

case "$1" in
    need-packages)
        install_yay

        echo "Installing pacman packages..."
        sudo pacman -S --needed --noconfirm "${pacman_packages[@]}"

        echo "Installing AUR packages..."
        yay -S --needed --noconfirm "${aur_packages[@]}"

        set_zsh_default
        install_dotfiles

        echo "=== Setup complete ==="
        echo "Note: Re-login required if your shell was changed."
        ;;
    *)
        usage
        ;;
esac