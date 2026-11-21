import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/doctor.dart';

/// The patient's booked appointment. Having one means the patient is now
/// "following with a doctor", which unlocks Doctor / Medicine / Report /
/// Emergency on Home. Stored on this device only (a prototype: no doctor-side
/// confirmation exists yet).
class Appointment {
  final String doctorId;
  final DateTime date;
  final String time;
  final bool shareResults;
  final String patientName;
  final String patientEmail;

  const Appointment({
    required this.doctorId,
    required this.date,
    required this.time,
    required this.shareResults,
    this.patientName = '',
    this.patientEmail = '',
  });

  Doctor get doctor => doctorById(doctorId);

  Map<String, dynamic> toJson() => {
    'doctorId': doctorId,
    'date': date.toIso8601String(),
    'time': time,
    'shareResults': shareResults,
    'patientName': patientName,
    'patientEmail': patientEmail,
  };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    doctorId: json['doctorId'] as String,
    date: DateTime.parse(json['date'] as String),
    time: json['time'] as String,
    shareResults: json['shareResults'] as bool? ?? true,
    patientName: json['patientName'] as String? ?? '',
    patientEmail: json['patientEmail'] as String? ?? '',
  );
}

/// "10:30" -> "10:30 AM", "14:00" -> "2:00 PM".
String formatSlotTime(String hhmm) {
  final parts = hhmm.split(':');
  final hour = int.tryParse(parts.first) ?? 0;
  final minute = parts.length > 1 ? parts[1] : '00';
  final suffix = hour >= 12 ? 'PM' : 'AM';
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  return '$h12:$minute $suffix';
}

class AppointmentProvider extends ChangeNotifier {
  static const _key = 'shifai_appointment';

  Appointment? _appointment;
  bool _loading = true;

  AppointmentProvider() {
    _load();
  }

  Appointment? get appointment => _appointment;
  bool get followingDoctor => _appointment != null;
  bool get loading => _loading;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        _appointment = Appointment.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (_) {
        _appointment = null;
      }
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> book(Appointment appointment) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(appointment.toJson()));
    _appointment = appointment;
    notifyListeners();
  }

  Future<void> cancel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _appointment = null;
    notifyListeners();
  }
}
