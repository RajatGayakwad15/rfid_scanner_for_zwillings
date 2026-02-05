// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import '../utils/constants.dart';
// import 'home_webview.dart';

// /// Login screen with WebView and integrated RFID card scanning
// class LoginWebViewScreen extends StatefulWidget {
//   const LoginWebViewScreen({super.key});

//   @override
//   State<LoginWebViewScreen> createState() => _LoginWebViewScreenState();
// }

// class _LoginWebViewScreenState extends State<LoginWebViewScreen> {
//   late final WebViewController _controller;
//   late final FocusNode _focusNode;
//   bool _isLoading = true;
//   String? _errorMessage;
//   String _currentUrl = Constants.loginUrl;

//   // RFID scanning state
//   String _currentBuffer = '';
//   DateTime? _lastInputTime;
//   static const Duration _debounceDuration = Duration(milliseconds: 100);
//   static const int _maxUidLength = 20;
//   bool _isProcessingScan = false;

//   @override
//   void initState() {
//     super.initState();
//     _focusNode = FocusNode();
//     _initializeWebView();
//     _requestFocus();
//   }

//   void _requestFocus() {
//     // Request focus to capture keyboard input from HID RFID scanner
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _focusNode.requestFocus();
//     });
//   }

//   void _initializeWebView() {
//     _controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setBackgroundColor(Colors.white)
//       ..enableZoom(true)
//       ..setUserAgent(
//           'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36')
//       ..addJavaScriptChannel(
//         'FlutterLoginChannel',
//         onMessageReceived: (JavaScriptMessage message) {
//           print('[LoginWebView] 📨 Message from WebView: ${message.message}');
//           final data = message.message;
//           if (data == 'login_success' || data.contains('login_success')) {
//             print('[LoginWebView] ✅ Login success detected via channel');
//             if (mounted) {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => const HomeWebViewScreen(),
//                 ),
//               );
//             }
//           }
//         },
//       )
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onPageStarted: (String url) {
//             print('[LoginWebView] 📄 Page started loading: $url');
//             setState(() {
//               _isLoading = true;
//               _errorMessage = null;
//               _currentUrl = url;
//             });

//             // Check if URL indicates successful login (redirects to order list or similar)
//             _checkLoginSuccess(url);
//           },
//           onPageFinished: (String url) async {
//             print('[LoginWebView] ✅ Page finished loading: $url');
//             // Get the actual current URL
//             try {
//               final actualUrl = await _controller.currentUrl();
//               setState(() {
//                 _isLoading = false;
//                 _currentUrl = actualUrl ?? url;
//               });
//             } catch (e) {
//               setState(() {
//                 _isLoading = false;
//                 _currentUrl = url;
//               });
//             }
//             // Re-request focus after page loads
//             _requestFocus();

//             // Check if URL indicates successful login
//             _checkLoginSuccess(url);
//           },
//           onWebResourceError: (WebResourceError error) {
//             print(
//                 '[LoginWebView] ❌ Web resource error: ${error.description} (${error.errorCode})');
//             setState(() {
//               _isLoading = false;
//               _errorMessage = 'Error loading page: ${error.description}';
//             });
//           },
//           onNavigationRequest: (NavigationRequest request) {
//             print('[LoginWebView] 🔄 Navigation request: ${request.url}');
//             // Check if navigation is to order list URL (successful login)
//             if (request.url.contains('/list/process') ||
//                 request.url == Constants.orderListUrl) {
//               // Navigate to home screen instead
//               WidgetsBinding.instance.addPostFrameCallback((_) {
//                 if (mounted) {
//                   Navigator.pushReplacement(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const HomeWebViewScreen(),
//                     ),
//                   );
//                 }
//               });
//               return NavigationDecision.prevent;
//             }
//             // Allow navigation within WebView
//             return NavigationDecision.navigate;
//           },
//         ),
//       );

//     // Load the URL
//     print('[LoginWebView] 🌐 Loading URL: ${Constants.loginUrl}');
//     _controller.loadRequest(Uri.parse(Constants.loginUrl));
//   }

//   /// Handle keyboard input from HID RFID scanner
//   void _handleKeyEvent(KeyEvent event) {
//     if (event is! KeyDownEvent || _isProcessingScan) {
//       return;
//     }

//     final now = DateTime.now();

//     // Handle Enter key (scan completion)
//     if (event.logicalKey == LogicalKeyboardKey.enter ||
//         event.logicalKey == LogicalKeyboardKey.numpadEnter) {
//       if (_currentBuffer.isNotEmpty) {
//         final completeUid = _currentBuffer.trim();
//         print('[LoginWebView] ✅ RFID UID scanned: $completeUid');
//         _currentBuffer = '';
//         _lastInputTime = null;
//         _sendUidToWebView(completeUid);
//       }
//       return;
//     }

//     // Handle character input
//     final character = _getCharacterFromKeyEvent(event);
//     if (character != null) {
//       // Debounce: reset buffer if too much time passed (new scan started)
//       if (_lastInputTime != null &&
//           now.difference(_lastInputTime!) > _debounceDuration) {
//         print('[LoginWebView] ⚠️ Debounce timeout, clearing buffer');
//         _currentBuffer = '';
//       }

//       // Prevent buffer overflow
//       if (_currentBuffer.length < _maxUidLength) {
//         _currentBuffer += character;
//         _lastInputTime = now;
//         print('[LoginWebView] 📝 Buffer: $_currentBuffer');
//       } else {
//         print('[LoginWebView] ⚠️ Buffer overflow, clearing');
//         _currentBuffer = character; // Start fresh
//         _lastInputTime = now;
//       }
//     }
//   }

//   /// Extract character from key event
//   String? _getCharacterFromKeyEvent(KeyEvent event) {
//     // Handle numeric keys (0-9)
//     if (event.logicalKey.keyId >= LogicalKeyboardKey.digit0.keyId &&
//         event.logicalKey.keyId <= LogicalKeyboardKey.digit9.keyId) {
//       final digit = event.logicalKey.keyId - LogicalKeyboardKey.digit0.keyId;
//       return digit.toString();
//     }

//     // Handle numpad keys (0-9)
//     if (event.logicalKey.keyId >= LogicalKeyboardKey.numpad0.keyId &&
//         event.logicalKey.keyId <= LogicalKeyboardKey.numpad9.keyId) {
//       final digit = event.logicalKey.keyId - LogicalKeyboardKey.numpad0.keyId;
//       return digit.toString();
//     }

//     // Handle letters (A-Z, a-z) - RFID scanners typically send numeric UIDs
//     if (event.logicalKey.keyId >= LogicalKeyboardKey.keyA.keyId &&
//         event.logicalKey.keyId <= LogicalKeyboardKey.keyZ.keyId) {
//       final letterIndex =
//           event.logicalKey.keyId - LogicalKeyboardKey.keyA.keyId;
//       final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
//       return String.fromCharCode(isShiftPressed ? 65 : 97 + letterIndex);
//     }

//     return null;
//   }

//   /// Check if URL indicates successful login and navigate accordingly
//   void _checkLoginSuccess(String url) {
//     // Check if URL contains order list path or matches orderListUrl
//     if (url.contains('/list/process') ||
//         url == Constants.orderListUrl ||
//         url.contains('list/process')) {
//       print('[LoginWebView] ✅ Login successful, navigating to order list');
//       // Delay navigation slightly to ensure page is ready
//       Future.delayed(const Duration(milliseconds: 500), () {
//         if (mounted) {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (context) => const HomeWebViewScreen(),
//             ),
//           );
//         }
//       });
//     }
//   }

//   /// Send RFID UID to WebView via JavaScript
//   Future<void> _sendUidToWebView(String uid) async {
//     if (_isProcessingScan) {
//       print('[LoginWebView] ⚠️ Already processing scan, ignoring');
//       return;
//     }

//     setState(() {
//       _isProcessingScan = true;
//     });

//     try {
//       print('[LoginWebView] 📤 Sending UID to WebView: $uid');

//       // Call JavaScript function in the web page
//       final jsCode = '''
//         (function() {
//           if (typeof window.handleHmiCardLogin === 'function') {
//             window.handleHmiCardLogin('$uid');
//             return true;
//           } else {
//             console.warn('handleHmiCardLogin function not found in window object');
//             return false;
//           }
//         })();
//       ''';

//       final result = await _controller.runJavaScriptReturningResult(jsCode);
//       print('[LoginWebView] ✅ JavaScript executed. Result: $result');

//       // Show success feedback
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('RFID card scanned: $uid'),
//             duration: const Duration(seconds: 2),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }

//       // Monitor for navigation to order list after login
//       // Check current URL after a delay to see if login redirected
//       Future.delayed(const Duration(seconds: 2), () async {
//         try {
//           final currentUrl = await _controller.currentUrl();
//           print('[LoginWebView] Current URL after login: $currentUrl');
//           _checkLoginSuccess(currentUrl ?? '');
//         } catch (e) {
//           print('[LoginWebView] Error getting current URL: $e');
//         }
//       });
//     } catch (e) {
//       print('[LoginWebView] ❌ Error sending UID to WebView: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error sending UID: $e'),
//             duration: const Duration(seconds: 3),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       setState(() {
//         _isProcessingScan = false;
//       });
//     }
//   }

//   /// Simulate RFID scan for testing
//   void _simulateRfidScan() {
//     // Generate a test UID
//     const testUid = '1234567890';
//     print('[LoginWebView] 🧪 Simulating RFID scan with UID: $testUid');
//     _sendUidToWebView(testUid);
//   }

//   /// Toggle between cardlogin and login URLs
//   void _toggleLoginUrl() async {
//     try {
//       final currentUrl = await _controller.currentUrl();
//       final url = currentUrl ?? _currentUrl;

//       String newUrl;
//       if (url.contains('/cardlogin')) {
//         // Currently on cardlogin, switch to login
//         newUrl = Constants.regularLoginUrl;
//       } else if (url.contains('/login')) {
//         // Currently on login, switch to cardlogin
//         newUrl = Constants.loginUrl;
//       } else {
//         // Default to cardlogin if URL doesn't match
//         newUrl = Constants.loginUrl;
//       }

//       print('[LoginWebView] 🔄 Toggling from $url to $newUrl');
//       await _controller.loadRequest(Uri.parse(newUrl));
//       setState(() {
//         _currentUrl = newUrl;
//       });
//     } catch (e) {
//       print('[LoginWebView] ❌ Error toggling URL: $e');
//     }
//   }

//   /// Prevent back button from closing the app (kiosk mode)
//   Future<bool> _onWillPop() async {
//     // Return false to prevent back button from closing the app
//     return false;
//   }

//   @override
//   void dispose() {
//     _focusNode.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       canPop: false, // Prevent back button from closing app
//       onPopInvoked: (didPop) {
//         // This will be called but won't pop because canPop is false
//         if (didPop) {
//           // If somehow it did pop, we can handle it here
//         }
//       },
//       child: Scaffold(
//         body: Stack(
//           children: [
//             // WebView should be the base layer
//             SizedBox.expand(
//               child: KeyboardListener(
//                 focusNode: _focusNode,
//                 autofocus: true,
//                 onKeyEvent: _handleKeyEvent,
//                 child: WebViewWidget(controller: _controller),
//               ),
//             ),
//             if (_isLoading)
//               Container(
//                 color: Colors.white.withOpacity(0.8),
//                 child: const Center(
//                   child: CircularProgressIndicator(),
//                 ),
//               ),
//             if (_errorMessage != null)
//               Container(
//                 color: Colors.white,
//                 child: Center(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(Icons.error_outline,
//                             size: 48, color: Colors.red),
//                         const SizedBox(height: 16),
//                         Text(
//                           _errorMessage!,
//                           textAlign: TextAlign.center,
//                           style: const TextStyle(color: Colors.red),
//                         ),
//                         const SizedBox(height: 16),
//                         ElevatedButton(
//                           onPressed: () {
//                             setState(() {
//                               _errorMessage = null;
//                               _isLoading = true;
//                             });
//                             _controller.reload();
//                           },
//                           child: const Text('Retry'),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             // Toggle button for switching between login URLs
//             Positioned(
//               top: 16,
//               right: 16,
//               child: FloatingActionButton(
//                 onPressed: _isLoading ? null : _toggleLoginUrl,
//                 tooltip: 'Toggle Login Type',
//                 mini: true,
//                 child: const Icon(Icons.swap_horiz),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/constants.dart';
import 'home_webview.dart';
import 'login_landing.dart';

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
  String _currentUrl = Constants.loginUrl;

  // ✅ NEW: login state (ONLY for toggle visibility)
  bool _isLoggedIn = false;

  // RFID scanning state (UNCHANGED)
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  // ✅ CENTRALIZED LOGIN SUCCESS (SAFE)
  void _onLoginSuccess() {
    if (_isLoggedIn) return;

    setState(() {
      _isLoggedIn = true; // 🔥 hides toggle
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeWebViewScreen(),
      ),
    );
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(true)
      ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36')
      ..addJavaScriptChannel(
        'FlutterLoginChannel',
        onMessageReceived: (message) {
          final data = message.message;
          if (data.contains('login_success')) {
            _onLoginSuccess();
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
              _currentUrl = url;
            });
            _checkLoginSuccess(url);
          },
          onPageFinished: (url) async {
            final actualUrl = await _controller.currentUrl();
            setState(() {
              _isLoading = false;
              _currentUrl = actualUrl ?? url;
            });
            _requestFocus();
            _checkLoginSuccess(url);
          },
          onWebResourceError: (error) {
            setState(() {
              _isLoading = false;
              _errorMessage = error.description;
            });
          },
          onNavigationRequest: (request) {
            if (request.url.contains('/list/process') ||
                request.url == Constants.orderListUrl) {
              _onLoginSuccess();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    _controller.loadRequest(Uri.parse(Constants.loginUrl));
  }

  void _checkLoginSuccess(String url) {
    if (url.contains('/list/process') ||
        url == Constants.orderListUrl ||
        url.contains('list/process')) {
      Future.delayed(const Duration(milliseconds: 300), _onLoginSuccess);
    }
  }

  // ================= RFID LOGIC (UNCHANGED) =================
  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent || _isProcessingScan) return;

    final now = DateTime.now();

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (_currentBuffer.isNotEmpty) {
        final uid = _currentBuffer.trim();
        _currentBuffer = '';
        _lastInputTime = null;
        _sendUidToWebView(uid);
      }
      return;
    }

    final character = _getCharacterFromKeyEvent(event);
    if (character != null) {
      if (_lastInputTime != null &&
          now.difference(_lastInputTime!) > _debounceDuration) {
        _currentBuffer = '';
      }

      if (_currentBuffer.length < _maxUidLength) {
        _currentBuffer += character;
        _lastInputTime = now;
      } else {
        _currentBuffer = character;
        _lastInputTime = now;
      }
    }
  }

  String? _getCharacterFromKeyEvent(KeyEvent event) {
    if (event.logicalKey.keyId >= LogicalKeyboardKey.digit0.keyId &&
        event.logicalKey.keyId <= LogicalKeyboardKey.digit9.keyId) {
      return (event.logicalKey.keyId - LogicalKeyboardKey.digit0.keyId)
          .toString();
    }

    if (event.logicalKey.keyId >= LogicalKeyboardKey.numpad0.keyId &&
        event.logicalKey.keyId <= LogicalKeyboardKey.numpad9.keyId) {
      return (event.logicalKey.keyId - LogicalKeyboardKey.numpad0.keyId)
          .toString();
    }

    if (event.logicalKey.keyId >= LogicalKeyboardKey.keyA.keyId &&
        event.logicalKey.keyId <= LogicalKeyboardKey.keyZ.keyId) {
      final index = event.logicalKey.keyId - LogicalKeyboardKey.keyA.keyId;
      final shift = HardwareKeyboard.instance.isShiftPressed;
      return String.fromCharCode(shift ? 65 : 97 + index);
    }
    return null;
  }

  Future<void> _sendUidToWebView(String uid) async {
    if (_isProcessingScan) return;

    setState(() => _isProcessingScan = true);

    try {
      await _controller.runJavaScriptReturningResult('''
        if (window.handleHmiCardLogin) {
          window.handleHmiCardLogin('$uid');
        }
      ''');

      Future.delayed(const Duration(seconds: 2), () async {
        final url = await _controller.currentUrl();
        _checkLoginSuccess(url ?? '');
      });
    } finally {
      setState(() => _isProcessingScan = false);
    }
  }

  void _toggleLoginUrl() async {
    final url = await _controller.currentUrl() ?? _currentUrl;
    final newUrl = url.contains('/cardlogin')
        ? Constants.regularLoginUrl
        : Constants.loginUrl;

    await _controller.loadRequest(Uri.parse(newUrl));
    setState(() => _currentUrl = newUrl);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final buttonBarHeight = 56.0;
    
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Column(
          children: [
            // Fixed top bar with buttons (only show on login/cardlogin pages)
            if (_currentUrl.contains('/login') ||
                _currentUrl.contains('/cardlogin'))
              Container(
                height: buttonBarHeight,
                margin: EdgeInsets.only(top: topPadding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Back arrow button
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const LoginLandingScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      tooltip: 'Back',
                    ),
                    const Spacer(),
                    // Toggle button
                    IconButton(
                      icon: const Icon(Icons.swap_horiz),
                      onPressed: _isLoading ? null : _toggleLoginUrl,
                      tooltip: 'Toggle Login Type',
                    ),
                  ],
                ),
              ),
            // WebView below the button bar
            Expanded(
              child: Stack(
                children: [
                  KeyboardListener(
                    focusNode: _focusNode,
                    autofocus: true,
                    onKeyEvent: _handleKeyEvent,
                    child: WebViewWidget(controller: _controller),
                  ),
                  if (_isLoading)
                    Container(
                      color: Colors.white.withOpacity(0.8),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  if (_errorMessage != null)
                    Container(
                      color: Colors.white,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _errorMessage = null;
                                    _isLoading = true;
                                  });
                                  _controller.reload();
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
