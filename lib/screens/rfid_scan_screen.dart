import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/nfc_service.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'home_webview.dart';

/// RFID card scanning screen
class RfidScanScreen extends StatefulWidget {
  const RfidScanScreen({super.key});

  @override
  State<RfidScanScreen> createState() => _RfidScanScreenState();
}

class _RfidScanScreenState extends State<RfidScanScreen> {
  bool _isScanning = false;
  bool _isProcessing = false;
  String? _statusMessage;
  bool _nfcAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
  }

  Future<void> _checkNfcAvailability() async {
    final available = await NfcService.isAvailable();
    setState(() {
      _nfcAvailable = available;
      if (!available) {
        _statusMessage = 'NFC is not available on this device';
      }
    });
  }

  Future<void> _startScanning() async {
    if (!_nfcAvailable) {
      _showError('NFC is not available on this device');
      return;
    }

    setState(() {
      _isScanning = true;
      _isProcessing = false;
      _statusMessage = 'Please tap your RFID card...';
    });

    try {
      // Read card UID
      final cardUid = await NfcService.readCardUid();

      if (cardUid == null || cardUid.isEmpty) {
        setState(() {
          _isScanning = false;
          _statusMessage = 'No card detected or scan cancelled';
        });
        return;
      }

      setState(() {
        _isScanning = false;
        _isProcessing = true;
        _statusMessage = 'Processing card login...';
      });

      // Call API to login with card UID
      final response = await ApiService.cardLogin(cardUid);

      if (response != null) {
        // Log full response so you can see it in Logcat / `flutter run`
        print('[RFID] cardLogin response: $response');

        // You asked to always go to /orderlist when the API returns 200,
        // so as long as we have a response (non-null) we navigate.
        final success = response['success'] as bool? ?? false;
        if (!success) {
          print(
              '[RFID] WARNING: API returned success=false but navigating to /orderlist because HTTP status was OK.');
        }

        // Store token if present
        if (response.containsKey('token')) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              Constants.tokenKey, response['token'].toString());
        }

        // Store user data if present
        if (response.containsKey('user')) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(response['user']));
        }

        // Store card UID
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(Constants.cardUidKey, cardUid);

        // Navigate directly to Order List screen
        if (mounted) {
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
          _statusMessage = 'Login failed. Please try again.';
        });
        _showError('Card login failed. Please check your connection and try again.');
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
        _isProcessing = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
      _showError('Error during scan: $e');
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
    // Stop NFC session when leaving the screen
    NfcService.stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan RFID Card'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.credit_card,
                size: 120,
                color: _nfcAvailable ? Colors.blue : Colors.grey,
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
              const SizedBox(height: 32),
              if (_isScanning || _isProcessing)
                const CircularProgressIndicator(),
              if (!_isScanning && !_isProcessing && _nfcAvailable)
                ElevatedButton.icon(
                  onPressed: _startScanning,
                  icon: const Icon(Icons.nfc),
                  label: const Text('Start Scanning'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              if (!_nfcAvailable)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'NFC is not available on this device.\nPlease use the web login instead.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

