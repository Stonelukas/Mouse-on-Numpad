# Packaging Files

This directory contains distribution packaging files for Mouse on Numpad.

## Files

### PKGBUILD
Arch Linux AUR package build script.

**Usage:**
```bash
makepkg -si
```

### mouse-on-numpad.desktop
XDG desktop entry for application menu integration.

**Install Location:**
- System: `/usr/share/applications/`
- User: `~/.local/share/applications/`

### mouse-on-numpad.service
Systemd user service for daemon mode.

**Install Location:**
- System: `/usr/lib/systemd/user/`
- User: `~/.config/systemd/user/`

**Enable:**
```bash
systemctl --user enable mouse-on-numpad.service
systemctl --user start mouse-on-numpad.service
```

### com.github.mouse-on-numpad.policy
Polkit policy for input device access without root privileges.

**Install Location:**
- System: `/usr/share/polkit-1/actions/`
- User: `~/.local/share/polkit-1/actions/`

### install.sh
Manual installation script supporting both user and system-wide installation.

**Usage:**
```bash
# User installation (recommended)
./install.sh --user

# System-wide installation
sudo ./install.sh --system
```

## Installation Methods

See [docs/installation.md](../docs/installation.md) for complete installation guide.

### Quick Start (AUR)
```bash
yay -S mouse-on-numpad
```

### Quick Start (Manual)
```bash
./install.sh --user
```

## Distribution Support

**Current:**
- Arch Linux (AUR) - primary target

**Planned (Post-MVP):**
- Flatpak
- AppImage
- Debian/Ubuntu (.deb)
- Fedora (.rpm)
- PyPI

## Build Requirements

- Python 3.10+
- python-build
- python-installer
- python-hatchling

## Testing

Before submitting to AUR:
```bash
# Validate PKGBUILD
namcap PKGBUILD

# Test build
makepkg -f

# Test installation
makepkg -si

# Verify
mouse-on-numpad --version
systemctl --user status mouse-on-numpad.service
```

---

For detailed packaging documentation, see [docs/installation.md](../docs/installation.md).
