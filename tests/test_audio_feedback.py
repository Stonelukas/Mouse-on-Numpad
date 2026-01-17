"""Tests for audio feedback system."""

from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

from mouse_on_numpad.core.config import ConfigManager
from mouse_on_numpad.input.audio_feedback import AudioFeedback


@pytest.fixture
def temp_config_dir(tmp_path: Path) -> Path:
    """Create temporary config directory."""
    return tmp_path / "config"


@pytest.fixture
def config_manager(temp_config_dir: Path) -> ConfigManager:
    """Create ConfigManager with temp directory."""
    return ConfigManager(config_dir=temp_config_dir)


@pytest.fixture
def audio_feedback_mock_backend(config_manager: ConfigManager) -> AudioFeedback:
    """Create AudioFeedback with mocked backend detection."""
    with patch.object(AudioFeedback, "_detect_backend", return_value="pulseaudio"):
        return AudioFeedback(config_manager)


def test_init_default_config(audio_feedback_mock_backend: AudioFeedback) -> None:
    """Test initialization with default config."""
    assert audio_feedback_mock_backend.is_enabled is True
    assert audio_feedback_mock_backend._volume == 50


def test_init_custom_config(temp_config_dir: Path) -> None:
    """Test initialization with custom config."""
    config_manager = ConfigManager(config_dir=temp_config_dir)
    config_manager.set("audio.enabled", False)
    config_manager.set("audio.volume", 75)

    with patch.object(AudioFeedback, "_detect_backend", return_value="pulseaudio"):
        audio = AudioFeedback(config_manager)

    assert audio.is_enabled is False
    assert audio._volume == 75


def test_enable_disable(audio_feedback_mock_backend: AudioFeedback) -> None:
    """Test enabling and disabling audio."""
    # Disable
    audio_feedback_mock_backend.disable()
    assert audio_feedback_mock_backend.is_enabled is False

    # Enable
    audio_feedback_mock_backend.enable()
    assert audio_feedback_mock_backend.is_enabled is True


def test_set_volume(audio_feedback_mock_backend: AudioFeedback) -> None:
    """Test setting volume."""
    audio_feedback_mock_backend.set_volume(75)
    assert audio_feedback_mock_backend._volume == 75

    audio_feedback_mock_backend.set_volume(0)
    assert audio_feedback_mock_backend._volume == 0

    audio_feedback_mock_backend.set_volume(100)
    assert audio_feedback_mock_backend._volume == 100


def test_set_volume_invalid(audio_feedback_mock_backend: AudioFeedback) -> None:
    """Test setting invalid volume raises ValueError."""
    with pytest.raises(ValueError, match="Volume must be 0-100"):
        audio_feedback_mock_backend.set_volume(-1)

    with pytest.raises(ValueError, match="Volume must be 0-100"):
        audio_feedback_mock_backend.set_volume(101)


@patch("subprocess.run")
def test_play_click(mock_run: MagicMock, audio_feedback_mock_backend: AudioFeedback) -> None:
    """Test playing click sound."""
    audio_feedback_mock_backend.play_click()

    # Should call subprocess.run with speaker-test
    mock_run.assert_called_once()
    args = mock_run.call_args[0][0]
    assert "speaker-test" in args
    assert "-f" in args
    assert str(AudioFeedback.TONE_CLICK) in args


@patch("subprocess.run")
def test_play_toggle_on(
    mock_run: MagicMock, audio_feedback_mock_backend: AudioFeedback
) -> None:
    """Test playing toggle-on sound."""
    audio_feedback_mock_backend.play_toggle_on()

    mock_run.assert_called_once()
    args = mock_run.call_args[0][0]
    assert str(AudioFeedback.TONE_TOGGLE_ON) in args


@patch("subprocess.run")
def test_play_toggle_off(
    mock_run: MagicMock, audio_feedback_mock_backend: AudioFeedback
) -> None:
    """Test playing toggle-off sound."""
    audio_feedback_mock_backend.play_toggle_off()

    mock_run.assert_called_once()
    args = mock_run.call_args[0][0]
    assert str(AudioFeedback.TONE_TOGGLE_OFF) in args


@patch("subprocess.run")
def test_play_save(mock_run: MagicMock, audio_feedback_mock_backend: AudioFeedback) -> None:
    """Test playing save sound."""
    audio_feedback_mock_backend.play_save()

    mock_run.assert_called_once()
    args = mock_run.call_args[0][0]
    assert str(AudioFeedback.TONE_SAVE) in args


@patch("subprocess.run")
def test_play_when_disabled(
    mock_run: MagicMock, audio_feedback_mock_backend: AudioFeedback
) -> None:
    """Test sounds don't play when disabled."""
    audio_feedback_mock_backend.disable()

    audio_feedback_mock_backend.play_click()
    audio_feedback_mock_backend.play_toggle_on()
    audio_feedback_mock_backend.play_save()

    # subprocess.run should not be called
    mock_run.assert_not_called()


@patch("subprocess.run")
def test_detect_backend_pipewire(mock_run: MagicMock, config_manager: ConfigManager) -> None:
    """Test detecting PipeWire backend."""
    mock_result = MagicMock()
    mock_result.returncode = 0
    mock_result.stdout = "Server Name: PulseAudio (on PipeWire 0.3.65)"
    mock_run.return_value = mock_result

    audio = AudioFeedback(config_manager)
    assert audio._backend == "pipewire"


@patch("subprocess.run")
def test_detect_backend_pulseaudio(
    mock_run: MagicMock, config_manager: ConfigManager
) -> None:
    """Test detecting PulseAudio backend."""
    mock_result = MagicMock()
    mock_result.returncode = 0
    mock_result.stdout = "Server Name: pulseaudio"
    mock_run.return_value = mock_result

    audio = AudioFeedback(config_manager)
    assert audio._backend == "pulseaudio"


@patch("subprocess.run")
def test_detect_backend_none(mock_run: MagicMock, config_manager: ConfigManager) -> None:
    """Test fallback when no audio backend available."""
    mock_run.side_effect = FileNotFoundError()

    audio = AudioFeedback(config_manager)
    assert audio._backend == "none"


@patch("subprocess.run")
def test_play_with_no_backend(mock_run: MagicMock, config_manager: ConfigManager) -> None:
    """Test playing sounds with no backend doesn't crash."""
    mock_run.side_effect = FileNotFoundError()

    audio = AudioFeedback(config_manager)
    assert audio._backend == "none"

    # Should not crash
    audio.play_click()
    audio.play_save()


def test_volume_persistence(temp_config_dir: Path) -> None:
    """Test volume setting persists in config."""
    config_manager = ConfigManager(config_dir=temp_config_dir)

    with patch.object(AudioFeedback, "_detect_backend", return_value="pulseaudio"):
        audio = AudioFeedback(config_manager)
        audio.set_volume(75)

    # Create new instance
    config_manager2 = ConfigManager(config_dir=temp_config_dir)
    with patch.object(AudioFeedback, "_detect_backend", return_value="pulseaudio"):
        audio2 = AudioFeedback(config_manager2)

    assert audio2._volume == 75


def test_enabled_persistence(temp_config_dir: Path) -> None:
    """Test enabled state persists in config."""
    config_manager = ConfigManager(config_dir=temp_config_dir)

    with patch.object(AudioFeedback, "_detect_backend", return_value="pulseaudio"):
        audio = AudioFeedback(config_manager)
        audio.disable()

    # Create new instance
    config_manager2 = ConfigManager(config_dir=temp_config_dir)
    with patch.object(AudioFeedback, "_detect_backend", return_value="pulseaudio"):
        audio2 = AudioFeedback(config_manager2)

    assert audio2.is_enabled is False
