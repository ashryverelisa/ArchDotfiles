# Dotfiles

> Personal configuration and installer for an Arch-based Linux desktop.
> Currently its CachyOS with Hyprland.

---

## About

This repository contains my personal dotfiles and helper scripts to quickly provision a Linux desktop (Arch or Arch-based distributions). The included installer automates package installation, deploys configuration files, and sets up the default shell.

- Primary target: Arch Linux and Arch-based distributions
- Shell: zsh (Powerlevel10k prompt can be deployed)

---

## Quick start

Clone the repo and run the installer. You must run the installer as a regular user with sudo privileges.

```bash
git clone https://github.com/YOUR_USERNAME/Dotfiles.git
cd Dotfiles
# Install the "need-packages" set (essential desktop packages)
./install.sh need-packages
```

## Installation options

Run `./install.sh` with one of the supported targets below.

- Essential packages (system utilities, Wayland, terminal, editor):

```bash
./install.sh need-packages
```

What the installer does (high level):
- Installs packages listed by the selected target (uses `yay` when available; otherwise falls back to `pacman`).
- stows dotfiles/configs to your home directory:
  - contents of `.config/` -> `~/.config/`
- Attempts to set `zsh` as the default shell for the current user.

---

## Repository layout

```
.
├── install.sh                # Top-level installer script (entrypoint)
├── .config/                  # Application configurations to be deployed
├── .p10k.zsh                 # Powerlevel10k prompt config
├── .zshrc                    # Zsh configuration
└── README.md
```

---

## Contributing

This repo is a personal config set. If you want to contribute tweaks or suggest improvements, open an issue or send a pull request. Keep changes small and document any new packages or configuration files added.

---

## License

MIT
