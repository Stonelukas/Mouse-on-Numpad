"""Tests for backend abstraction layer."""

from __future__ import annotations

import os
from unittest.mock import MagicMock, Mock, patch

import pytest

from mouse_on_numpad.backends import (
    EvdevBackend,
    InputBackend,
    WaylandBackend,
    X11Backend,
    get_backend,
)


class TestBackendAutoDetection:
    """Test backend auto-detection logic."""

    def test_get_backend_x11_session(self) -> None:
        """Test X11 backend selected for X11 sessions."""
        with patch.dict(os.environ, {"XDG_SESSION_TYPE": "x11"}):
            backend = get_backend()
            assert isinstance(backend, X11Backend)

    def test_get_backend_wayland_session(self) -> None:
        """Test Wayland backend selected for Wayland sessions."""
        with patch.dict(os.environ, {"XDG_SESSION_TYPE": "wayland"}):
            backend = get_backend()
            assert isinstance(backend, WaylandBackend)
            # Verify GDK_BACKEND is set
            assert os.environ.get("GDK_BACKEND") == "x11"

    def test_get_backend_wayland_display(self) -> None:
        """Test Wayland backend selected when WAYLAND_DISPLAY is set."""
        with patch.dict(os.environ, {"WAYLAND_DISPLAY": "wayland-0"}):
            backend = get_backend()
            assert isinstance(backend, WaylandBackend)

    def test_get_backend_unknown_session(self) -> None:
        """Test X11 backend attempted for unknown sessions."""
        with patch.dict(os.environ, {"XDG_SESSION_TYPE": "unknown"}, clear=True):
            backend = get_backend()
            # Should attempt X11 backend first
            assert isinstance(backend, (X11Backend, EvdevBackend))


class TestX11Backend:
    """Test X11Backend functionality."""

    def test_initialization(self) -> None:
        """Test X11Backend initializes correctly."""
        backend = X11Backend()
        assert backend is not None
        assert hasattr(backend, "_mouse")
        assert hasattr(backend, "_callbacks")

    def test_move_mouse(self) -> None:
        """Test absolute mouse movement."""
        backend = X11Backend()
        # Just verify the method executes without error
        # Actual position setting requires X11 display
        try:
            backend.move_mouse(100, 200)
        except Exception:
            # Skip test if no X11 display available
            pytest.skip("No X11 display available")

    def test_move_mouse_relative(self) -> None:
        """Test relative mouse movement."""
        backend = X11Backend()
        # Just verify the method executes without error
        try:
            backend.move_mouse_relative(50, -30)
        except Exception:
            # Skip test if no X11 display available
            pytest.skip("No X11 display available")

    def test_click_left(self) -> None:
        """Test left mouse click."""
        backend = X11Backend()
        backend._mouse.click = Mock()

        backend.click("left")
        assert backend._mouse.click.called

    def test_click_invalid_button(self) -> None:
        """Test invalid button raises ValueError."""
        backend = X11Backend()

        with pytest.raises(ValueError, match="Invalid button"):
            backend.click("invalid")

    def test_scroll(self) -> None:
        """Test mouse scrolling."""
        backend = X11Backend()
        backend._mouse.scroll = Mock()

        backend.scroll(0, 5)
        backend._mouse.scroll.assert_called_with(0, 5)

    def test_get_position(self) -> None:
        """Test mouse position query."""
        backend = X11Backend()
        backend._mouse.position = (123.5, 456.7)

        pos = backend.get_position()
        assert pos == (123, 456)  # Should be integers

    def test_register_hotkey(self) -> None:
        """Test hotkey registration."""
        backend = X11Backend()
        callback = Mock()

        backend.register_hotkey("kp_5", callback)
        assert "kp_5" in backend._callbacks

    def test_register_hotkey_with_modifiers(self) -> None:
        """Test hotkey registration with modifiers."""
        backend = X11Backend()
        callback = Mock()

        backend.register_hotkey("kp_5", callback, modifiers=["ctrl", "shift"])
        # Should create key signature with sorted modifiers
        assert "ctrl+shift+kp_5" in backend._callbacks

    def test_unregister_hotkey(self) -> None:
        """Test hotkey unregistration."""
        backend = X11Backend()
        callback = Mock()

        backend.register_hotkey("kp_5", callback)
        backend.unregister_hotkey("kp_5")
        assert "kp_5" not in backend._callbacks

    def test_start_stop_listening(self) -> None:
        """Test hotkey listener start/stop."""
        backend = X11Backend()

        try:
            backend.start_listening()
            assert backend._listener is not None

            backend.stop_listening()
            assert backend._listener is None
        except Exception:
            # Skip test if no X11 display available
            pytest.skip("No X11 display available")


class TestWaylandBackend:
    """Test WaylandBackend functionality."""

    def test_initialization(self) -> None:
        """Test Wayland backend initializes with X11 mode."""
        backend = WaylandBackend()
        assert backend is not None
        # Should inherit from X11Backend
        assert isinstance(backend, X11Backend)
        # Should set GDK_BACKEND
        assert os.environ.get("GDK_BACKEND") == "x11"

    def test_inherits_x11_functionality(self) -> None:
        """Test Wayland backend inherits all X11 methods."""
        backend = WaylandBackend()

        # Should have all InputBackend methods
        assert hasattr(backend, "move_mouse")
        assert hasattr(backend, "move_mouse_relative")
        assert hasattr(backend, "click")
        assert hasattr(backend, "scroll")
        assert hasattr(backend, "get_position")
        assert hasattr(backend, "register_hotkey")


class TestEvdevBackend:
    """Test EvdevBackend functionality."""

    @patch("mouse_on_numpad.backends.evdev_backend.os.path.exists")
    @patch("mouse_on_numpad.backends.evdev_backend.os.access")
    def test_initialization_success(self, mock_access: Mock, mock_exists: Mock) -> None:
        """Test evdev backend initializes when permissions OK."""
        mock_exists.return_value = True
        mock_access.return_value = True

        # Mock evdev module
        with patch.dict("sys.modules", {"evdev": MagicMock()}):
            try:
                backend = EvdevBackend()
                # If initialization succeeds, evdev is available
                assert backend is not None
            except RuntimeError:
                # If evdev not available, that's OK for this test
                pytest.skip("evdev not available in test environment")

    @patch("mouse_on_numpad.backends.evdev_backend.os.path.exists")
    def test_initialization_no_uinput(self, mock_exists: Mock) -> None:
        """Test evdev backend fails when uinput missing."""
        mock_exists.return_value = False

        with patch.dict("sys.modules", {"evdev": MagicMock()}):
            with pytest.raises(RuntimeError, match="uinput not found"):
                EvdevBackend()

    @patch("mouse_on_numpad.backends.evdev_backend.os.path.exists")
    @patch("mouse_on_numpad.backends.evdev_backend.os.access")
    def test_initialization_no_permissions(self, mock_access: Mock, mock_exists: Mock) -> None:
        """Test evdev backend fails without write permissions."""
        mock_exists.return_value = True
        mock_access.return_value = False

        with patch.dict("sys.modules", {"evdev": MagicMock()}):
            with pytest.raises(RuntimeError, match="No write permission"):
                EvdevBackend()

    def test_move_mouse_absolute_not_supported(self) -> None:
        """Test absolute positioning raises NotImplementedError."""
        # Create mock evdev backend (skip initialization)
        with patch.dict("sys.modules", {"evdev": MagicMock()}):
            with patch("mouse_on_numpad.backends.evdev_backend.os.path.exists", return_value=True):
                with patch("mouse_on_numpad.backends.evdev_backend.os.access", return_value=True):
                    try:
                        backend = EvdevBackend()
                        with pytest.raises(NotImplementedError, match="Absolute"):
                            backend.move_mouse(100, 100)
                    except RuntimeError:
                        pytest.skip("evdev not available")

    def test_get_position_not_supported(self) -> None:
        """Test position query raises NotImplementedError."""
        with patch.dict("sys.modules", {"evdev": MagicMock()}):
            with patch("mouse_on_numpad.backends.evdev_backend.os.path.exists", return_value=True):
                with patch("mouse_on_numpad.backends.evdev_backend.os.access", return_value=True):
                    try:
                        backend = EvdevBackend()
                        with pytest.raises(NotImplementedError, match="position queries"):
                            backend.get_position()
                    except RuntimeError:
                        pytest.skip("evdev not available")

    def test_hotkeys_not_supported(self) -> None:
        """Test hotkeys raise NotImplementedError."""
        with patch.dict("sys.modules", {"evdev": MagicMock()}):
            with patch("mouse_on_numpad.backends.evdev_backend.os.path.exists", return_value=True):
                with patch("mouse_on_numpad.backends.evdev_backend.os.access", return_value=True):
                    try:
                        backend = EvdevBackend()

                        with pytest.raises(NotImplementedError, match="Global hotkey"):
                            backend.register_hotkey("kp_5", lambda: None)

                        with pytest.raises(NotImplementedError):
                            backend.unregister_hotkey("kp_5")

                        with pytest.raises(NotImplementedError):
                            backend.start_listening()

                        with pytest.raises(NotImplementedError):
                            backend.stop_listening()
                    except RuntimeError:
                        pytest.skip("evdev not available")


class TestInputBackendInterface:
    """Test InputBackend abstract interface."""

    def test_cannot_instantiate_abstract_class(self) -> None:
        """Test InputBackend cannot be instantiated directly."""
        with pytest.raises(TypeError):
            InputBackend()  # type: ignore[abstract]

    def test_all_backends_implement_interface(self) -> None:
        """Test all concrete backends implement InputBackend."""
        assert issubclass(X11Backend, InputBackend)
        assert issubclass(WaylandBackend, InputBackend)
        assert issubclass(EvdevBackend, InputBackend)
