#!/bin/bash
# Manual installation script for Mouse on Numpad
# Usage: ./install.sh [--user | --system]

set -e

INSTALL_MODE="${1:---user}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Mouse on Numpad Installation ==="
echo "Install mode: $INSTALL_MODE"
echo ""

# Check Python version
PYTHON_VERSION=$(python3 --version | awk '{print $2}')
REQUIRED_VERSION="3.10"

if ! python3 -c "import sys; exit(0 if sys.version_info >= (3, 10) else 1)"; then
    echo "Error: Python $REQUIRED_VERSION or higher required (found $PYTHON_VERSION)"
    exit 1
fi

# Install Python package
echo "Installing Python package..."
cd "$PROJECT_DIR"

if [ "$INSTALL_MODE" = "--system" ]; then
    echo "System-wide installation requires sudo..."
    sudo python3 -m pip install .
    BIN_DIR="/usr/bin"
    APPLICATIONS_DIR="/usr/share/applications"
    SYSTEMD_DIR="/usr/lib/systemd/user"
    POLKIT_DIR="/usr/share/polkit-1/actions"
    ICONS_DIR="/usr/share/icons/hicolor/scalable/apps"
else
    python3 -m pip install --user .
    BIN_DIR="$HOME/.local/bin"
    APPLICATIONS_DIR="$HOME/.local/share/applications"
    SYSTEMD_DIR="$HOME/.config/systemd/user"
    POLKIT_DIR="$HOME/.local/share/polkit-1/actions"
    ICONS_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
fi

echo "Package installed successfully."
echo ""

# Create directories
echo "Creating directories..."
mkdir -p "$APPLICATIONS_DIR"
mkdir -p "$SYSTEMD_DIR"
mkdir -p "$POLKIT_DIR"
mkdir -p "$ICONS_DIR"

# Install desktop entry
echo "Installing desktop entry..."
if [ "$INSTALL_MODE" = "--system" ]; then
    sudo cp "$SCRIPT_DIR/mouse-on-numpad.desktop" "$APPLICATIONS_DIR/"
else
    cp "$SCRIPT_DIR/mouse-on-numpad.desktop" "$APPLICATIONS_DIR/"
fi

# Install systemd service
echo "Installing systemd service..."
if [ "$INSTALL_MODE" = "--system" ]; then
    sudo cp "$SCRIPT_DIR/mouse-on-numpad.service" "$SYSTEMD_DIR/"
else
    cp "$SCRIPT_DIR/mouse-on-numpad.service" "$SYSTEMD_DIR/"
    systemctl --user daemon-reload
fi

# Install polkit policy
echo "Installing polkit policy..."
if [ "$INSTALL_MODE" = "--system" ]; then
    sudo cp "$SCRIPT_DIR/com.github.mouse-on-numpad.policy" "$POLKIT_DIR/"
else
    echo "Warning: Polkit policy requires system installation"
    echo "Run with --system or manually copy policy to $POLKIT_DIR"
fi

# Install icon (if available)
# if [ -f "$PROJECT_DIR/data/icons/app-icon.svg" ]; then
#     echo "Installing application icon..."
#     if [ "$INSTALL_MODE" = "--system" ]; then
#         sudo cp "$PROJECT_DIR/data/icons/app-icon.svg" "$ICONS_DIR/mouse-on-numpad.svg"
#     else
#         cp "$PROJECT_DIR/data/icons/app-icon.svg" "$ICONS_DIR/mouse-on-numpad.svg"
#     fi
# fi

# Update desktop database
echo "Updating desktop database..."
if [ "$INSTALL_MODE" = "--system" ]; then
    sudo update-desktop-database /usr/share/applications 2>/dev/null || true
else
    update-desktop-database "$APPLICATIONS_DIR" 2>/dev/null || true
fi

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Command installed: mouse-on-numpad"
echo "Desktop entry: $APPLICATIONS_DIR/mouse-on-numpad.desktop"
echo "Systemd service: $SYSTEMD_DIR/mouse-on-numpad.service"
echo ""
echo "To enable autostart:"
echo "  systemctl --user enable mouse-on-numpad.service"
echo "  systemctl --user start mouse-on-numpad.service"
echo ""
echo "To run the GUI:"
echo "  mouse-on-numpad --settings"
echo ""
echo "For more information, see docs/installation.md"
