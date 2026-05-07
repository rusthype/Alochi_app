import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../groups/groups_provider.dart';

class BirthdayStudentModel {
  final String id;
  final String name;
  final String groupName;
  final String birthday;
  final bool isToday;

  const BirthdayStudentModel({
    required this.id,
    required this.name,
    required this.groupName,
    required this.birthday,
    required this.isToday,
  });
}

final birthdayStudentsProvider =
    FutureProvider.autoDispose<List<BirthdayStudentModel>>((ref) async {
  final groups = await ref.watch(groupsListProvider.future);
  final now = DateTime.now();
  final results = <BirthdayStudentModel>[];

  for (final group in groups) {
    final students = await ref.watch(groupStudentsProvider(group.id).future);
    for (final student in students) {
      if (student.birthday == null || student.birthday!.isEmpty) continue;
      final bd = _parseBirthday(student.birthday!);
      if (bd == null) continue;
      final thisYearBd = DateTime(now.year, bd.month, bd.day);
      final diff = thisYearBd.difference(now).inDays;
      if (diff >= 0 && diff <= 7) {
        results.add(BirthdayStudentModel(
          id: student.id,
          name: student.fullName,
          groupName: '${group.code} · ${group.subjectName}',
          birthday: student.birthday!,
          isToday: diff == 0,
        ));
      }
    }
  }

  results.sort((a, b) => (a.isToday ? 0 : 1).compareTo(b.isToday ? 0 : 1));
  return results;
});

DateTime? _parseBirthday(String raw) {
  try {
    final parts = raw.split('-');
    if (parts.length < 3) return null;
    return DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  } catch (_) {
    return null;
  }
}

String birthdayDaysLabel(String birthday) {
  try {
    final now = DateTime.now();
    final bd = _parseBirthday(birthday)!;
    final diff = DateTime(now.year, bd.month, bd.day).difference(now).inDays;
    if (diff == 0) return 'Bugun!';
    if (diff == 1) return 'Erta';
    return '$diff kundan keyin';
  } catch (_) {
    return '';
  }
}
