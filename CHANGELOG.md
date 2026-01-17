# Changelog

All notable changes to Mouse on Numpad Enhanced will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned
- Flatpak packaging
- AppImage build
- Wayland-native implementation
- Plugin system for custom key mappings
- Desktop notifications for state changes

---

## [1.0.0] - 2026-01-17

### Added - Phase 1: Core Infrastructure
- Thread-safe `ConfigManager` with XDG Base Directory compliance
- Observable `StateManager` with subscriber pattern for state changes
- Centralized `ErrorLogger` with log rotation and structured logging
- Comprehensive test suite with 80%+ coverage
- Type-safe configuration with nested key access via dot notation
- Configuration auto-backup on save (`.bak` files)

### Added - Phase 2: Input Control Layer (Planned)
- Numpad key listener with X11/Wayland support
- Mouse control via pynput with acceleration
- Configurable key mappings
- Speed modifiers (Shift=slow, Ctrl=fast)
- Click modes (single, double, hold, drag)

### Added - Phase 3: Position Memory & Audio (Planned)
- Position memory system (save/recall cursor positions)
- Audio feedback controller using PulseAudio
- Configurable audio cues for state changes
- Visual status bar indicator

### Added - Phase 4: GUI Implementation (Planned)
- GTK4 settings window
- Real-time configuration preview
- Visual key mapping editor
- Audio feedback controls

### Added - Phase 5: Wayland Support (Planned)
- Evdev-based input capture for Wayland
- libinput integration
- Compositor-agnostic implementation

### Added - Phase 6: Packaging & Distribution
- AUR PKGBUILD for Arch Linux installation
- XDG desktop entry for application menu integration
- Systemd user service for daemon mode
- Polkit policy for input device access
- Manual installation script (`install.sh`)
- Comprehensive installation documentation

### Documentation
- Project overview and design goals (`docs/project-overview-pdr.md`)
- System architecture documentation (`docs/system-architecture.md`)
- Code standards and guidelines (`docs/code-standards.md`)
- Codebase summary (`docs/codebase-summary.md`)
- Installation guide (`docs/installation.md`)
- Development workflow rules (`.claude/rules/`)

### Infrastructure
- Python 3.10+ project with modern type hints
- Ruff for formatting and linting
- MyPy for strict type checking
- Pytest with coverage reporting
- GitHub Actions CI/CD (planned)

---

## [0.1.0] - 2024-XX-XX (Windows Legacy)

### Legacy Features (Windows-only)
- Basic numpad mouse control
- Simple GUI with tkinter
- Position memory (9 slots)
- Audio feedback
- System tray integration

**Note:** Version 0.1.0 was the original Windows implementation. Version 1.0.0 is a complete rewrite for Linux with enhanced architecture and features.

---

## Migration from Windows Version

**Breaking Changes:**
- Complete rewrite - no backward compatibility with Windows version
- Configuration format changed to JSON (was INI)
- Different key mappings (configurable)
- GTK4 GUI instead of tkinter
- Systemd service instead of Windows service

**Migration Steps:**
1. Export settings from Windows version (if applicable)
2. Install Linux version via AUR or manual installation
3. Configure via GUI: `mouse-on-numpad --settings`
4. Enable systemd service for autostart

---

## Version History

- **1.0.0** - Complete Linux port with modern architecture
- **0.1.0** - Original Windows implementation (legacy)

---

**For detailed technical changes, see commit history:**
https://github.com/Stonelukas/mouse-on-numpad/commits/main
