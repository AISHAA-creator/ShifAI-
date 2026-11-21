import 'package:intl/intl.dart';

import '../models/lab_record.dart';
import '../providers/appointment_provider.dart';
import '../providers/medicine_provider.dart';
import '../models/wellness_content.dart';

enum NoticeKind { appointment, medicine, lab, doctor, activity }

/// One entry of the notification list. Built from what is in the app (no
/// server, no push): the id changes when the situation changes, so a new
/// situation shows up as unread again.
class AppNotice {
  final String id;
  final NoticeKind kind;
  final String title;
  final String body;

  const AppNotice({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
  });
}

List<AppNotice> buildNotices({
  required List<LabRecord> records,
  required Appointment? appointment,
  required List<Medicine> medicines,
  required bool medicineReminders,
  required int weekMinutes,
  required DateTime now,
}) {
  final out = <AppNotice>[];
  final day = Medicine.dayKey(now);

  if (appointment != null) {
    out.add(
      AppNotice(
        id: 'appt-${appointment.date.toIso8601String()}-${appointment.time}',
        kind: NoticeKind.appointment,
        title: 'Appointment with ${appointment.doctor.name}',
        body:
            '${DateFormat('d MMM').format(appointment.date)} at '
            '${formatSlotTime(appointment.time)}',
      ),
    );
  }

  if (medicineReminders) {
    final minutesNow = now.hour * 60 + now.minute;
    for (final m in medicines) {
      final parts = m.time.split(':');
      final due =
          (int.tryParse(parts.first) ?? 0) * 60 +
          (int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0);
      if (!m.takenToday(now) && due <= minutesNow) {
        out.add(
          AppNotice(
            id: 'med-${m.id}-$day',
            kind: NoticeKind.medicine,
            title: '${m.name} is due',
            body: [
              m.dose,
              'planned at ${m.time}',
            ].where((s) => s.isNotEmpty).join(', '),
          ),
        );
      }
    }
  }

  if (records.isEmpty) {
    out.add(
      const AppNotice(
        id: 'first-scan',
        kind: NoticeKind.lab,
        title: 'Scan your first lab report',
        body: 'It takes a minute and gives you your first score.',
      ),
    );
  } else {
    final last = records.last;
    final age = now.difference(last.date).inDays;
    if (age > 90) {
      out.add(
        AppNotice(
          id: 'lab-${last.id}',
          kind: NoticeKind.lab,
          title: 'Time for a new lab test',
          body: 'Your last result is $age days old.',
        ),
      );
    }
    if (last.homaIrBand == HomaIrBand.significantResistance &&
        appointment == null) {
      out.add(
        AppNotice(
          id: 'doctor-${last.id}',
          kind: NoticeKind.doctor,
          title: 'Your latest result is high',
          body: 'Talking to a doctor is a good next step.',
        ),
      );
    }
  }

  if (weekMinutes < weeklyGoalMinutes && now.weekday >= DateTime.thursday) {
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    out.add(
      AppNotice(
        id: 'move-${Medicine.dayKey(monday)}',
        kind: NoticeKind.activity,
        title: '$weekMinutes of $weeklyGoalMinutes minutes this week',
        body: 'A 10-minute walk after a meal helps.',
      ),
    );
  }
  return out;
}
