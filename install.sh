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

deploy_dotfiles() {
    if [ ! -d "$dotfiles_dir" ]; then
        echo "Dotfiles directory '$dotfiles_dir' does not exist. Clone your repo first!"
        exit 1
    fi

    # Allow overriding the target (useful for testing) and a dry-run mode
    target="${STOW_TARGET:-$config_target}"
    dry_run="${STOW_DRY_RUN:-0}"

    # Ensure stow is available
    if ! command -v stow >/dev/null 2>&1; then
        echo "Error: 'stow' is not installed. Install it (e.g., pacman -S stow or yay -S stow) and retry."
        exit 1
    fi

    # Make sure the target exists
    mkdir -p "$target"

    # Exclude obvious non-config top-level folders/files
    EXCLUDES=(".git" ".idea" "install.sh")

    echo "Deploying configs from $dotfiles_dir to $target using stow..."
    echo "Excluding: ${EXCLUDES[*]}"
    if [ "$dry_run" -ne 0 ]; then
        echo "Running in dry-run mode (no changes will be made). Set STOW_DRY_RUN=0 to apply changes."
    fi

    cd "$dotfiles_dir" || { echo "Failed to cd to $dotfiles_dir"; exit 1; }

    # Discover stow packages (top-level directories) but skip exclusions
    stow_pkgs=()
    for d in .*/ */ ; do
        # skip if the glob didn't match anything
        [ -e "$d" ] || continue
        name="${d%/}"
        
        # skip '.' and '..'
        if [ "$name" = "." ] || [ "$name" = ".." ]; then
            continue
        fi
        
        # skip if in EXCLUDES
        skip=0
        for ex in "${EXCLUDES[@]}"; do
            if [ "$name" = "$ex" ]; then
                skip=1
                break
            fi
        done
        if [ "$skip" -eq 1 ]; then
            echo "Skipping '$name'"
            continue
        fi
        # Only consider directories
        if [ -d "$name" ]; then
            stow_pkgs+=("$name")
        fi
    done

    if [ ${#stow_pkgs[@]} -eq 0 ]; then
        echo "No packages to stow. Nothing to do."
        return 0
    fi

    # Run stow for each package (dry-run if requested)
    for pkg in "${stow_pkgs[@]}"; do
        echo "Processing stow package: $pkg"
        if [ "$dry_run" -ne 0 ]; then
            stow -n -v -t "$target" "$pkg" || { echo "Dry-run stow failed for $pkg"; continue; }
        else
            stow -v -t "$target" "$pkg" || { echo "Stow failed for $pkg"; exit 1; }
        fi
    done

    echo "Dotfiles deployed successfully!"
}

case "$1" in
    need-packages)
        install_yay
        echo "Installing essential packages."
	sudo pacman -S --noconfirm "${pacman_packages[@]}"
	yay -S --noconfirm "${aur_packages[@]}"
	set_zsh_default
	deploy_dotfiles
        echo "=== Essential packages installed successfully! ==="
        echo "NOTE: The installer sets zsh as your default shell. You must log out and log back in (re-login) for this to take effect in new sessions."
        ;;
    *)
        show_usage
        ;;
esac
