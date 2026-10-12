/// Resolves to the real camera+OCR screen everywhere dart:io exists
/// (Android, iOS, Windows, macOS, Linux), and to a web-safe stub on web
/// (where dart:io and Google ML Kit don't exist at all).
library;

export 'lab_scan_screen_stub.dart' if (dart.library.io) 'lab_scan_screen.dart';
