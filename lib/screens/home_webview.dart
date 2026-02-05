import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/constants.dart';
import '../services/api_service.dart';

/// Home screen with WebView showing order list
class HomeWebViewScreen extends StatefulWidget {
  const HomeWebViewScreen({super.key});

  @override
  State<HomeWebViewScreen> createState() => _HomeWebViewScreenState();
}

class _HomeWebViewScreenState extends State<HomeWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(true)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('[HomeWebView] 📄 Page started loading: $url');
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          },
          onPageFinished: (String url) {
            print('[HomeWebView] ✅ Page finished loading: $url');
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('[HomeWebView] ❌ Web resource error: ${error.description} (${error.errorCode})');
            setState(() {
              _isLoading = false;
              _errorMessage = 'Error loading page: ${error.description}';
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            print('[HomeWebView] 🔄 Navigation request: ${request.url}');
            // Keep navigation inside the WebView
            return NavigationDecision.navigate;
          },
        ),
      );

    // Attach session cookie (if any) to WebView cookie store, then load order list
    final sessionCookie = await ApiService.getSessionCookie();
    final uri = Uri.parse(Constants.orderListUrl);

    if (sessionCookie != null && sessionCookie.isNotEmpty) {
      // sessionCookie is in form "name=value"
      final parts = sessionCookie.split('=');
      final cookieName = parts.isNotEmpty ? parts[0].trim() : '';
      final cookieValue = parts.length > 1 ? parts[1].trim() : '';

      if (cookieName.isNotEmpty && cookieValue.isNotEmpty) {
        // Set cookie into WebView's CookieManager so it is sent with all requests
        final cookieManager = WebViewCookieManager();
        await cookieManager.setCookie(
          WebViewCookie(
            name: cookieName,
            value: cookieValue,
            domain: uri.host,
            path: '/',
          ),
        );
      }
    }

    // Now load the order list URL (cookie will be sent automatically if set)
    await _controller.loadRequest(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller.reload();
            },
            tooltip: 'Refresh',
          ),
        ],
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
        ],
      ),
    );
  }
}

