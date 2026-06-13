import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class CertificatePinningHttpOverrides extends HttpOverrides {
  CertificatePinningHttpOverrides({required this.expectedPinSha256});

  final String expectedPinSha256;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (cert, host, port) {
      if (kDebugMode || expectedPinSha256.isEmpty) {
        return false;
      }

      final fingerprint = sha256.convert(cert.der).toString();
      return fingerprint == expectedPinSha256.toLowerCase();
    };
    return client;
  }
}
