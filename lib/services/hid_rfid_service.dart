import 'package:flutter/services.dart';

/// Service for handling USB HID RFID scanner input (keyboard wedge mode)
/// The RFID scanner acts as a keyboard and types the UID followed by Enter
class HidRfidService {
  static final HidRfidService _instance = HidRfidService._internal();
  factory HidRfidService() => _instance;
  HidRfidService._internal();

  String _buffer = '';
  DateTime? _lastInputTime;
  static const Duration _debounceDuration = Duration(milliseconds: 100);
  static const int _maxUidLength = 20; // Maximum expected UID length

  /// Callback function that will be called when a complete UID is scanned
  Function(String uid)? onUidScanned;

  /// Process keyboard input from HID RFID scanner
  /// Returns true if Enter was detected (scan complete), false otherwise
  bool processKeyEvent(KeyEvent event) {
    // Only process key down events
    if (event is! KeyDownEvent) {
      return false;
    }

    final now = DateTime.now();

    // Handle Enter key (scan completion)
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (_buffer.isNotEmpty) {
        final completeUid = _buffer.trim();
        print('[HidRfidService] ✅ Complete UID received: $completeUid');
        
        // Clear buffer
        _buffer = '';
        _lastInputTime = null;

        // Trigger callback
        onUidScanned?.call(completeUid);
        return true;
      }
      return false;
    }

    // Handle character input
    final character = _getCharacterFromKeyEvent(event);
    if (character != null) {
      // Debounce: reset buffer if too much time passed (new scan started)
      if (_lastInputTime != null &&
          now.difference(_lastInputTime!) > _debounceDuration) {
        print('[HidRfidService] ⚠️ Debounce timeout, clearing buffer');
        _buffer = '';
      }

      // Prevent buffer overflow
      if (_buffer.length < _maxUidLength) {
        _buffer += character;
        _lastInputTime = now;
        print('[HidRfidService] 📝 Buffer: $_buffer');
      } else {
        print('[HidRfidService] ⚠️ Buffer overflow, clearing');
        _buffer = character; // Start fresh
        _lastInputTime = now;
      }
    }

    return false;
  }

  /// Extract character from key event
  String? _getCharacterFromKeyEvent(KeyEvent event) {
    // Handle numeric keys (0-9)
    if (event.logicalKey.keyId >= LogicalKeyboardKey.digit0.keyId &&
        event.logicalKey.keyId <= LogicalKeyboardKey.digit9.keyId) {
      final digit = event.logicalKey.keyId - LogicalKeyboardKey.digit0.keyId;
      return digit.toString();
    }

    // Handle numpad keys (0-9)
    if (event.logicalKey.keyId >= LogicalKeyboardKey.numpad0.keyId &&
        event.logicalKey.keyId <= LogicalKeyboardKey.numpad9.keyId) {
      final digit = event.logicalKey.keyId - LogicalKeyboardKey.numpad0.keyId;
      return digit.toString();
    }

    // Handle letters (A-Z, a-z) - RFID scanners typically send numeric UIDs
    // but we support alphanumeric for flexibility
    if (event.logicalKey.keyId >= LogicalKeyboardKey.keyA.keyId &&
        event.logicalKey.keyId <= LogicalKeyboardKey.keyZ.keyId) {
      final letterIndex = event.logicalKey.keyId - LogicalKeyboardKey.keyA.keyId;
      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
      return String.fromCharCode(isShiftPressed ? 65 : 97 + letterIndex);
    }

    return null;
  }

  /// Clear the input buffer
  void clearBuffer() {
    print('[HidRfidService] 🗑️ Buffer cleared');
    _buffer = '';
    _lastInputTime = null;
  }

  /// Get current buffer content (for debugging)
  String getCurrentBuffer() => _buffer;
}

