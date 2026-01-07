import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'home_webview.dart';

/// RFID scanning screen for USB HID keyboard wedge scanners
/// The scanner types the UID and presses Enter automatically
class HidRfidScanScreen extends StatefulWidget {
  const HidRfidScanScreen({super.key});

  @override
  State<HidRfidScanScreen> createState() => _HidRfidScanScreenState();
}

class _HidRfidScanScreenState extends State<HidRfidScanScreen> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _textController = TextEditingController();
  
  bool _isProcessing = false;
  String? _statusMessage;
  String? _lastScannedUid;
  String _currentBuffer = '';
  DateTime? _lastInputTime;
  static const Duration _debounceDuration = Duration(milliseconds: 100);
  static const int _maxUidLength = 20;

  @override
  void initState() {
    super.initState();
    _requestFocus();
  }

  void _requestFocus() {
    // Request focus so we can capture keyboard input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      setState(() {
        _statusMessage = 'Ready to scan. Please scan your RFID card...';
      });
    });
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) {
      return;
    }

    final now = DateTime.now();

    // Handle Enter key (scan completion)
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (_currentBuffer.isNotEmpty) {
        final completeUid = _currentBuffer.trim();
        print('[HidRfidScanScreen] ✅ Complete UID received: $completeUid');
        _currentBuffer = '';
        _lastInputTime = null;
        _textController.clear();
        _handleScannedUid(completeUid);
      }
      return;
    }

    // Handle character input
    final character = _getCharacterFromRawKeyEvent(event);
    if (character != null) {
      // Debounce: reset buffer if too much time passed (new scan started)
      if (_lastInputTime != null &&
          now.difference(_lastInputTime!) > _debounceDuration) {
        print('[HidRfidScanScreen] ⚠️ Debounce timeout, clearing buffer');
        _currentBuffer = '';
      }

      // Prevent buffer overflow
      if (_currentBuffer.length < _maxUidLength) {
        _currentBuffer += character;
        _lastInputTime = now;
        _textController.text = _currentBuffer;
        print('[HidRfidScanScreen] 📝 Buffer: $_currentBuffer');
        setState(() {}); // Update UI
      } else {
        print('[HidRfidScanScreen] ⚠️ Buffer overflow, clearing');
        _currentBuffer = character; // Start fresh
        _lastInputTime = now;
        _textController.text = _currentBuffer;
        setState(() {}); // Update UI
      }
    }
  }

  String? _getCharacterFromRawKeyEvent(RawKeyEvent event) {
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
    if (event.logicalKey.keyId >= LogicalKeyboardKey.keyA.keyId &&
        event.logicalKey.keyId <= LogicalKeyboardKey.keyZ.keyId) {
      final letterIndex = event.logicalKey.keyId - LogicalKeyboardKey.keyA.keyId;
      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
      return String.fromCharCode(isShiftPressed ? 65 : 97 + letterIndex);
    }

    return null;
  }

  Future<void> _handleScannedUid(String uid) async {
    if (_isProcessing) {
      print('[HidRfidScanScreen] ⚠️ Already processing, ignoring duplicate scan');
      return;
    }

    setState(() {
      _isProcessing = true;
      _lastScannedUid = uid;
      _statusMessage = 'Processing UID: $uid...';
      _currentBuffer = '';
    });

    // Log UID received
    print('[HidRfidScanScreen] 📥 UID received from scanner: $uid');

    try {
      // Call API with the scanned UID
      print('[HidRfidScanScreen] 📤 Sending API request with UID: $uid');
      final response = await ApiService.cardLogin(uid);

      if (response != null) {
        // Log full API response
        print('[HidRfidScanScreen] ✅ API Response: $response');
        print('[HidRfidScanScreen] ✅ API Response (JSON): ${jsonEncode(response)}');

        // Store user data if present
        if (response.containsKey('user')) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(response['user']));
        }

        // Store card UID
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(Constants.cardUidKey, uid);

        // Navigate to order list screen
        if (mounted) {
          print('[HidRfidScanScreen] 🚀 Navigating to order list screen');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeWebViewScreen(),
            ),
          );
        }
      } else {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'API request failed. Please try again.';
        });
        _showError('Failed to process card. Please check connection and try again.');
        _currentBuffer = '';
      }
    } catch (e) {
      print('[HidRfidScanScreen] ❌ Error: $e');
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
      _showError('Error processing scan: $e');
      _currentBuffer = '';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    _currentBuffer = '';
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan RFID Card'),
      ),
      body: RawKeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKey: _handleKeyEvent,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.credit_card,
                  size: 120,
                  color: _isProcessing ? Colors.orange : Colors.blue,
                ),
                const SizedBox(height: 32),
                if (_statusMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      _statusMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (_lastScannedUid != null && !_isProcessing)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Last scanned: $_lastScannedUid',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                if (_currentBuffer.isNotEmpty && !_isProcessing)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Buffer: $_currentBuffer',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
                if (_isProcessing)
                  const CircularProgressIndicator(),
                if (!_isProcessing)
                  const Text(
                    'Scan your RFID card using the USB scanner',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                const SizedBox(height: 24),
                // Hidden text field to capture input (optional, for debugging)
                Opacity(
                  opacity: 0.0,
                  child: SizedBox(
                    width: 1,
                    height: 1,
                    child: TextField(
                      controller: _textController,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

