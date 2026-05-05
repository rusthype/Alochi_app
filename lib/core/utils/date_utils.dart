/// Centralized date utilities for the A'lochi app.
/// All date formatting and calendar helpers belong here.
library;

/// Returns today's day name in Uzbek (Monday-based).
/// Example: Monday → 'Dushanba', Sunday → 'Yakshanba'
String todayUzbekDayName() {
  const days = [
    'Dushanba',
    'Seshanba',
    'Chorshanba',
    'Payshanba',
    'Juma',
    'Shanba',
    'Yakshanba',
  ];
  return days[DateTime.now().weekday - 1];
}

/// Returns today's date formatted as ISO date string (YYYY-MM-DD).
String todayIsoString() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

/// Formats any [DateTime] as ISO date string (YYYY-MM-DD).
String formatDateIso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Returns a human-readable "time ago" string in Uzbek.
String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inSeconds < 60) return '${diff.inSeconds} soniya oldin';
  if (diff.inMinutes < 60) return '${diff.inMinutes} daqiqa oldin';
  if (diff.inHours < 24) return '${diff.inHours} soat oldin';
  if (diff.inDays < 7) return '${diff.inDays} kun oldin';
  return formatDateIso(date);
}

/// Returns true if the lesson at [time] (format "HH:MM" or "HH:MM - HH:MM") is currently in progress.
/// If only start time is provided, assumes a lesson lasts 45 minutes.
bool isLessonNow(String time) {
  if (time.isEmpty) return false;
  try {
    // Handle ranges like "08:00 - 08:45"
    final rangeParts = time.split('-');
    final startTimeStr = rangeParts.first.trim();
    final endTimeStr = rangeParts.length > 1 ? rangeParts[1].trim() : '';

    final startParts = startTimeStr.split(':');
    if (startParts.length < 2) return false;
    final h = int.parse(startParts[0].trim());
    final m = int.parse(startParts[1].trim());

    final now = DateTime.now();
    final lessonStart = DateTime(now.year, now.month, now.day, h, m);
    DateTime lessonEnd;

    if (endTimeStr.isNotEmpty) {
      final endParts = endTimeStr.split(':');
      if (endParts.length >= 2) {
        final eh = int.parse(endParts[0].trim());
        final em = int.parse(endParts[1].trim());
        lessonEnd = DateTime(now.year, now.month, now.day, eh, em);
      } else {
        lessonEnd = lessonStart.add(const Duration(minutes: 45));
      }
    } else {
      lessonEnd = lessonStart.add(const Duration(minutes: 45));
    }

    return now.isAfter(lessonStart) && now.isBefore(lessonEnd);
  } catch (_) {
    return false;
  }
}
