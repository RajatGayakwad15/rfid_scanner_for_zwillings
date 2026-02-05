import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

/// Zwilling logo: shows image if asset exists, otherwise text fallback.
class ZwillingLogo extends StatelessWidget {
  const ZwillingLogo({super.key, this.height = 80});

  final double height;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: rootBundle
          .load(Constants.zwillingLogoAsset)
          .then((_) => true)
          .catchError((_) => false),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return Image.asset(
            Constants.zwillingLogoAsset,
            height: height,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _textFallback(),
          );
        }
        return _textFallback();
      },
    );
  }

  Widget _textFallback() => Text(
        'Zwilling Labs',
        style: TextStyle(
          fontSize: height * 0.3,
          fontWeight: FontWeight.bold,
        ),
      );
}
