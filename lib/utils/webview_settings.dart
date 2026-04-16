import 'dart:io';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// Applies Android WebView settings equivalent to:
/// - setUseWideViewPort(true)
/// - setLoadWithOverviewMode(false)
/// - setBuiltInZoomControls(false), setDisplayZoomControls(false), setSupportZoom(false)
/// - setTextZoom(100)
Future<void> applyAndroidWebViewSettings(WebViewController controller) async {
  if (!Platform.isAndroid) return;

  // Disable zoom (built-in controls, display controls, support zoom)
  await controller.enableZoom(false);

  final platform = controller.platform;
  if (platform is! AndroidWebViewController) return;

  await platform.setUseWideViewPort(true);
  await platform.setTextZoom(100);
  // setLoadWithOverviewMode(false) is not exposed by webview_flutter_android;
  // plugin defaults may apply. Other settings above are applied.
}
