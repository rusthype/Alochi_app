import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alochi_app/app/app.dart';
import 'package:alochi_app/core/models/homework_model.dart';
import 'package:alochi_app/shared/widgets/alochi_button.dart';
import 'package:alochi_app/shared/widgets/alochi_avatar.dart';
import 'package:alochi_app/shared/widgets/alochi_pill.dart';
import 'package:alochi_app/theme/colors.dart';

void main() {
  group('App smoke test', () {
    testWidgets('App builds without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: AlochiApp()));
      expect(find.byType(ProviderScope), findsOneWidget);
    });
  });

  group('HomeworkModel', () {
    test('fromJson reads due_date correctly', () {
      final json = {
        'id': 'abc',
        'title': 'Test',
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
    });

    test('HomeworkSubmission maps status correctly', () {
      final submitted = HomeworkSubmission.fromJson({
        'student_id': 's1',
        'name': 'Ali Valiyev',
        'initials': 'AV',
        'color': '#1F6F65',
        'status': 'submitted',
        'submitted_at': '2026-05-07T10:00:00Z',
        'file_url': null,
      });
      expect(submitted.hasSubmitted, isTrue);
      expect(submitted.isOnTime, isTrue);
      expect(submitted.isPending, isFalse);

      final pending = HomeworkSubmission.fromJson({
        'student_id': 's2',
        'name': 'Zulfiya Karimova',
        'initials': 'ZK',
        'color': '#6366F1',
        'status': 'pending',
        'submitted_at': null,
        'file_url': null,
      });
      expect(pending.hasSubmitted, isFalse);
      expect(pending.isPending, isTrue);
    });
  });

  group('Widget tests', () {
    testWidgets('AlochiAvatar shows initials', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AlochiAvatar(name: 'Shoiraxon Yusupova', size: 40),
          ),
        ),
      );
      expect(find.text('SY'), findsOneWidget);
    });

    testWidgets('AlochiButton primary renders', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlochiButton.primary(
              label: 'Saqlash',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );
      expect(find.text('Saqlash'), findsOneWidget);
      await tester.tap(find.text('Saqlash'));
      expect(tapped, isTrue);
    });

    testWidgets('AlochiPill success variant renders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AlochiPill(
              label: 'Aktiv',
              variant: AlochiPillVariant.success,
            ),
          ),
        ),
      );
      expect(find.text('Aktiv'), findsOneWidget);
    });

    testWidgets('AlochiButton disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlochiButton.primary(
              label: 'Saqla',
              onPressed: null,
            ),
          ),
        ),
      );
      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(btn.onPressed, isNull);
    });
  });

  group('AppColors sanity', () {
    test('brand color is teal', () {
      expect(AppColors.brand.toARGB32(), equals(const Color(0xFF1F6F65).toARGB32()));
    });
  });
}
