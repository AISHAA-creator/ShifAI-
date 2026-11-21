/// Real camera + OCR screen where dart:io exists (Android, iOS, desktop), and a
/// web-safe stub on web, where Google ML Kit does not exist.
library;

export 'prescription_scan_screen_stub.dart'
    if (dart.library.io) 'prescription_scan_screen.dart';
