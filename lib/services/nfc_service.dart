import 'package:nfc_manager/nfc_manager.dart';

/// Service for handling NFC/RFID operations
class NfcService {
  /// Check if NFC is available on the device
  static Future<bool> isAvailable() async {
    return await NfcManager.instance.isAvailable();
  }

  /// Start NFC tag reading
  /// Returns the UID of the scanned card, or null if cancelled/failed
  static Future<String?> readCardUid() async {
    try {
      String? cardUid;

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          // Extract UID from the tag
          // The UID is typically in the 'nfca' or 'nfcb' handle
          if (tag.data.containsKey('nfca')) {
            final nfca = tag.data['nfca'] as Map?;
            if (nfca != null && nfca.containsKey('identifier')) {
              final identifier = nfca['identifier'] as List<int>?;
              if (identifier != null) {
                // Convert bytes to hex string
                cardUid = identifier.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('').toUpperCase();
              }
            }
          } else if (tag.data.containsKey('nfcb')) {
            final nfcb = tag.data['nfcb'] as Map?;
            if (nfcb != null && nfcb.containsKey('identifier')) {
              final identifier = nfcb['identifier'] as List<int>?;
              if (identifier != null) {
                cardUid = identifier.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('').toUpperCase();
              }
            }
          } else if (tag.data.containsKey('nfcf')) {
            final nfcf = tag.data['nfcf'] as Map?;
            if (nfcf != null && nfcf.containsKey('identifier')) {
              final identifier = nfcf['identifier'] as List<int>?;
              if (identifier != null) {
                cardUid = identifier.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('').toUpperCase();
              }
            }
          } else if (tag.data.containsKey('nfcv')) {
            final nfcv = tag.data['nfcv'] as Map?;
            if (nfcv != null && nfcv.containsKey('identifier')) {
              final identifier = nfcv['identifier'] as List<int>?;
              if (identifier != null) {
                cardUid = identifier.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('').toUpperCase();
              }
            }
          }

          // Stop session after reading
          await NfcManager.instance.stopSession();
        },
      );

      return cardUid;
    } catch (e) {
      print('Error reading NFC card: $e');
      return null;
    }
  }

  /// Stop NFC session
  static Future<void> stopSession() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (e) {
      print('Error stopping NFC session: $e');
    }
  }
}

