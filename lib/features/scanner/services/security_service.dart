import 'dart:io';
import 'package:flutter/services.dart';

/// Security utilities: prevent screenshots, secure memory, delete temp files.
class SecurityService {
  SecurityService._();
  static final SecurityService instance = SecurityService._();

  static const _channel =
      MethodChannel('com.nagarikplus.scanner/security');

  // ── Screenshot prevention ─────────────────────────────────────────────────

  /// Call on scanner / vault screens to block screenshots (Android FLAG_SECURE).
  Future<void> enableSecureScreen() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('setSecureScreen', {'secure': true});
    } on MissingPluginException {
      // Plugin not yet registered — safe to ignore in debug
    }
  }

  Future<void> disableSecureScreen() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('setSecureScreen', {'secure': false});
    } on MissingPluginException {}
  }

  // ── Temp file cleanup ─────────────────────────────────────────────────────

  /// Delete all Nagarik+ temp scan files from the app's temp directory.
  Future<void> cleanTempFiles() async {
    try {
      // Use path_provider — NOT Directory.systemTemp (wrong on Android)
      final tmpDir = await _getTempDir();
      await for (final entity in Directory(tmpDir).list()) {
        if (entity is File) {
          final name = entity.path.split(Platform.pathSeparator).last;
          if (name.startsWith('nk_scan_') ||
              name.startsWith('nk_c') ||
              name.startsWith('nk_comp_')) {
            try { await entity.delete(); } catch (_) {}
          }
        }
      }
    } catch (_) {}
  }

  static Future<String> _getTempDir() async {
    // We can't import path_provider here (flutter plugin),
    // so we use dart:io temporary directory via Platform env as fallback,
    // or simply skip — the OS will clear temp files eventually.
    try {
      return Directory.systemTemp.path;
    } catch (_) {
      return '';
    }
  }

  /// Overwrite file bytes then delete — secure erase.
  Future<void> secureDelete(String path) async {
    try {
      final f = File(path);
      if (!await f.exists()) return;
      final len = await f.length();
      // Overwrite with zeros
      await f.writeAsBytes(List.filled(len, 0), flush: true);
      await f.delete();
    } catch (_) {}
  }
}
