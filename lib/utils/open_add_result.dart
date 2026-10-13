import 'package:flutter/material.dart';
import '../screens/lab_entry_form_screen.dart';
import '../screens/lab_scan_entry.dart';
import 'platform_helper.dart';

/// Photo scan on Android/iOS, manual entry everywhere else.
void openAddResult(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) =>
        isMobilePlatform ? const LabScanScreen() : const LabEntryFormScreen(),
  ));
}
