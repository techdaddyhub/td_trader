// TD TRADER - Unified Cross-Platform Direct Deriv Token Verifier
// Copyright (c) 2026 TechDaddy. All rights reserved.

import 'deriv_verifier_stub.dart'
    if (dart.library.io) 'deriv_verifier_io.dart'
    if (dart.library.html) 'deriv_verifier_web.dart';

class DerivDirectVerifier {
  static Future<Map<String, dynamic>> verifyDirect(
    String apiToken, {
    String appId = '1089',
  }) {
    return directVerifyDerivToken(apiToken, appId: appId);
  }
}
