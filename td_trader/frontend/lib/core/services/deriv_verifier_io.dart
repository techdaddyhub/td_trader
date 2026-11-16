// TD TRADER - IO (Android / iOS / Desktop) Direct Deriv WebSocket Token Verification
// Copyright (c) 2026 TechDaddy. All rights reserved.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<Map<String, dynamic>> directVerifyDerivToken(
  String apiToken, {
  String appId = '1089',
}) async {
  final cleanAppId = appId.replaceAll(RegExp(r'[^0-9]'), '').isEmpty
      ? '1089'
      : appId.replaceAll(RegExp(r'[^0-9]'), '');

  final endpoints = [
    'wss://ws.derivws.com/websockets/v3?app_id=$cleanAppId&l=EN&brand=deriv',
    'wss://blue.derivws.com/websockets/v3?app_id=$cleanAppId&l=EN&brand=deriv',
    'wss://green.derivws.com/websockets/v3?app_id=$cleanAppId&l=EN&brand=deriv',
  ];

  dynamic lastErr;

  for (final url in endpoints) {
    WebSocket? ws;
    try {
      ws = await WebSocket.connect(
        url,
        headers: {
          'Origin': 'https://app.deriv.com',
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
        },
      ).timeout(const Duration(seconds: 8));

      ws.add(jsonEncode({'authorize': apiToken.trim()}));

      final raw = await ws.first.timeout(const Duration(seconds: 8));
      await ws.close();

      final decoded = jsonDecode(raw.toString());
      if (decoded is! Map<String, dynamic>) {
        continue;
      }

      if (decoded.containsKey('error')) {
        final err = decoded['error'] as Map<String, dynamic>? ?? {};
        final code = err['code']?.toString() ?? 'AUTH';
        final message = err['message']?.toString() ?? 'Invalid Deriv token';
        throw Exception('$code: $message');
      }

      final auth = decoded['authorize'] as Map<String, dynamic>? ?? {};
      final isVirtual =
          (auth['is_virtual'] == 1 || auth['is_virtual'] == true);
      final loginid = auth['loginid']?.toString() ?? '';
      final balance = (auth['balance'] is num)
          ? (auth['balance'] as num).toDouble()
          : 0.0;
      final currency = auth['currency']?.toString() ?? 'USD';

      return {
        'verified': true,
        'loginid': loginid,
        'is_virtual': isVirtual,
        'recommended_platform':
            isVirtual ? 'DERIV_API_DEMO' : 'DERIV_API_LIVE',
        'balance': balance,
        'currency': currency,
        'email': auth['email']?.toString() ?? '',
        'fullname': auth['fullname']?.toString() ?? '',
        'app_id': cleanAppId,
        'server': 'ws.derivws.com (AppID: $cleanAppId)',
      };
    } catch (e) {
      lastErr = e;
      final errStr = e.toString();
      if (errStr.contains('InvalidToken') ||
          errStr.contains('InputValidationFailed') ||
          errStr.contains('AuthorizationRequired')) {
        rethrow;
      }
    } finally {
      try {
        await ws?.close();
      } catch (_) {}
    }
  }

  throw Exception(
      'Deriv verification unavailable: ${lastErr ?? "Connection failed"}. Please verify your API token.');
}
