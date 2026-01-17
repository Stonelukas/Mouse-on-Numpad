"""Structured logging with rotation and XDG compliance."""

import logging
import os
import uuid
from logging.handlers import RotatingFileHandler
from pathlib import Path


class ErrorLogger:
    """Application logger with rotating file handler.

    Features:
    - XDG Base Directory compliance (~/.local/share/mouse-on-numpad/logs/)
    - Rotating log files (5 MB max, 3 backups)
    - Structured format with timestamps
    - Console output in debug mode
    """

    LOG_FORMAT = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    LOG_DATE_FORMAT = "%Y-%m-%d %H:%M:%S"
    MAX_BYTES = 5 * 1024 * 1024  # 5 MB
    BACKUP_COUNT = 3

    def __init__(
        self,
        name: str = "mouse-on-numpad",
        log_dir: Path | None = None,
        level: int = logging.INFO,
        console_output: bool = False,
    ) -> None:
        """Initialize ErrorLogger.

        Args:
            name: Logger name
            log_dir: Custom log directory. Defaults to XDG_DATA_HOME.
            level: Logging level (DEBUG, INFO, WARNING, ERROR)
            console_output: Enable console output (for debugging)
        """
        if log_dir is None:
            xdg_data = os.environ.get(
                "XDG_DATA_HOME", str(Path.home() / ".local" / "share")
            )
            self._log_dir = Path(xdg_data) / "mouse-on-numpad" / "logs"
        else:
            self._log_dir = log_dir

        self._log_file = self._log_dir / f"{name}.log"
        # Use unique logger name to avoid conflicts with cached loggers
        # This ensures each ErrorLogger instance gets its own fresh logger
        self._logger_name = f"mouse_on_numpad.{name}.{uuid.uuid4().hex[:8]}"
        self._logger = logging.getLogger(self._logger_name)
        self._logger.setLevel(level)
        # Don't propagate to root logger (avoids pytest capturing)
        self._logger.propagate = False
        # Always set up handlers for this unique logger
        self._setup_handlers(console_output)

    def _setup_handlers(self, console_output: bool) -> None:
        """Configure file and optional console handlers."""
        formatter = logging.Formatter(self.LOG_FORMAT, datefmt=self.LOG_DATE_FORMAT)

        # Ensure log directory exists
        self._log_dir.mkdir(parents=True, exist_ok=True)
        os.chmod(self._log_dir, 0o700)

        # Rotating file handler
        file_handler = RotatingFileHandler(
            self._log_file,
            maxBytes=self.MAX_BYTES,
            backupCount=self.BACKUP_COUNT,
            encoding="utf-8",
        )
        file_handler.setFormatter(formatter)
        self._logger.addHandler(file_handler)

        # Console handler for debugging
        if console_output:
            console_handler = logging.StreamHandler()
            console_handler.setFormatter(formatter)
            self._logger.addHandler(console_handler)

    @property
    def log_dir(self) -> Path:
        """Return log directory path."""
        return self._log_dir

    @property
    def log_file(self) -> Path:
        """Return log file path."""
        return self._log_file

    def _flush(self) -> None:
        """Flush all handlers to ensure logs are written."""
        for handler in self._logger.handlers:
            handler.flush()

    def debug(self, message: str, *args: object) -> None:
        """Log debug message."""
        self._logger.debug(message, *args)
        self._flush()

    def info(self, message: str, *args: object) -> None:
        """Log info message."""
        self._logger.info(message, *args)
        self._flush()

    def warning(self, message: str, *args: object) -> None:
        """Log warning message."""
        self._logger.warning(message, *args)
        self._flush()

    def error(self, message: str, *args: object) -> None:
        """Log error message."""
        self._logger.error(message, *args)
        self._flush()

    def exception(self, message: str, *args: object) -> None:
        """Log exception with traceback."""
        self._logger.exception(message, *args)
        self._flush()

    def set_level(self, level: int) -> None:
        """Change logging level.

        Args:
            level: logging.DEBUG, INFO, WARNING, ERROR
        """
        self._logger.setLevel(level)


# Global logger instance for convenience
_default_logger: ErrorLogger | None = None


def get_logger() -> ErrorLogger:
    """Get or create the default application logger."""
    global _default_logger
    if _default_logger is None:
        _default_logger = ErrorLogger()
    return _default_logger
