---
phase: 6
title: "Packaging & Distribution"
status: completed
priority: P3
effort: 4h
completed: 2026-01-17
---

# Phase 6: Packaging & Distribution

## Context

- Parent: [plan.md](./plan.md)
- Source: [LINUX_PORT_PLAN.md](../../LINUX_PORT_PLAN.md) Section 3 Phase 6
- Dependencies: Phase 1-5 (complete application)

## Overview

Package for distribution with AUR priority. Create XDG desktop entry, systemd service, and PKGBUILD. **Defer Flatpak/AppImage to post-MVP.**

## Key Insights

- AUR is primary target (Arch Linux focus)
- uv for Python packaging
- systemd user service for daemon mode
- XDG compliance for desktop integration

## Requirements

### Functional
- AUR PKGBUILD
- XDG desktop entry
- systemd user service
- Installation documentation
- PyPI package (optional)

### Non-Functional
- Single command install (AUR helper)
- Proper dependencies declared
- Clean uninstall path
- Follow Arch packaging guidelines

## Architecture

```
packaging/
  mouse-on-numpad.desktop   # XDG desktop entry
  mouse-on-numpad.service   # systemd user service
  PKGBUILD                  # Arch Linux package
  install.sh                # Manual install script
```

### Package Contents
```
/usr/bin/mouse-on-numpad
/usr/share/applications/mouse-on-numpad.desktop
/usr/share/icons/hicolor/scalable/apps/mouse-on-numpad.svg
/usr/lib/systemd/user/mouse-on-numpad.service
```

## Related Code Files

### Create
- `packaging/mouse-on-numpad.desktop`
- `packaging/mouse-on-numpad.service`
- `packaging/PKGBUILD`
- `packaging/install.sh`
- `docs/installation.md`
- `CHANGELOG.md`

## Implementation Steps

1. Create XDG desktop entry
   ```ini
   [Desktop Entry]
   Type=Application
   Name=Mouse on Numpad
   Comment=Control mouse with numpad keys
   Exec=mouse-on-numpad
   Icon=mouse-on-numpad
   Categories=Utility;Accessibility;
   Keywords=mouse;numpad;accessibility;keyboard;
   StartupNotify=false
   Terminal=false
   ```

2. Create systemd user service
   ```ini
   [Unit]
   Description=Mouse on Numpad Enhanced
   After=graphical-session.target
   PartOf=graphical-session.target

   [Service]
   Type=simple
   ExecStart=/usr/bin/mouse-on-numpad --daemon
   Restart=on-failure
   RestartSec=5

   [Install]
   WantedBy=graphical-session.target
   ```

3. Create PKGBUILD for AUR
   ```bash
   # Maintainer: Your Name <email>
   pkgname=mouse-on-numpad
   pkgver=1.0.0
   pkgrel=1
   pkgdesc="Control mouse with numpad keys"
   arch=('any')
   url="https://github.com/user/mouse-on-numpad"
   license=('MIT')
   depends=('python>=3.10' 'python-pynput' 'python-gobject' 'gtk4')
   makedepends=('python-build' 'python-installer')
   source=("$pkgname-$pkgver.tar.gz")

   build() {
       cd "$pkgname-$pkgver"
       python -m build --wheel --no-isolation
   }

   package() {
       cd "$pkgname-$pkgver"
       python -m installer --destdir="$pkgdir" dist/*.whl
       install -Dm644 packaging/*.desktop "$pkgdir/usr/share/applications/"
       install -Dm644 packaging/*.service "$pkgdir/usr/lib/systemd/user/"
       install -Dm644 data/icons/app-icon.svg "$pkgdir/usr/share/icons/hicolor/scalable/apps/mouse-on-numpad.svg"
   }
   ```

4. Update pyproject.toml
   - Add entry points for CLI
   - Configure package metadata
   - Set version properly

5. Create manual install script
   ```bash
   #!/bin/bash
   # Install mouse-on-numpad from source
   uv pip install .
   # Copy desktop file, service, icons
   ```

6. Write installation documentation
   - AUR installation
   - Manual installation
   - systemd service setup
   - Autostart configuration
   - Troubleshooting

7. Set up release workflow
   - Tag-based releases
   - Generate changelog
   - Upload to AUR

## Todo List

- [x] Create XDG desktop entry
- [x] Create systemd user service
- [x] Create PKGBUILD for AUR
- [x] Update pyproject.toml entry points (already configured)
- [x] Create manual install.sh script
- [x] Write installation documentation
- [x] Create CHANGELOG.md
- [x] Create LICENSE file
- [x] Create polkit policy file
- [ ] Test AUR package locally (requires full implementation)
- [ ] Test systemd service enable/start (requires executable)
- [ ] Verify desktop entry appears in menu (requires installation)

## Success Criteria

- [ ] `makepkg -si` installs package
- [ ] `mouse-on-numpad` command available after install
- [ ] Desktop entry appears in application menu
- [ ] `systemctl --user enable mouse-on-numpad` works
- [ ] Service starts on login
- [ ] Clean uninstall removes all files
- [ ] Documentation covers all install methods

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| AUR guideline violations | Medium | Review Arch Wiki packaging |
| Dependency version mismatch | Low | Test on clean Arch install |
| Service fails silently | Low | Add logging, journalctl |
| Icon not displaying | Low | Use SVG, test themes |

## Security Considerations

- Package signed with maintainer key
- No post-install scripts with elevated privileges
- Service runs as user, not root
- Dependencies from official repos only

## Future (Post-MVP)

- Flatpak manifest
- AppImage build
- Debian/Ubuntu .deb
- Fedora .rpm
- PyPI upload
- CI/CD for automated releases

## Next Steps

After Phase 6 complete:
- MVP ready for distribution
- Submit to AUR
- Announce release
- Gather user feedback
