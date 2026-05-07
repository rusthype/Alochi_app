import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../shared/widgets/alochi_skeleton.dart';
import '../../../core/models/teacher_dashboard.dart';
import '../../../core/models/lesson_model.dart';
import '../notifications/notifications_provider.dart';
import '../profile/profile_provider.dart';
import 'dashboard_provider.dart';

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(dashboardSummaryProvider.future),
          color: AppColors.brand,
          child: summaryAsync.when(
            data: (summary) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _GreetingHeader(),
                  const SizedBox(height: 6),
                  _TodayLessonsSection(lessons: summary.todayLessons),
                  const SizedBox(height: 14),
                  _ConcernsSection(concerns: summary.concerns),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
            loading: () => const _DashboardLoadingSkeleton(),
            error: (err, stack) => _ErrorState(onRetry: () => ref.invalidate(dashboardSummaryProvider)),
          ),
        ),
      ),
    );
  }
}

class _GreetingHeader extends ConsumerWidget {
  const _GreetingHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(teacherProfileProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final name = profileAsync.valueOrNull?.name.split(' ').first;
    final displayName = name != null && name.isNotEmpty ? '$name Ustoz' : 'Ustoz';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assalomu alaykum,',
                style: AppTextStyles.bodyS.copyWith(
                  color: AppColors.gray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                displayName,
                style: AppTextStyles.displayM.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => context.push('/teacher/notifications'),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F5F7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.ink,
                    size: 20,
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.brand,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayLessonsSection extends StatelessWidget {
  final List<DashboardLessonModel> lessons;

  const _TodayLessonsSection({required this.lessons});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'BUGUNGI DARSLARIM · ${lessons.length}',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray2,
                  letterSpacing: 0.5,
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/teacher/groups'),
                child: Text(
                  'Hammasi',
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.brand,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (lessons.isEmpty)
          const _EmptyLessonsPlaceholder()
        else
          SizedBox(
            height: 195,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16, right: 6),
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                if (lesson.isActive) {
                  return _ActiveLessonCard(lesson: lesson);
                }
                return _InactiveLessonCard(lesson: lesson);
              },
            ),
          ),
      ],
    );
  }
}

class _ActiveLessonCard extends StatelessWidget {
  final DashboardLessonModel lesson;

  const _ActiveLessonCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
      decoration: BoxDecoration(
        color: AppColors.heroDark,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'HOZIR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                lesson.time,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.gray2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x521F6F65),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  lesson.className,
                  style: const TextStyle(
                    color: Color(0xFFA8D5CD),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  lesson.subject,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${lesson.studentCount} o\'quvchi${lesson.topic.isNotEmpty ? ' · ${lesson.topic}' : ''}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.gray2,
              fontSize: 12,
              height: 1.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),

          GestureDetector(
            onTap: () {
              final lessonModel = LessonModel(
                id: lesson.id,
                groupId: lesson.groupId,
                groupName: lesson.className,
                subject: lesson.subject,
                startTime: lesson.time.split('-').first.trim(),
                endTime: lesson.time.contains('-') 
                    ? lesson.time.split('-').last.trim() 
                    : '',
                room: '',
                isNow: lesson.isActive,
                studentsCount: lesson.studentCount,
              );
              context.push('/teacher/lessons/${lesson.id}', extra: lessonModel);
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                    spreadRadius: -4,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text(
                'Darsni ochish ›',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InactiveLessonCard extends StatelessWidget {
  final DashboardLessonModel lesson;

  const _InactiveLessonCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lesson.time,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.gray2,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2EF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  lesson.className,
                  style: const TextStyle(
                    color: AppColors.brand,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  lesson.subject,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${lesson.studentCount} o\'quvchi${lesson.timeStatus.isNotEmpty ? ' · ${lesson.timeStatus}' : ''}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.gray,
              fontSize: 12,
              height: 1.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),

          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.lineSoft,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: const Text(
              'Tayyorlanish',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConcernsSection extends StatelessWidget {
  final List<ConcernModel> concerns;

  const _ConcernsSection({required this.concerns});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'DIQQAT TALAB',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray2,
                  letterSpacing: 0.5,
                ),
              ),
              GestureDetector(
                onTap: () {}, // All concerns
                child: Text(
                  'Hammasi',
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.brand,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: concerns.map((concern) => _ConcernItem(concern: concern)).toList(),
          ),
        ),
      ],
    );
  }
}

class _ConcernItem extends StatelessWidget {
  final ConcernModel concern;

  const _ConcernItem({required this.concern});

  @override
  Widget build(BuildContext context) {
    Color iconBg;
    Color iconColor;
    String iconText;
    String subtitle;

    switch (concern.type) {
      case 'homework':
        iconBg = const Color(0xFFFCEBEB);
        iconColor = AppColors.danger;
        iconText = '!';
        subtitle = 'Vazifa muddati o\'tdi · ${concern.count} ta qoldi';
        break;
      case 'messages':
        iconBg = const Color(0xFFE8F2EF);
        iconColor = AppColors.brand;
        iconText = concern.count;
        subtitle = 'Yangi xabarlar kelgan';
        break;
      case 'telegram':
        iconBg = const Color(0xFFFAEEDA);
        iconColor = AppColors.warning;
        iconText = '!';
        subtitle = 'Telegram ulanmagan ota-onalar';
        break;
      default:
        iconBg = const Color(0xFFF4F5F7);
        iconColor = const Color(0xFF6B7280);
        iconText = '?';
        subtitle = concern.title;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11).copyWith(right: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              iconText,
              style: TextStyle(
                color: iconColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  concern.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          const Text(
            '›',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLessonsPlaceholder extends StatelessWidget {
  const _EmptyLessonsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.calendar_today_outlined, color: Color(0xFFD1D5DB), size: 32),
            const SizedBox(height: 12),
            Text(
              'Bugun darsingiz yo\'q',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.gray,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Eski guruhlarni ko\'rish',
              style: AppTextStyles.label.copyWith(color: AppColors.brand),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 16),
          const Text('Yuklab bo\'lmadi', style: AppTextStyles.titleM),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
            ),
            child: const Text('Qayta urinish'),
          ),
        ],
      ),
    );
  }
}

class _DashboardLoadingSkeleton extends StatelessWidget {
  const _DashboardLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      children: [
        const AlochiSkeleton(width: 120, height: 16),
        const SizedBox(height: 8),
        const AlochiSkeleton(width: 180, height: 28),
        const SizedBox(height: 32),
        const AlochiSkeleton(width: 140, height: 14),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 2,
            itemBuilder: (_, __) => const Padding(
              padding: EdgeInsets.only(right: 12),
              child: AlochiSkeleton(width: 220, height: 190),
            ),
          ),
        ),
        const SizedBox(height: 32),
        const AlochiSkeleton(width: 120, height: 14),
        const SizedBox(height: 12),
        const AlochiSkeleton(height: 60),
        const SizedBox(height: 8),
        const AlochiSkeleton(height: 60),
      ],
    );
  }
}


