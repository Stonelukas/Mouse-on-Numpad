# Installation Guide

**Mouse on Numpad Enhanced - Linux Installation**

This guide covers installation methods for Mouse on Numpad on Linux systems.

---

## Prerequisites

**System Requirements:**
- Python 3.10 or higher
- GTK4 libraries
- X11 or Wayland display server
- PulseAudio or PipeWire audio system

**For Arch Linux (recommended):**
All dependencies are handled automatically via AUR.

**For other distributions:**
Install dependencies manually (see Manual Installation section).

---

## Installation Methods

### Method 1: AUR (Arch Linux - Recommended)

**Using an AUR helper (yay, paru, etc.):**

```bash
# Using yay
yay -S mouse-on-numpad

# Using paru
paru -S mouse-on-numpad
```

**Manual AUR installation:**

```bash
# Clone AUR repository
git clone https://aur.archlinux.org/mouse-on-numpad.git
cd mouse-on-numpad

# Build and install
makepkg -si
```

**What gets installed:**
- `/usr/bin/mouse-on-numpad` - Main executable
- `/usr/share/applications/mouse-on-numpad.desktop` - Desktop entry
- `/usr/lib/systemd/user/mouse-on-numpad.service` - Systemd service
- `/usr/share/polkit-1/actions/` - Polkit policy for input access

---

### Method 2: Manual Installation

**Install system dependencies:**

**Arch Linux:**
```bash
sudo pacman -S python python-pynput python-gobject gtk4 python-pulsectl python-xlib python-evdev
```

**Ubuntu/Debian:**
```bash
sudo apt install python3 python3-pip python3-gi gir1.2-gtk-4.0 libcairo2-dev libgirepository1.0-dev
pip3 install pynput pulsectl python-xlib evdev
```

**Fedora:**
```bash
sudo dnf install python3 python3-pip python3-gobject gtk4 cairo-devel gobject-introspection-devel
pip3 install pynput pulsectl python-xlib evdev
```

**Clone and install:**

```bash
# Clone repository
git clone https://github.com/Stonelukas/mouse-on-numpad.git
cd mouse-on-numpad

# User installation (recommended)
./packaging/install.sh --user

# OR system-wide installation
sudo ./packaging/install.sh --system
```

**Verify installation:**

```bash
# Check command is available
which mouse-on-numpad

# Test launch
mouse-on-numpad --help
```

---

### Method 3: Python Package (pip)

**Install from source:**

```bash
git clone https://github.com/Stonelukas/mouse-on-numpad.git
cd mouse-on-numpad
pip install --user .
```

**Note:** This only installs the Python package. You need to manually copy:
- Desktop entry from `packaging/mouse-on-numpad.desktop`
- Systemd service from `packaging/mouse-on-numpad.service`
- Polkit policy from `packaging/com.github.mouse-on-numpad.policy`

---

## Post-Installation Setup

### Enable Systemd Service (Autostart)

**Start service now:**
```bash
systemctl --user start mouse-on-numpad.service
```

**Enable autostart on login:**
```bash
systemctl --user enable mouse-on-numpad.service
```

**Check service status:**
```bash
systemctl --user status mouse-on-numpad.service
```

**View service logs:**
```bash
journalctl --user -u mouse-on-numpad.service -f
```

### Desktop Entry

The desktop entry should appear automatically in your application menu under:
- **Category:** Utilities → Accessibility
- **Name:** Mouse on Numpad

If it doesn't appear:
```bash
# Update desktop database
update-desktop-database ~/.local/share/applications
```

### Input Device Permissions

**For Wayland (evdev access):**

Add user to `input` group:
```bash
sudo usermod -a -G input $USER
```

**Log out and back in** for group changes to take effect.

**For X11 (using pynput):**

No additional permissions required (uses X11 protocol).

### Polkit Policy (Optional)

For systems requiring polkit authentication:

```bash
# Install policy (if not done by package)
sudo cp packaging/com.github.mouse-on-numpad.policy \
    /usr/share/polkit-1/actions/
```

---

## Configuration

**Default config location:**
- `~/.config/mouse-on-numpad/config.json`

**Edit configuration:**
```bash
# Via GUI (recommended)
mouse-on-numpad --settings

# Via text editor
nano ~/.config/mouse-on-numpad/config.json
```

**Configuration options:**
- Movement speed (base, acceleration, max)
- Audio feedback (enabled, volume)
- Toggle key (default: Num Lock)
- Status bar position (top, bottom)

---

## Usage

### Command Line

**Start daemon:**
```bash
mouse-on-numpad --daemon
```

**Open settings GUI:**
```bash
mouse-on-numpad --settings
```

**Show help:**
```bash
mouse-on-numpad --help
```

**Show version:**
```bash
mouse-on-numpad --version
```

### Keyboard Controls

**Default Keybindings:**
- `Num Lock` - Toggle mouse mode on/off
- `8/4/6/2` - Move cursor (up/left/right/down)
- `7/9/1/3` - Diagonal movement
- `5` - Left click
- `0` - Hold/release left button
- `Enter` - Right click
- `+` - Double click
- `-` - Middle click

**Speed Modifiers:**
- Hold `Shift` - Slower movement (precision mode)
- Hold `Ctrl` - Faster movement (acceleration)

---

## Troubleshooting

### Service won't start

**Check logs:**
```bash
journalctl --user -u mouse-on-numpad.service -n 50
```

**Common issues:**
- Python not found: Install Python 3.10+
- Import errors: Install missing dependencies
- Permission denied: Check input group membership

### Numpad keys not detected

**Check input device access:**
```bash
# Verify user in input group
groups | grep input

# Check evdev permissions
ls -l /dev/input/event*
```

**For X11:**
Ensure `xdotool` or `python-xlib` is installed.

**For Wayland:**
Ensure `python-evdev` is installed and user in `input` group.

### Desktop entry not showing

**Update desktop database:**
```bash
update-desktop-database ~/.local/share/applications
```

**Check file exists:**
```bash
ls -l ~/.local/share/applications/mouse-on-numpad.desktop
```

### Audio feedback not working

**Check PulseAudio/PipeWire:**
```bash
# PulseAudio
pactl info

# PipeWire (with PulseAudio compatibility)
pw-cli info 0
```

**Test audio manually:**
```bash
paplay /usr/share/sounds/freedesktop/stereo/bell.oga
```

---

## Uninstallation

### AUR Installation

```bash
# Using AUR helper
yay -R mouse-on-numpad

# Manual
sudo pacman -R mouse-on-numpad
```

### Manual Installation

```bash
# Stop and disable service
systemctl --user stop mouse-on-numpad.service
systemctl --user disable mouse-on-numpad.service

# Remove package
pip uninstall mouse-on-numpad

# Remove files (user installation)
rm ~/.local/bin/mouse-on-numpad
rm ~/.local/share/applications/mouse-on-numpad.desktop
rm ~/.config/systemd/user/mouse-on-numpad.service

# Remove config (optional)
rm -rf ~/.config/mouse-on-numpad
```

### System Installation

```bash
# Stop service
systemctl --user stop mouse-on-numpad.service

# Remove package
sudo pip uninstall mouse-on-numpad

# Remove files
sudo rm /usr/bin/mouse-on-numpad
sudo rm /usr/share/applications/mouse-on-numpad.desktop
sudo rm /usr/lib/systemd/user/mouse-on-numpad.service
sudo rm /usr/share/polkit-1/actions/com.github.mouse-on-numpad.policy
```

---

## Additional Resources

- **Documentation:** `docs/` directory
- **GitHub Issues:** https://github.com/Stonelukas/mouse-on-numpad/issues
- **System Architecture:** `docs/system-architecture.md`
- **Code Standards:** `docs/code-standards.md`

---

**Version:** 1.0.0
**Last Updated:** 2026-01-17
