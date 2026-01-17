"""Mouse on Numpad Enhanced - Main entry point."""

import argparse
import sys

from . import __version__
from .core import ConfigManager, ErrorLogger, StateManager


def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        prog="mouse-on-numpad",
        description="Control mouse with numpad keys on Linux",
    )
    parser.add_argument(
        "--version",
        action="version",
        version=f"%(prog)s {__version__}",
    )
    parser.add_argument(
        "--daemon",
        action="store_true",
        help="Run in background daemon mode",
    )
    parser.add_argument(
        "--settings",
        action="store_true",
        help="Open settings GUI",
    )
    parser.add_argument(
        "--toggle",
        action="store_true",
        help="Toggle mouse control on/off",
    )
    parser.add_argument(
        "--status",
        action="store_true",
        help="Show current status",
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Enable debug logging",
    )
    return parser.parse_args()


def main() -> int:
    """Application entry point.

    Returns:
        Exit code (0 for success)
    """
    args = parse_args()

    # Initialize core components
    logger = ErrorLogger(console_output=args.debug)
    config = ConfigManager()
    state = StateManager()

    logger.info("Mouse on Numpad %s starting", __version__)
    logger.debug("Config loaded from: %s", config.config_file)

    if args.status:
        # Show current state
        snapshot = state.get_state_snapshot()
        print(f"Mouse Mode: {'ENABLED' if snapshot['is_enabled'] else 'DISABLED'}")
        print(f"NumLock: {'ON' if snapshot['numlock_state'] else 'OFF'}")
        print(f"Position: {snapshot['current_position']}")
        print(f"Monitor: {snapshot['active_monitor']}")
        return 0

    if args.toggle:
        enabled = state.toggle()
        status = "enabled" if enabled else "disabled"
        print(f"Mouse control {status}")
        logger.info("Mouse control toggled: %s", status)
        return 0

    if args.settings:
        # Launch GTK GUI
        import gi

        gi.require_version("Gtk", "4.0")
        from .app import Application

        app = Application()
        return app.run(None)

    if args.daemon:
        # Daemon mode will be implemented in Phase 3
        print("Daemon mode not yet implemented (Phase 3)")
        logger.info("Daemon mode requested but not yet implemented")
        return 0

    # Default: show help
    print(f"Mouse on Numpad Enhanced v{__version__}")
    print("Use --help for usage information")
    print("Use --status to check current state")
    return 0


if __name__ == "__main__":
    sys.exit(main())
