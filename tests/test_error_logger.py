"""Tests for ErrorLogger."""

import logging
import os
import tempfile
from pathlib import Path

import pytest

from mouse_on_numpad.core.error_logger import ErrorLogger, get_logger


@pytest.fixture
def temp_log_dir():
    """Create a temporary log directory for testing."""
    with tempfile.TemporaryDirectory() as tmpdir:
        yield Path(tmpdir)


class TestErrorLogger:
    """Test ErrorLogger functionality."""

    def test_creates_log_directory(self, temp_log_dir: Path):
        """Log directory created on initialization."""
        logger = ErrorLogger(log_dir=temp_log_dir)
        assert temp_log_dir.exists()

    def test_creates_log_file(self, temp_log_dir: Path):
        """Log file created when logging."""
        logger = ErrorLogger(name="test", log_dir=temp_log_dir)
        logger.info("Test message")
        assert logger.log_file.exists()

    def test_log_levels(self, temp_log_dir: Path):
        """All log levels work."""
        logger = ErrorLogger(name="test", log_dir=temp_log_dir, level=logging.DEBUG)
        logger.debug("Debug message")
        logger.info("Info message")
        logger.warning("Warning message")
        logger.error("Error message")

        with open(logger.log_file) as f:
            content = f.read()

        assert "Debug message" in content
        assert "Info message" in content
        assert "Warning message" in content
        assert "Error message" in content

    def test_log_format(self, temp_log_dir: Path):
        """Log format includes timestamp and level."""
        logger = ErrorLogger(name="test", log_dir=temp_log_dir)
        logger.info("Format test")

        with open(logger.log_file) as f:
            content = f.read()

        # Check format: timestamp - name - level - message
        assert "INFO" in content
        assert "test" in content
        assert "Format test" in content

    def test_secure_permissions(self, temp_log_dir: Path):
        """Log directory has secure permissions (0700)."""
        logger = ErrorLogger(log_dir=temp_log_dir)

        dir_stat = os.stat(temp_log_dir)
        dir_mode = dir_stat.st_mode & 0o777
        assert dir_mode == 0o700

    def test_set_level(self, temp_log_dir: Path):
        """Logging level can be changed."""
        logger = ErrorLogger(name="test", log_dir=temp_log_dir, level=logging.WARNING)
        logger.debug("Should not appear")
        logger.info("Should not appear")
        logger.warning("Should appear")

        with open(logger.log_file) as f:
            content = f.read()

        assert "Should not appear" not in content
        assert "Should appear" in content

        # Change level to DEBUG
        logger.set_level(logging.DEBUG)
        logger.debug("Now visible")

        with open(logger.log_file) as f:
            content = f.read()

        assert "Now visible" in content

    def test_exception_logging(self, temp_log_dir: Path):
        """Exception logging includes traceback."""
        logger = ErrorLogger(name="test", log_dir=temp_log_dir)

        try:
            raise ValueError("Test exception")
        except ValueError:
            logger.exception("Caught exception")

        with open(logger.log_file) as f:
            content = f.read()

        assert "Caught exception" in content
        assert "ValueError" in content
        assert "Test exception" in content

    def test_log_path_properties(self, temp_log_dir: Path):
        """Log path properties return correct paths."""
        logger = ErrorLogger(name="test", log_dir=temp_log_dir)
        assert logger.log_dir == temp_log_dir
        assert logger.log_file == temp_log_dir / "test.log"

    def test_separate_logger_instances(self, temp_log_dir: Path):
        """Each ErrorLogger instance has its own logger."""
        logger1 = ErrorLogger(name="unique_test", log_dir=temp_log_dir)
        logger2 = ErrorLogger(name="unique_test", log_dir=temp_log_dir)

        # Each instance has exactly one handler (its own file handler)
        assert len(logger1._logger.handlers) == 1
        assert len(logger2._logger.handlers) == 1
        # But they're different loggers
        assert logger1._logger is not logger2._logger


class TestGetLogger:
    """Test get_logger convenience function."""

    def test_returns_logger_instance(self):
        """get_logger returns ErrorLogger instance."""
        logger = get_logger()
        assert isinstance(logger, ErrorLogger)

    def test_returns_same_instance(self):
        """get_logger returns same instance on repeated calls."""
        logger1 = get_logger()
        logger2 = get_logger()
        assert logger1 is logger2
