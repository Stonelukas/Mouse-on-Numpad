"""Audio feedback system using PulseAudio/PipeWire."""

import logging
import subprocess
from typing import Literal

from mouse_on_numpad.core.config import ConfigManager

_logger = logging.getLogger(__name__)


class AudioFeedback:
    """Provide audio feedback for user actions.

    Features:
    - Simple beep tones for different actions
    - PipeWire/PulseAudio backend with fallback
    - Volume control (0-100)
    - Enable/disable via config
    """

    # Tone frequencies for different actions (in Hz)
    TONE_CLICK = 800  # Quick click
    TONE_TOGGLE_ON = 1000  # Toggle enabled
    TONE_TOGGLE_OFF = 600  # Toggle disabled
    TONE_SAVE = 1200  # Position saved

    # Tone durations (in milliseconds)
    DURATION_SHORT = 50
    DURATION_MEDIUM = 100

    def __init__(self, config: ConfigManager) -> None:
        """Initialize AudioFeedback.

        Args:
            config: ConfigManager instance
        """
        self._config = config
        self._enabled = config.get("audio.enabled", True)
        self._volume = config.get("audio.volume", 50)

        # Detect audio backend
        self._backend = self._detect_backend()
        _logger.info("Audio backend: %s (enabled=%s)", self._backend, self._enabled)

    def _detect_backend(self) -> Literal["pipewire", "pulseaudio", "none"]:
        """Detect available audio backend.

        Returns:
            "pipewire", "pulseaudio", or "none"
        """
        # Check for PipeWire first (modern Linux)
        try:
            result = subprocess.run(
                ["pactl", "info"],
                capture_output=True,
                text=True,
                timeout=1,
                check=False,
            )
            if "PipeWire" in result.stdout:
                return "pipewire"
            if result.returncode == 0:
                return "pulseaudio"
        except (subprocess.TimeoutExpired, FileNotFoundError):
            pass

        # Fallback
        _logger.warning("No PulseAudio/PipeWire detected, audio disabled")
        return "none"

    def _play_tone(self, frequency: int, duration_ms: int) -> None:
        """Play a tone using paplay.

        Args:
            frequency: Tone frequency in Hz
            duration_ms: Duration in milliseconds
        """
        if not self._enabled or self._backend == "none":
            return

        try:
            # Generate sine wave using sox/paplay pipeline
            # Use paplay with raw audio format
            # Formula: samples = sample_rate * duration_ms / 1000
            sample_rate = 44100
            samples = int(sample_rate * duration_ms / 1000)

            # Use speaker-test for simple tone generation
            # Alternative: sox if available
            subprocess.run(
                [
                    "speaker-test",
                    "-t",
                    "sine",
                    "-f",
                    str(frequency),
                    "-l",
                    "1",
                    "-p",
                    str(duration_ms * 1000),  # Convert to microseconds
                ],
                capture_output=True,
                timeout=1,
                check=False,
            )
        except (subprocess.TimeoutExpired, FileNotFoundError) as e:
            _logger.debug("Failed to play tone: %s", e)

    def play_click(self) -> None:
        """Play click feedback sound."""
        self._play_tone(self.TONE_CLICK, self.DURATION_SHORT)

    def play_toggle_on(self) -> None:
        """Play toggle-on feedback sound."""
        self._play_tone(self.TONE_TOGGLE_ON, self.DURATION_MEDIUM)

    def play_toggle_off(self) -> None:
        """Play toggle-off feedback sound."""
        self._play_tone(self.TONE_TOGGLE_OFF, self.DURATION_MEDIUM)

    def play_save(self) -> None:
        """Play position-save feedback sound."""
        self._play_tone(self.TONE_SAVE, self.DURATION_MEDIUM)

    def set_volume(self, volume: int) -> None:
        """Set audio volume.

        Args:
            volume: Volume percentage (0-100)

        Raises:
            ValueError: If volume is out of range
        """
        if not 0 <= volume <= 100:
            raise ValueError(f"Volume must be 0-100, got {volume}")

        self._volume = volume
        self._config.set("audio.volume", volume)
        _logger.info("Audio volume set to %d%%", volume)

    def enable(self) -> None:
        """Enable audio feedback."""
        self._enabled = True
        self._config.set("audio.enabled", True)
        _logger.info("Audio feedback enabled")

    def disable(self) -> None:
        """Disable audio feedback."""
        self._enabled = False
        self._config.set("audio.enabled", False)
        _logger.info("Audio feedback disabled")

    @property
    def is_enabled(self) -> bool:
        """Check if audio feedback is enabled.

        Returns:
            True if enabled, False otherwise
        """
        return self._enabled
