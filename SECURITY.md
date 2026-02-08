# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly:

1. **Do NOT** open a public issue
2. Email: Use GitHub's private vulnerability reporting feature at https://github.com/mouse-on-numpad/mouse-on-numpad/security/advisories/new
3. Include in your report:
   - Description of the vulnerability
   - Steps to reproduce the issue
   - Impact assessment (what could an attacker do?)
   - Suggested fix (if you have one)

## Scope

This project handles sensitive system operations. Security-relevant areas include:

- **Input device access** (evdev, uinput): Raw keyboard/mouse event capture and injection
- **Configuration file handling**: JSON config parsing and validation
- **Subprocess execution**: External tools (ydotool, xdotool) invocation
- **IPC mechanisms**: Status file in /tmp for inter-process communication
- **Device permissions**: Requires membership in 'input' group for device access

## Response Timeline

We take security seriously and will respond as follows:

- **Acknowledgment**: Within 48 hours of report submission
- **Assessment**: Initial severity assessment within 1 week
- **Fix timeline**:
  - Critical vulnerabilities: Within 30 days
  - High severity: Within 60 days
  - Medium/Low severity: Within 90 days or next release

## Security Considerations

When using this software:

- The daemon requires elevated permissions (input group membership) to capture keyboard events
- Configuration files are stored in user home directory (~/.config/mouse-on-numpad/)
- Status files are written to /tmp (world-readable but low risk)
- No network access or external data transmission occurs

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Known Security Features

- Input validation on all numeric configuration values
- Subprocess calls use explicit paths and validation
- No code execution from configuration files
- Device access limited to keyboard/mouse inputs only
