import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/lab_record.dart';

/// Opens WhatsApp with a short text summary of [latest]. Nothing is sent
/// unless the user presses send in WhatsApp.
Future<void> shareSummaryOnWhatsApp(
  BuildContext context,
  LabRecord latest,
) async {
  final text = StringBuffer('My ShifAI summary\n');
  if (latest.homaIr != null) {
    text.writeln(
      'HOMA-IR: ${latest.homaIr!.toStringAsFixed(2)} '
      '(${latest.homaIrBand!.label}) on ${DateFormat.yMMMd().format(latest.date)}',
    );
  } else {
    text.writeln('Result from ${DateFormat.yMMMd().format(latest.date)}');
  }
  if (latest.fastingGlucoseMgdl != null) {
    text.writeln(
      'Fasting glucose: ${latest.fastingGlucoseMgdl!.toStringAsFixed(0)} mg/dL',
    );
  }
  if (latest.fastingInsulinUiuml != null) {
    text.writeln(
      'Fasting insulin: ${latest.fastingInsulinUiuml!.toStringAsFixed(1)} µIU/mL',
    );
  }
  if (latest.hba1cPercent != null) {
    text.writeln('HbA1c: ${latest.hba1cPercent!.toStringAsFixed(1)}%');
  }
  text.write('Screening tool only, not medical advice.');

  final uri = Uri.parse(
    'https://wa.me/?text=${Uri.encodeComponent(text.toString())}',
  );
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on PlatformException {
    opened = false;
  } on MissingPluginException {
    opened = false;
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Couldn't open WhatsApp on this device.")),
    );
  }
}
