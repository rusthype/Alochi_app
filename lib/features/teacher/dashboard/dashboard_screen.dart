import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import '../../../shared/widgets/alochi_card.dart';
import '../../../shared/widgets/alochi_pill.dart';
import '../../../shared/widgets/alochi_skeleton.dart';
import '../../../core/models/teacher_dashboard.dart';
import '../notifications/notifications_provider.dart';
import '../profile/profile_provider.dart';
import 'dashboard_provider.dart';

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(dashboardSummaryProvider.future),
          color: AppColors.brand,
          child: summaryAsync.when(
            data: (summary) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GreetingHeader(
                    todayLessonsCount: summary.todayLessons.length,
                  ),
                  if (summary.todayLessons.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    _TodayLessonsHorizontalList(lessons: summary.todayLessons),
                  ],
                  if (summary.concerns.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    _ConcernsSection(concerns: summary.concerns),
                  ],
                  if (summary.todayLessons.isEmpty && summary.concerns.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Center(
                        child: Text(
                          'Hozircha hech qanday ma\'lumot yo\'q',
                          style: AppTextStyles.bodyS
                              .copyWith(color: const Color(0xFF6B7280)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            loading: () => const _DashboardLoadingSkeleton(),
            error: (err, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppColors.danger),
                    const SizedBox(height: 16),
                    const Text('Yuklab bo\'lmadi', style: AppTextStyles.titleM),
                    const SizedBox(height: 8),
                    Text(
                      'Internet aloqasini tekshiring va qayta urinib ko\'ring',
                      style: AppTextStyles.bodyS.copyWith(color: AppColors.brandMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(dashboardSummaryProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.m)),
                      ),
                      child: const Text('Qayta urinish'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardLoadingSkeleton extends StatelessWidget {
  const _DashboardLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.l),
      children: const [
        AlochiSkeleton(width: 200, height: 28),
        SizedBox(height: AppSpacing.s),
        AlochiSkeleton(width: 280, height: 14),
        SizedBox(height: AppSpacing.xl),
        AlochiSkeleton(width: 160, height: 20),
        SizedBox(height: AppSpacing.m),
        AlochiSkeletonCard(height: 100),
        AlochiSkeletonCard(height: 100),
        AlochiSkeletonCard(height: 100),
      ],
    );
  }
}

class _GreetingHeader extends ConsumerWidget {
  final int todayLessonsCount;

  const _GreetingHeader({
    required this.todayLessonsCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final profileAsync = ref.watch(teacherProfileProvider);
    final name = profileAsync.valueOrNull?.name ?? '';
    final greeting = name.isNotEmpty ? 'Salom, $name Ustoz' : 'Salom, Ustoz';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: AppTextStyles.displayM.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: 4),
              Text(
                todayLessonsCount == 0
                    ? "Bugun darslaringiz yo'q"
                    : 'Bugun sizni $todayLessonsCount ta dars kutmoqda',
                style: AppTextStyles.body.copyWith(color: AppColors.brandMuted),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => context.push('/teacher/notifications'),
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Icon(Icons.notifications_none_rounded,
                      color: AppColors.ink),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                            BorderSide(color: Colors.white, width: 2)),
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

class _TodayLessonsHorizontalList extends StatelessWidget {
  final List<DashboardLessonModel> lessons;

  const _TodayLessonsHorizontalList({required this.lessons});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bugungi darslarim', style: AppTextStyles.titleL),
              TextButton(
                onPressed: () => context.go('/teacher/groups'),
                child: Text('Hammasi',
                    style:
                        AppTextStyles.label.copyWith(color: AppColors.brand)),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        if (lessons.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.l),
            child: Text('Bugun darslaringiz yo\'q'),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              scrollDirection: Axis.horizontal,
              physics: const PageScrollPhysics(),
              itemCount: lessons.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.m),
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                if (lesson.isActive) {
                  return _LessonCardActive(lesson: lesson);
                }
                return _LessonCard(lesson: lesson);
              },
            ),
          ),
        const SizedBox(height: AppSpacing.s),
        Center(
          child: TextButton(
            onPressed: () => context.push('/teacher/timetable'),
            child: Text(
              'Haftalik jadval →',
              style: AppTextStyles.body.copyWith(color: AppColors.brand),
            ),
          ),
        ),
      ],
    );
  }
}

class _LessonCardActive extends StatelessWidget {
  final DashboardLessonModel lesson;

  const _LessonCardActive({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/teacher/lesson/${lesson.id}'),
      child: Container(
        width: 230,
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(AppRadii.l),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(lesson.time,
                    style: AppTextStyles.label.copyWith(color: Colors.white)),
                const AlochiPill(
                    label: 'HOZIR', variant: AlochiPillVariant.brand),
              ],
            ),
            const Spacer(),
            Text(
              lesson.className,
              style:
                  AppTextStyles.bodyS.copyWith(color: const Color(0xFFA1A1AA)),
            ),
            const SizedBox(height: 4),
            Text(
              lesson.subject,
              style: AppTextStyles.titleM.copyWith(color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.m),
            Row(
              children: [
                const Icon(Icons.people_outline,
                    size: 16, color: Color(0xFFA1A1AA)),
                const SizedBox(width: 4),
                Text(
                  '${lesson.studentCount} o\'quvchi',
                  style: AppTextStyles.label
                      .copyWith(color: const Color(0xFFA1A1AA)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(AppRadii.s),
              ),
              child: Center(
                child: Text(
                  'Darsni ochish',
                  style: AppTextStyles.label.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final DashboardLessonModel lesson;

  const _LessonCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/teacher/lesson/${lesson.id}'),
      child: AlochiCard(
        padding: const EdgeInsets.all(AppSpacing.l),
        borderRadius: AppRadii.l,
        child: SizedBox(
          width: 198, // 230 - 32 (padding)
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lesson.time,
                  style: AppTextStyles.label
                      .copyWith(color: const Color(0xFF6B7280))),
              const Spacer(),
              Text(
                lesson.className,
                style: AppTextStyles.bodyS
                    .copyWith(color: const Color(0xFF6B7280)),
              ),
              const SizedBox(height: 4),
              Text(
                lesson.subject,
                style: AppTextStyles.titleM.copyWith(color: AppColors.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.m),
              Row(
                children: [
                  const Icon(Icons.people_outline,
                      size: 16, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 4),
                  Text(
                    '${lesson.studentCount} o\'quvchi',
                    style: AppTextStyles.label
                        .copyWith(color: const Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConcernsSection extends StatelessWidget {
  final List<ConcernModel> concerns;

  const _ConcernsSection({required this.concerns});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('E\'tibor talab', style: AppTextStyles.titleL),
          const SizedBox(height: AppSpacing.m),
          ...concerns.map((concern) => _ConcernRow(concern: concern)),
        ],
      ),
    );
  }
}

class _ConcernRow extends StatelessWidget {
  final ConcernModel concern;

  const _ConcernRow({required this.concern});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconBgColor;
    Color iconColor;

    switch (concern.type) {
      case 'homework':
        icon = Icons.assignment_outlined;
        iconBgColor = const Color(0xFFFEF3C7);
        iconColor = const Color(0xFFD97706);
        break;
      case 'messages':
        icon = Icons.chat_bubble_outline;
        iconBgColor = const Color(0xFFE0F2FE);
        iconColor = const Color(0xFF0EA5E9);
        break;
      case 'telegram':
        icon = Icons.send_rounded;
        iconBgColor = const Color(0xFFE8F2EF);
        iconColor = AppColors.brand;
        break;
      default:
        icon = Icons.info_outline;
        iconBgColor = const Color(0xFFF3F4F6);
        iconColor = const Color(0xFF6B7280);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: GestureDetector(
        onTap: () => context.push(concern.route),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.m),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(concern.title,
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      '${concern.count} ta yangi',
                      style: AppTextStyles.bodyS
                          .copyWith(color: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB)),
            ],
          ),
        ),
      ),
    );
  }
}
