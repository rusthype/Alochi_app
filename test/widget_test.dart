import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alochi_app/core/models/homework_model.dart';
import 'package:alochi_app/shared/widgets/alochi_button.dart';
import 'package:alochi_app/shared/widgets/alochi_avatar.dart';
import 'package:alochi_app/shared/widgets/alochi_pill.dart';
import 'package:alochi_app/theme/colors.dart';
import 'package:alochi_app/theme/theme.dart';

void main() {
  group('HomeworkModel unit tests', () {
    test('fromJson reads due_date correctly', () {
      final json = {
        'id': 'abc',
        'title': 'Test vazifa',
        'description': '',
        'subject': 'Matematika',
        'class_name': '2-guruh',
        'due_date': '2026-12-31',
        'status': 'active',
        'submitted_count': 3,
        'total_count': 10,
        'submissions': [],
        'is_panel': true,
      };
      final hw = HomeworkModel.fromJson(json);
      expect(hw.deadline, equals('2026-12-31'));
      expect(hw.totalCount, equals(10));
      expect(hw.submittedCount, equals(3));
      expect(hw.isActive, isTrue);
      expect(hw.groupName, equals('2-guruh'));
    });

    test('HomeworkModel isActive false when deadline passed', () {
      final json = {
        'id': 'abc',
        'title': 'Eski vazifa',
        'description': '',
        'subject': 'Matematika',
        'class_name': '2-guruh',
        'due_date': '2020-01-01',
        'submitted_count': 0,
        'total_count': 5,
        'submissions': [],
      };
      final hw = HomeworkModel.fromJson(json);
      expect(hw.isActive, isFalse);
    });

    test('HomeworkSubmission submitted status', () {
      final sub = HomeworkSubmission.fromJson({
        'student_id': 's1',
        'name': 'Ali Valiyev',
        'initials': 'AV',
        'color': '#1F6F65',
        'status': 'submitted',
        'submitted_at': '2026-05-07T10:00:00Z',
        'file_url': null,
      });
      expect(sub.hasSubmitted, isTrue);
      expect(sub.isOnTime, isTrue);
      expect(sub.isPending, isFalse);
      expect(sub.studentName, equals('Ali Valiyev'));
    });

    test('HomeworkSubmission pending status', () {
      final sub = HomeworkSubmission.fromJson({
        'student_id': 's2',
        'name': 'Zulfiya Karimova',
        'initials': 'ZK',
        'color': '#6366F1',
        'status': 'pending',
        'submitted_at': null,
        'file_url': null,
      });
      expect(sub.hasSubmitted, isFalse);
      expect(sub.isPending, isTrue);
      expect(sub.isOnTime, isFalse);
    });

    test('HomeworkSubmission late status', () {
      final sub = HomeworkSubmission.fromJson({
        'student_id': 's3',
        'name': 'Bobur Toshmatov',
        'initials': 'BT',
        'color': '#EF4444',
        'status': 'late',
        'submitted_at': '2026-05-08T08:00:00Z',
        'file_url': null,
      });
      expect(sub.hasSubmitted, isTrue);
      expect(sub.isOnTime, isFalse);
      expect(sub.isPending, isFalse);
    });
  });

  group('AppColors', () {
    test('brand color is teal', () {
      expect(
        AppColors.brand.toARGB32(),
        equals(const Color(0xFF1F6F65).toARGB32()),
      );
    });

    test('danger color is DC2626', () {
      expect(AppColors.danger.toARGB32(),
          equals(const Color(0xFFDC2626).toARGB32()));
    });

    test('success color is 0F9A6E', () {
      expect(AppColors.success.toARGB32(),
          equals(const Color(0xFF0F9A6E).toARGB32()));
    });
  });

  group('Widget tests', () {
    Widget themed(Widget child) => MaterialApp(
          theme: AlochiTheme.light,
          home: Scaffold(body: Center(child: child)),
        );

    testWidgets('AlochiAvatar 2-letter initials', (tester) async {
      await tester.pumpWidget(themed(
        const AlochiAvatar(name: 'Shoiraxon Yusupova', size: 40),
      ));
      expect(find.text('SY'), findsOneWidget);
    });

    testWidgets('AlochiAvatar single name', (tester) async {
      await tester.pumpWidget(themed(
        const AlochiAvatar(name: 'Alibek', size: 40),
      ));
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('AlochiButton primary callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(themed(
        AlochiButton.primary(
          label: 'Saqlash',
          onPressed: () => tapped = true,
        ),
      ));
      expect(find.text('Saqlash'), findsOneWidget);
      await tester.tap(find.text('Saqlash'));
      expect(tapped, isTrue);
    });

    testWidgets('AlochiButton null onPressed renders', (tester) async {
      await tester.pumpWidget(themed(
        AlochiButton.primary(label: 'Saqla', onPressed: null),
      ));
      expect(find.text('Saqla'), findsOneWidget);
    });

    testWidgets('AlochiPill success label', (tester) async {
      await tester.pumpWidget(themed(
        const AlochiPill(label: 'Aktiv', variant: AlochiPillVariant.success),
      ));
      expect(find.text('Aktiv'), findsOneWidget);
    });

    testWidgets('AlochiPill danger label', (tester) async {
      await tester.pumpWidget(themed(
        const AlochiPill(label: 'Xato', variant: AlochiPillVariant.danger),
      ));
      expect(find.text('Xato'), findsOneWidget);
    });
  });
}
