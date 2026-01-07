import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/constants.dart';

/// Login screen with WebView and integrated RFID card scanning
class LoginWebViewScreen extends StatefulWidget {
  const LoginWebViewScreen({super.key});

  @override
  State<LoginWebViewScreen> createState() => _LoginWebViewScreenState();
}

class _LoginWebViewScreenState extends State<LoginWebViewScreen> {
  late final WebViewController _controller;
  late final FocusNode _focusNode;
  bool _isLoading = true;
  String? _errorMessage;
  
  // RFID scanning state
  String _currentBuffer = '';
  DateTime? _lastInputTime;
  static const Duration _debounceDuration = Duration(milliseconds: 100);
  static const int _maxUidLength = 20;
  bool _isProcessingScan = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _initializeWebView();
    _requestFocus();
  }

  void _requestFocus() {
    // Request focus to capture keyboard input from HID RFID scanner
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            // Re-request focus after page loads
            _requestFocus();
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Error loading page: ${error.description}';
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // Allow navigation within WebView
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(Constants.loginUrl));
  }

  /// Handle keyboard input from HID RFID scanner
  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent || _isProcessingScan) {
      return;
    }

    final now = DateTime.now();

    // Handle Enter key (scan completion)
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (_currentBuffer.isNotEmpty) {
        final completeUid = _currentBuffer.trim();
        print('[LoginWebView] ✅ RFID UID scanned: $completeUid');
        _currentBuffer = '';
        _lastInputTime = null;
        _sendUidToWebView(completeUid);
      }
      return;
    }

    // Handle character input
    final character = _getCharacterFromKeyEvent(event);
    if (character != null) {
      // Debounce: reset buffer if too much time passed (new scan started)
      if (_lastInputTime != null &&
          now.difference(_lastInputTime!) > _debounceDuration) {
        print('[LoginWebView] ⚠️ Debounce timeout, clearing buffer');
        _currentBuffer = '';
      }

      // Prevent buffer overflow
      if (_currentBuffer.length < _maxUidLength) {
        _currentBuffer += character;
        _lastInputTime = now;
        print('[LoginWebView] 📝 Buffer: $_currentBuffer');
      } else {
        print('[LoginWebView] ⚠️ Buffer overflow, clearing');
        _currentBuffer = character; // Start fresh
        _lastInputTime = now;
      }
    }
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
    if (event.logicalKey.keyId >= LogicalKeyboardKey.keyA.keyId &&
        event.logicalKey.keyId <= LogicalKeyboardKey.keyZ.keyId) {
      final letterIndex = event.logicalKey.keyId - LogicalKeyboardKey.keyA.keyId;
      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
      return String.fromCharCode(isShiftPressed ? 65 : 97 + letterIndex);
    }

    return null;
  }

  /// Send RFID UID to WebView via JavaScript
  Future<void> _sendUidToWebView(String uid) async {
    if (_isProcessingScan) {
      print('[LoginWebView] ⚠️ Already processing scan, ignoring');
      return;
    }

    setState(() {
      _isProcessingScan = true;
    });

    try {
      print('[LoginWebView] 📤 Sending UID to WebView: $uid');
      
      // Call JavaScript function in the web page
      final jsCode = '''
        (function() {
          if (typeof window.handleHmiCardLogin === 'function') {
            window.handleHmiCardLogin('$uid');
            return true;
          } else {
            console.warn('handleHmiCardLogin function not found in window object');
            return false;
          }
        })();
      ''';

      final result = await _controller.runJavaScriptReturningResult(jsCode);
      print('[LoginWebView] ✅ JavaScript executed. Result: $result');
      
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('RFID card scanned: $uid'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('[LoginWebView] ❌ Error sending UID to WebView: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending UID: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessingScan = false;
      });
    }
  }

  /// Simulate RFID scan for testing
  void _simulateRfidScan() {
    // Generate a test UID
    const testUid = '1234567890';
    print('[LoginWebView] 🧪 Simulating RFID scan with UID: $testUid');
    _sendUidToWebView(testUid);
  }

  /// Prevent back button from closing the app (kiosk mode)
  Future<bool> _onWillPop() async {
    // Return false to prevent back button from closing the app
    return false;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button from closing app
      onPopInvoked: (didPop) {
        // This will be called but won't pop because canPop is false
        if (didPop) {
          // If somehow it did pop, we can handle it here
        }
      },
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Login'),
            automaticallyImplyLeading: false, // Hide back button
          ),
          body: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
              if (_errorMessage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            _controller.reload();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              // Temporary test button (floating action button)
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  onPressed: _isProcessingScan ? null : _simulateRfidScan,
                  tooltip: 'Simulate RFID Scan (Test)',
                  child: _isProcessingScan
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.credit_card),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

