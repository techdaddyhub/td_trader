// Native IO storage for persisting PC Server URL across Android & Desktop restarts.
import 'dart:io';

File _resolveConfigFile() {
  if (Platform.isAndroid) {
    final appDir = Directory('/data/data/com.techdaddy.td_trader/files');
    if (appDir.existsSync()) {
      return File('${appDir.path}/td_server_url.txt');
    }
  }
  final home = Platform.environment['HOME'] ??
      Platform.environment['USERPROFILE'] ??
      Directory.systemTemp.path;
  return File('$home/.td_trader_server_url.txt');
}

Future<void> saveServerUrl(String url) async {
  try {
    final file = _resolveConfigFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(url, flush: true);
  } catch (_) {
    // Graceful fallback if filesystem path is restricted
  }
}

Future<String?> loadServerUrl() async {
  try {
    final file = _resolveConfigFile();
    if (await file.exists()) {
      final text = (await file.readAsString()).trim();
      if (text.isNotEmpty) return text;
    }
  } catch (_) {}
  return null;
}
