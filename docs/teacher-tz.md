# TZ — A'lochi Teacher Mobile v1.1

**Version:** 1.0
**Date:** 2026-05-03
**Owner:** Max (rusthype)
**Target release:** v1.1.0 (7 kun)
**Repo:** `rusthype/Alochi_app` (Flutter, branch: `v1.1-mobile-redesign`)
**Backend:** `rusthype/alochi` (Django, **NO new endpoints** — only use existing)
**Reference:** `alochi-teacher-ui.html` (26 mockups · single source of truth)

---

## Table of contents

1. [Architecture overview](#1-architecture-overview)
2. [Design system & theme](#2-design-system--theme)
3. [State management](#3-state-management)
4. [Data layer & models](#4-data-layer--models)
5. [Backend integration (existing endpoints)](#5-backend-integration-existing-endpoints)
6. [AI service integration](#6-ai-service-integration)
7. [Offline-first sync strategy](#7-offline-first-sync-strategy)
8. [Per-screen specifications (26 screens)](#8-per-screen-specifications)
9. [7-day sprint plan (daily checklist + acceptance criteria)](#9-7-day-sprint-plan)
10. [Quality gates & testing](#10-quality-gates--testing)
11. [Cuts & deferrals (scope guardrails)](#11-cuts--deferrals)

---

## 1. Architecture overview

### 1.1 Stack

| Layer | Tech |
|---|---|
| App | Flutter 3.24 (existing) |
| State | Riverpod 2.x (or match existing — see §3.1) |
| Routing | go_router 14.x |
| Local DB | Hive (existing — extend) |
| HTTP | dio + retrofit |
| Realtime | WebSocket (Django Channels) — for chat only |
| AI | Gemini Flash via FastAPI proxy at `https://api.alochi.org/ai/` |
| Telegram | Existing bot `@alochi_uz_bot` — no new logic |
| CI | GitHub Actions (existing) |
| Crash | Sentry (existing) |

### 1.2 Bottom navigation (5 tabs)

13 ta web teacher sahifasidan 5 ta tab'ga jamlandi:

| Tab | Index | Screens (top-level) | Web sahifalardan kelib chiqdi |
|---|---|---|---|
| **Bosh** | 0 | Dashboard | `/teacher/`, `/teacher/dashboard` |
| **Guruhlar** | 1 | Guruhlar list → Guruh detail (4 tabs: O'quvchilar / Davomat / Baholar / Tahlil) | `/teacher/classes`, `/teacher/students`, `/teacher/attendance` |
| **Vazifalar** | 2 | Vazifalar list → Vazifa detail / Yangi vazifa | `/teacher/homework`, `/teacher/tests` |
| **Xabarlar** | 3 | Xabarlar list → Chat thread | `/teacher/messages`, `/teacher/notifications` |
| **Profil** | 4 | Profil → Edit / Parol / Telegram / Bildirishnomalar | `/teacher/profile`, `/teacher/settings` |

**Cut from bottom nav (web-only):**
- Reyting (`/teacher/rating`) — deeplink ochiladi profile menyudan
- Hisobot (`/teacher/reports`) — web orqali
- Sertifikatlar (`/teacher/certificates`) — web orqali
- AI yordamchi alohida tab emas — Dashboard quick action + Vazifa create + Xabarlar inline chip orqali kiriladi

### 1.3 Navigation graph

```
SplashRoute
  ├─→ OnboardingRoute (1 screen V1.1 — Welcome only)
  │     └─→ AuthRoute
  └─→ AuthRoute → LoginScreen → AppShell (5 tabs)
                                  ├─ tab 0: Dashboard
                                  │     ├─ /lesson/:lessonId  (Dars boshqaruvi #27 — unified workflow)
                                  │     │     └─ inline steps: Davomat → Vazifa review → Baho → Yangi vazifa
                                  │     ├─ /todos  (concerns expanded)
                                  │     └─ /notifications
                                  ├─ tab 1: GroupsList (Sinflar → Guruhlar)
                                  │     └─ /groups/:id
                                  │           ├─ tab: students → /groups/:id/students/:studentId (Bola profili)
                                  │           ├─ tab: attendance (history)
                                  │           ├─ tab: grades
                                  │           └─ tab: analytics  (V1.2)
                                  ├─ tab 2: HomeworkList
                                  │     ├─ /homework/:id (detail)
                                  │     ├─ /homework/new
                                  │     └─ /tests/...
                                  ├─ tab 3: MessagesList
                                  │     ├─ /chat/:conversationId
                                  │     ├─ /messages/compose?recipientId=X  (V1.2)
                                  │     └─ /messages/group/:classId
                                  └─ tab 4: Profile
                                        ├─ /profile/edit
                                        ├─ /profile/password
                                        ├─ /profile/telegram  (#26 — parents invite, NOT teacher link)
                                        └─ /profile/notifications

Standalone routes (deeplink-only, V1.1 minimum):
  ├─ /attendance/take?classId=X       (out-of-lesson context)
  ├─ /grades/enter?classId=X&topicId  (out-of-lesson context)
  ├─ /homework/create?classId=X        (out-of-lesson context)
  └─ /ai                                (any time)
```

### 1.4 Folder structure (Flutter)

```
lib/
├── main.dart
├── app.dart                              # MaterialApp, theme, router root
├── theme/
│   ├── theme.dart                        # AlochiTheme.light/dark
│   ├── colors.dart                       # AppColors (12 tokens)
│   ├── typography.dart                   # AppText (10 styles)
│   ├── spacing.dart                      # AppSpacing (8/12/16/24/32)
│   └── radii.dart                        # AppRadius (8/12/14/16/100)
├── core/
│   ├── api/
│   │   ├── dio_client.dart
│   │   ├── api_endpoints.dart            # Constants
│   │   └── interceptors/
│   │       ├── auth_interceptor.dart
│   │       └── retry_interceptor.dart
│   ├── storage/
│   │   ├── hive_boxes.dart
│   │   └── secure_storage.dart
│   ├── sync/
│   │   ├── sync_queue.dart               # Pending operations
│   │   └── connectivity_service.dart
│   └── errors/
│       └── app_exception.dart
├── features/
│   ├── auth/
│   │   ├── data/  (repository, dto)
│   │   ├── domain/  (entities)
│   │   ├── presentation/  (providers, screens, widgets)
│   ├── onboarding/
│   ├── dashboard/
│   ├── classes/
│   ├── attendance/
│   ├── grades/
│   ├── homework/
│   ├── messages/
│   ├── ai_assistant/
│   └── profile/
├── shared/
│   ├── widgets/
│   │   ├── alochi_button.dart            # Primary, secondary, dashed, danger
│   │   ├── alochi_pill.dart              # Color variants (teal, amber, green, red)
│   │   ├── alochi_avatar.dart            # Circle with initials
│   │   ├── alochi_input.dart             # Filled, with label
│   │   ├── alochi_card.dart
│   │   ├── alochi_status_dot.dart        # Online indicator
│   │   ├── alochi_progress_bar.dart      # Color-coded
│   │   ├── alochi_grade_badge.dart       # 2/3/4/5 colored
│   │   ├── alochi_grade_button.dart      # Tap-to-grade in entry screen
│   │   ├── alochi_attendance_toggle.dart # ✓/−/✕ 3-state
│   │   ├── alochi_skeleton.dart          # Shimmer loading
│   │   ├── alochi_empty_state.dart       # Universal empty
│   │   ├── alochi_offline_banner.dart    # Top warning banner
│   │   └── ...
│   └── extensions/
│       ├── context_extensions.dart       # context.colors, context.text
│       └── date_extensions.dart          # "Bugun", "2 daq oldin"
└── l10n/
    └── intl_uz.arb                        # All strings (Uzbek)
```

### 1.5 Conventions

- **No emoji in code** — Lucide / Material icons only
- **Naming:** snake_case files, PascalCase classes, camelCase fields
- **No ad-hoc colors** — only `AppColors.brand` etc.
- **No ad-hoc text styles** — only `AppText.titleM` etc.
- **All `print()` removed** — use `AppLogger` (existing)
- **No hardcoded strings** — `S.of(context).welcome` (gen-l10n)
- **Universal salutation:** "Ustoz" not personal name (web Login backward-compat → if `user.first_name` exists, mobile still shows "Ustoz")

---

## 2. Design system & theme

### 2.1 Color tokens (`lib/theme/colors.dart`)

```dart
class AppColors {
  // Brand — Teal (o'qituvchi ilovasi primary)
  static const brand = Color(0xFF1F6F65);        // teal-600 — primary CTA, active states
  static const brand500 = Color(0xFF2D8A7E);     // teal-500 — hover, lighter accents
  static const brand700 = Color(0xFF155E59);     // teal-700 — pressed state
  static const brandLight = Color(0xFFD5E8E1);   // teal-100 — soft accents
  static const brandSoft = Color(0xFFE8F2EF);    // teal-50 — pill backgrounds
  static const brandTint = Color(0xFFBCD9D1);    // teal-200 — disabled CTA, borders
  static const brandInk = Color(0xFF0F4F49);     // teal-800 — text on light brand bg
  static const brandDarkInk = Color(0xFF0A3A35); // teal-900 — darker text
  static const brandOnDark = Color(0xFFA8D5CD);  // teal-300 — text on dark brand bg
  static const brandMuted = Color(0xFF5A8B87);   // tagline color, secondary
  
  // Accent — Warm Coral (logodagi orange barglardan extracted)
  // STRICT USAGE: faqat 4 ta o'rinda — AI features, Pride card, achievements, milestones
  static const accent = Color(0xFFE8954E);       // AI welcome, Pride card
  static const accentSoft = Color(0xFFFCEFE3);   // AI bg, Pride bg
  static const accentInk = Color(0xFF7A4218);    // Text on accent bg
  
  // Ink (text)
  static const ink = Color(0xFF111827);          // Primary text, hero CTAs
  static const ink2 = Color(0xFF374151);         // Body
  static const gray = Color(0xFF6B7280);         // Secondary
  static const gray2 = Color(0xFF9CA3AF);        // Tertiary, placeholders
  
  // Lines & surfaces
  static const line = Color(0xFFE5E7EB);
  static const lineSoft = Color(0xFFF4F5F7);
  static const surface = Color(0xFFFAFAFA);
  static const white = Color(0xFFFFFFFF);
  
  // Hero dark (active lesson card, lesson workflow header)
  static const heroDark = Color(0xFF0E2E2A);     // dark teal-tinted (brand-harmonized)
  
  // Semantic (status colors — strict separation from brand to avoid conflicts)
  static const success = Color(0xFF0F9A6E);      // Keldi, Topshirildi, Tushundi
  static const successSoft = Color(0xFFE1F5EE);
  static const successInk = Color(0xFF0F6E56);
  static const warning = Color(0xFFD97706);      // Kechikdi, Diqqat, Qisman
  static const warningSoft = Color(0xFFFAEEDA);
  static const warningInk = Color(0xFF854F0B);
  static const danger = Color(0xFFDC2626);       // Yo'q, Xato, Tushunmadi
  static const dangerSoft = Color(0xFFFCEBEB);
  static const dangerInk = Color(0xFF791F1F);
  static const info = Color(0xFF0EA5E9);
  static const telegram = Color(0xFF26A5E4);     // Telegram brand (external)
  
  // Grade colors (2 → 5)
  static const grade2 = Color(0xFFDC2626);       // Red — fail
  static const grade3 = Color(0xFFD97706);       // Amber — pass
  static const grade4 = Color(0xFF1F6F65);       // Teal — good (brand)
  static const grade5 = Color(0xFF0F9A6E);       // Green — excellent
}
```

### 2.2 Typography (`lib/theme/typography.dart`)

iOS-native his uchun **SF Pro / system** (Inter Android'da). Custom font YO'Q (mobil ilovada).

```dart
class AppText {
  static const _font = 'Inter'; // Android · iOS uses .systemFont
  
  static const display = TextStyle(
    fontFamily: _font, fontSize: 32, fontWeight: FontWeight.w600,
    letterSpacing: -0.8, height: 1.15, color: AppColors.ink,
  );
  static const titleL = TextStyle(
    fontFamily: _font, fontSize: 28, fontWeight: FontWeight.w600,
    letterSpacing: -0.6, color: AppColors.ink,
  );
  static const titleM = TextStyle(
    fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w600,
    letterSpacing: -0.5, color: AppColors.ink,
  );
  static const titleS = TextStyle(
    fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w600,
    letterSpacing: -0.2, color: AppColors.ink,
  );
  static const bodyL = TextStyle(
    fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w500,
    height: 1.5, color: AppColors.ink,
  );
  static const bodyM = TextStyle(
    fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w400,
    height: 1.5, color: AppColors.ink,
  );
  static const bodyS = TextStyle(
    fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w500,
    height: 1.4, color: AppColors.gray,
  );
  static const caption = TextStyle(
    fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w500,
    color: AppColors.gray,
  );
  static const overline = TextStyle(
    fontFamily: _font, fontSize: 11, fontWeight: FontWeight.w600,
    letterSpacing: 0.4, color: AppColors.gray2,
  );
  static const monoCode = TextStyle(
    fontFamily: 'JetBrains Mono', fontSize: 14, fontWeight: FontWeight.w500,
    letterSpacing: 0.5, color: AppColors.ink,
  );
}
```

### 2.3 Spacing & radii

```dart
class AppSpacing {
  static const xs = 4.0;   // Inline gaps
  static const s = 8.0;    // Tight cluster
  static const m = 12.0;   // Default item gap
  static const l = 16.0;   // Section padding
  static const xl = 24.0;  // Hero padding
  static const xxl = 32.0; // Empty state padding
}

class AppRadius {
  static const xs = 6.0;   // Small chips
  static const s = 8.0;    // Inputs, small buttons
  static const m = 10.0;   // Toggle buttons
  static const l = 12.0;   // Cards (medium)
  static const xl = 14.0;  // Hero cards
  static const xxl = 18.0; // Hero composition
  static const round = 100.0; // Pills
}
```

### 2.4 Reusable widget catalog (15 ta core widget)

| Widget | Path | Used in screens |
|---|---|---|
| `AlochiButton` | `shared/widgets/alochi_button.dart` | Hamma joyda |
| `AlochiPill` | `shared/widgets/alochi_pill.dart` | Guruh badges, status pillalar |
| `AlochiAvatar` | `shared/widgets/alochi_avatar.dart` | Hamma user list |
| `AlochiInput` | `shared/widgets/alochi_input.dart` | Login, Profil edit, Compose |
| `AlochiCard` | `shared/widgets/alochi_card.dart` | Guruh list, Vazifa list, etc. |
| `AlochiStatusDot` | `shared/widgets/alochi_status_dot.dart` | Online indicators |
| `AlochiProgressBar` | `shared/widgets/alochi_progress_bar.dart` | Davomat bars, vazifa bajarish |
| `AlochiGradeBadge` | `shared/widgets/alochi_grade_badge.dart` | Student list (oxirgi baho) |
| `AlochiGradeButton` | `shared/widgets/alochi_grade_button.dart` | Baholar entry screen |
| `AlochiAttendanceToggle` | `shared/widgets/alochi_attendance_toggle.dart` | Davomat belgilash 3-toggle |
| `AlochiHeroBlackCard` | `shared/widgets/alochi_hero_black_card.dart` | Dashboard "Bugungi davomat" |
| `AlochiSkeleton` | `shared/widgets/alochi_skeleton.dart` | Loading states |
| `AlochiEmptyState` | `shared/widgets/alochi_empty_state.dart` | Hamma list bo'sh holat |
| `AlochiOfflineBanner` | `shared/widgets/alochi_offline_banner.dart` | Internet yo'q banner |
| `AlochiBottomNav` | `shared/widgets/alochi_bottom_nav.dart` | 5-tab nav |

### 2.5 Theme wiring (`lib/theme/theme.dart`)

```dart
class AlochiTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: AppColors.brand,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.brandSoft,
      onPrimaryContainer: AppColors.brandInk,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      error: AppColors.danger,
    ),
    scaffoldBackgroundColor: AppColors.surface,
    fontFamily: 'Inter',
    splashColor: AppColors.brandSoft,
    highlightColor: AppColors.brandSoft,
    // ... appBarTheme, cardTheme, inputDecorationTheme, etc.
  );
  
  static ThemeData get dark => ...; // V1.2 — hozircha skip
}
```

**Ishlatish:**
```dart
// Hamma joyda:
Container(color: AppColors.brand)

// Yoki Theme'dan:
Container(color: Theme.of(context).colorScheme.primary)
```

---

## 3. State management

### 3.1 Approach

**Decision:** Riverpod 2.x + Hooks + freezed for state classes.

**Agar mavjud kod Bloc'da bo'lsa:** birinchi kun audit qiling — agar 80%+ Bloc bo'lsa, Riverpod'ga ko'chirmaslik. Yangi feature'larni bir paterndla yozish.

### 3.2 Provider taxonomy

```
Auth & user
├── authStateProvider                 (StateNotifier<AuthState>)
├── currentUserProvider               (Provider<User>)
└── currentTeacherProvider            (Provider<Teacher>) — has subjects[], classes[]

Connectivity & sync
├── connectivityProvider              (StreamProvider<ConnectivityResult>)
├── syncQueueProvider                 (StateNotifier<List<PendingOp>>)
└── isOnlineProvider                  (Provider<bool>)

Classes feature
├── classesListProvider               (FutureProvider<List<TeacherClass>>)
├── classDetailProvider.family(id)    (FutureProvider<ClassDetail>)
├── classStudentsProvider.family(id)  (FutureProvider<List<Student>>)
└── classAnalyticsProvider.family(id) (FutureProvider<ClassAnalytics>)

Attendance feature
├── attendanceMarkingProvider.family(classId, date)
│                                     (StateNotifier<AttendanceState>)
├── attendanceHistoryProvider.family(classId, period)
│                                     (FutureProvider<AttendanceHistory>)
└── attendanceLowStudentsProvider.family(classId)
                                      (Provider<List<Student>>)  — derived

Grades feature
├── gradesEntryProvider.family(classId, topicId)
│                                     (StateNotifier<GradesEntryState>)
└── studentGradesProvider.family(studentId, period)

Homework feature
├── homeworkListProvider.family(filter)  (FutureProvider<List<Homework>>)
├── homeworkDetailProvider.family(id)    (FutureProvider<HomeworkDetail>)
├── homeworkCreateProvider               (StateNotifier<HomeworkDraft>)
└── pollResultsProvider.family(homeworkId)

Messages feature
├── conversationsListProvider           (StreamProvider<List<Conversation>>)
├── chatThreadProvider.family(id)       (StreamProvider<List<Message>>)
├── chatComposerProvider                (StateNotifier<ComposerState>)
└── childContextProvider.family(studentId) (Provider<ChildContext>)

AI feature
├── aiSessionsListProvider              (FutureProvider<List<AiSession>>)
├── aiChatProvider.family(sessionId)    (StreamNotifier<AiChatState>)
└── aiTemplatesProvider                 (Provider<List<AiTemplate>>)  — static

Dashboard
├── dashboardSummaryProvider            (FutureProvider<DashboardSummary>)
└── pendingTodosProvider                (Provider<List<PendingTodo>>)  — derived
```

### 3.3 State classes (freezed pattern)

Misol — Davomat belgilash:

```dart
@freezed
class AttendanceMarkingState with _$AttendanceMarkingState {
  const factory AttendanceMarkingState({
    required int classId,
    required DateTime date,
    required Map<int, AttendanceStatus> studentStatuses, // studentId -> status
    @Default(false) bool isSaving,
    @Default(false) bool hasUnsavedChanges,
    String? error,
  }) = _AttendanceMarkingState;
  
  const AttendanceMarkingState._();
  
  int get presentCount => studentStatuses.values.where((s) => s == AttendanceStatus.present).length;
  int get lateCount => studentStatuses.values.where((s) => s == AttendanceStatus.late).length;
  int get absentCount => studentStatuses.values.where((s) => s == AttendanceStatus.absent).length;
  int get unmarkedCount => studentStatuses.length - presentCount - lateCount - absentCount;
  
  bool get canSave => hasUnsavedChanges && unmarkedCount == 0;
}

enum AttendanceStatus { present, late, absent, unmarked }
```

### 3.4 Persistence rules

| State | Persist? | Where | TTL |
|---|---|---|---|
| Auth tokens | yes | flutter_secure_storage | until logout |
| User profile | yes | Hive `user_box` | 24h refresh |
| Classes list | yes | Hive `classes_box` | 1h refresh |
| Students per class | yes | Hive `students_box` | 1h refresh |
| Today's attendance (unsynced) | **MUST** | Hive `pending_ops_box` | until synced |
| Grades draft | yes | Hive `drafts_box` | until submitted |
| Conversations preview | yes | Hive `chats_box` | live + 5min stale |
| Chat messages | yes | Hive `messages_box` (per chat) | last 100 each |
| Homework list | yes | Hive `homework_box` | 30min refresh |
| AI sessions | yes | Hive `ai_box` | manual delete only |
| Dashboard summary | yes | Hive `dashboard_box` | 5min stale |

---

## 4. Data layer & models

### 4.1 Existing Django models (use as-is, no changes)

Backend'da quyidagi model'lar bor (`rusthype/alochi`):

| Model | App | Mobile uses for |
|---|---|---|
| `User` | accounts | Auth, profile |
| `Teacher` | accounts | Profile, subjects, classes |
| `Student` | students | Class roster, profiles |
| `Parent` | parents | Chat recipients, contact |
| `SchoolClass` | classes | Guruh list, detail |
| `Subject` | subjects | Guruh header, profile fanlar |
| `Lesson` | lessons | Schedule (Bugun/Erta) |
| `Attendance` | attendance | Davomat belgilash, history |
| `Grade` | grades | Baholar entry, history |
| `GradeTopic` | grades | Baholar topic karta |
| `Homework` | homework | Vazifalar list, detail |
| `HomeworkSubmission` | homework | "18/32 topshirdi" |
| `Test` | tests | (Vazifalar list'da `type=test`) |
| `Conversation` | messages | Xabarlar list |
| `Message` | messages | Chat thread |
| `Notification` | notifications | Bell icon, dashboard "Diqqat talab" |
| `TelegramLink` | telegram | Profil → Telegram bog'lash |
| `TelegramPoll` | telegram | Vazifa detail poll natijalari |
| `AiSession` | ai | AI yordamchi tarix |
| `AiMessage` | ai | AI chat thread |
| `LessonPlan` | ai | Lesson plan card (structured output) |

### 4.2 Flutter DTO ↔ entity mapping

Har model uchun:
- **DTO** (`features/<feature>/data/dto/<model>_dto.dart`) — JSON ↔ Dart, `fromJson`/`toJson`, freezed + json_serializable.
- **Entity** (`features/<feature>/domain/entity/<model>.dart`) — pure Dart, business rules, no JSON deps.
- **Mapper** (`features/<feature>/data/mappers/<model>_mapper.dart`) — DTO ↔ Entity, ikki tomonlama.

Misol:

```dart
// dto/student_dto.dart
@freezed
class StudentDto with _$StudentDto {
  const factory StudentDto({
    required int id,
    @JsonKey(name: 'first_name') required String firstName,
    @JsonKey(name: 'last_name') required String lastName,
    @JsonKey(name: 'class_id') required int classId,
    @JsonKey(name: 'attendance_pct') double? attendancePct,
    @JsonKey(name: 'avg_grade') double? avgGrade,
    @JsonKey(name: 'last_grade') int? lastGrade,
    @JsonKey(name: 'parents') List<ParentDto>? parents,
  }) = _StudentDto;
  
  factory StudentDto.fromJson(Map<String, dynamic> json) => _$StudentDtoFromJson(json);
}

// domain/entity/student.dart
@freezed
class Student with _$Student {
  const factory Student({
    required int id,
    required String fullName,                  // "Boboqulova Madina"
    required String shortName,                 // "Boboqulova M."
    required String initials,                  // "BM"
    required int classId,
    double? attendancePct,
    double? avgGrade,
    int? lastGrade,                            // 2-5
    List<Parent>? parents,
  }) = _Student;
  
  const Student._();
  
  bool get hasLowAttendance => (attendancePct ?? 100) < 75;
  bool get hasLowAverage => (avgGrade ?? 5) < 3.5;
  bool get needsAttention => hasLowAttendance || hasLowAverage;
}
```

---

## 5. Backend integration (existing endpoints)

### 5.1 Base URL

- Production: `https://api.alochi.org/api/v1/`
- Staging: `http://198.163.206.64:8000/api/v1/`

### 5.2 Auth

| Method | Endpoint | Mobile use |
|---|---|---|
| POST | `/auth/login/` | Login screen |
| POST | `/auth/refresh/` | dio interceptor (auto) |
| POST | `/auth/logout/` | Profile → "Hisobdan chiqish" |
| POST | `/auth/password/change/` | Profile → Parol o'zgartirish |

JWT in `Authorization: Bearer <token>` header.

### 5.3 Endpoint → screen matrix

| Screen | Endpoint(s) | Method | Notes |
|---|---|---|---|
| **Dashboard** | `/teacher/dashboard/summary/` | GET | Returns today_lessons[], pending_todos[], unread_notifications. Cache 5min. |
| **Dars boshqaruvi** | `/teacher/lessons/{id}/` | GET | Lesson + class + today_attendance_status + yesterday_homework + activity_grading_state |
| **Guruhlar list** | `/teacher/classes/` | GET | Cache 1h. |
| **Guruh detail** | `/teacher/classes/{id}/` | GET | Cache 30min. |
| **Guruh detail tab: o'quvchilar** | `/teacher/classes/{id}/students/` | GET | |
| **Guruh detail tab: davomat** | `/teacher/classes/{id}/attendance/?period=month` | GET | |
| **Guruh detail tab: baholar** | `/teacher/classes/{id}/grades/` | GET | |
| **Guruh detail tab: tahlil** | `/teacher/classes/{id}/analytics/` | GET | V1.1 da basic |
| **Bola profili** | `/teacher/students/{id}/` | GET | Includes parent contacts, last 14 days att, recent grades |
| **Bola profili → Ustoz izohlari** | `/teacher/students/{id}/notes/` | GET, POST | Private to teacher |
| **Davomat belgilash** | `/teacher/attendance/mark/` | POST | Body: `{class_id, date, statuses: {studentId: 'present'/'late'/'absent'}}` |
| **Davomat belgilash (load existing)** | `/teacher/attendance/?class_id=X&date=Y` | GET | If already marked today |
| **Davomat tarixi** | `/teacher/attendance/history/?class_id=X&period=month` | GET | Returns daily aggregates + per-student |
| **Baholar entry** | `/teacher/grades/?class_id=X&topic_id=Y` | GET | |
| **Baholar entry (save)** | `/teacher/grades/bulk/` | POST | `[{student_id, value, comment}]` |
| **Baholar topiclar** | `/teacher/grade-topics/?class_id=X` | GET, POST | |
| **Vazifalar list** | `/teacher/homework/?status=all\|active\|overdue\|finished` | GET | |
| **Vazifa detail** | `/teacher/homework/{id}/` | GET | Includes submissions, poll results |
| **Vazifa create** | `/teacher/homework/` | POST | `{class_id, title, description, due_at, telegram_poll, reminder, attachments}` |
| **Vazifa eslatma yuborish** | `/teacher/homework/{id}/remind/` | POST | `{student_ids: []}` (yoki bo'sh = hammaga) |
| **Telegram poll natijalari** | `/teacher/homework/{id}/poll-results/` | GET | |
| **Xabarlar list** | `/teacher/conversations/` | GET | Sorted by `last_message_at` |
| **Chat thread** | `/teacher/conversations/{id}/messages/?cursor=X` | GET | Cursor pagination |
| **Chat send** | `/teacher/conversations/{id}/messages/` | POST | |
| **Chat WebSocket** | `wss://api.alochi.org/ws/chat/{conversationId}/` | — | Realtime new messages |
| **Compose new** | `/teacher/messages/compose/` | POST | `{recipient_ids: [], subject?, body, telegram_send: bool}` |
| **Tezkor tanlash (low attendance)** | `/teacher/students/?class_id=X&attendance_lt=75` | GET | |
| **Tezkor tanlash (no homework)** | `/teacher/homework/{id}/missing-students/` | GET | |
| **AI welcome (sessions)** | `/teacher/ai/sessions/` | GET, POST | |
| **AI chat thread** | `/teacher/ai/sessions/{id}/messages/` | GET | |
| **AI send message** | `/teacher/ai/sessions/{id}/messages/` | POST | Streams (SSE) |
| **AI export to homework** | `/teacher/ai/lesson-plan/{id}/to-homework/` | POST | "+ Vazifaga qo'sh" CTA |
| **Profil** | `/teacher/profile/` | GET | Used everywhere via cached provider |
| **Profil edit** | `/teacher/profile/` | PATCH | |
| **Avatar upload** | `/teacher/profile/avatar/` | POST (multipart) | |
| **Telegram groups status** | `/teacher/telegram/groups-status/` | GET | Per-group linked/total parents + invite_url + invite_code |
| **Telegram unlinked parents** | `/teacher/telegram/groups/{groupId}/unlinked-parents/` | GET | List of parents not yet subscribed |
| **SMS reminder to parent** | `/teacher/notifications/sms/` | POST | `{parent_id, message}` (existing — used for unlinked parent SMS invites) |

### 5.4 Pagination

Hamma list endpoint'lar `?cursor=X&limit=20` qabul qiladi. Response:

```json
{
  "results": [...],
  "next_cursor": "..." | null,
  "count": 124
}
```

### 5.5 Error contract

Backend xato qaytaradi:

```json
{
  "error_code": "INVALID_GRADE",
  "message": "O'zbek tilida tushunarli xabar",
  "field_errors": { "value": ["..."] }  // optional, 400 only
}
```

Mobile'da `AppException` ga aylanadi va UI'da snackbar/banner orqali ko'rsatiladi.

### 5.6 Rate limits (backend tomondan)

- AI endpoints: 10 req/min/user
- Compose (send): 30 req/min/user
- Hamma boshqasi: 60 req/min/user

Mobile dio interceptor 429'ni 1s/3s/9s back-off bilan qayta urinadi.

### 5.7 Telegram architecture (no teacher account linking)

**Asosiy printsip:** Ustozning shaxsiy Telegram akkaunti ulanmaydi. Bot maktab tomonida joylashgan, ota-onalar bot'ga obuna bo'lishadi.

```
Maktab admin (bir marta):
  └─→ @alochi_uz_bot — backend Django'ga webhook orqali ulangan

Ustoz:
  └─→ App'ga login qiladi (Telegram talab emas)
        └─→ App'da xabar yozadi
              └─→ Backend bot orqali yuboradi
                    └─→ Ota-ona Telegram'da oladi (obunachi bo'lgan)

Ota-ona:
  └─→ Ustozdan QR yoki invite link oladi (har guruh uchun alohida)
        └─→ Telegram'da QR skan / link ochish
              └─→ Bot'ga `/start group_5A` deep link bilan kirish
                    └─→ Backend: TelegramLink yaratadi (parent_id, group_id)
                          └─→ Endi ota-ona shu guruh xabarlarini oladi

Javob:
  └─→ Ota-ona bot'ga Telegram'da javob yozadi
        └─→ Bot webhook → backend → tegishli ustozning Conversation'iga
              └─→ Ustoz app'da chat thread'da ko'radi
                    └─→ App'da javob yozadi → bot ota-onaga yuboradi
```

**Backend allaqachon shu pattern uchun tayyorlangan:**
- `TelegramLink` model: parent_id + chat_id + group_subscriptions
- Bot webhook: `/api/v1/telegram/webhook/` (existing, no changes)
- Outbound message dispatcher: existing `send_to_parents(group_id, message)` service
- Inbound message router: existing parent → conversation routing

**Mobile responsibilities:**
- Display per-group invite QR + link (read from `groups-status` endpoint)
- Show subscription stats (28/30 ulangan)
- List unlinked parents → "SMS yubor" (uses existing SMS service to text invite)
- **No teacher-side Telegram auth UI**

**Per-message flow (teacher writes in app):**
1. Teacher composes in app (chat thread, homework create with poll, mass announce)
2. Frontend sends to existing endpoint (e.g. `/teacher/conversations/{id}/messages/`)
3. Backend persists + queues bot dispatch via Celery task
4. Bot sends to subscribed parents in target group
5. Delivery status (sent/read) reflected via WS to teacher's app

**No new mobile endpoints for Telegram** — leverages existing chat/homework/notification infrastructure. Only NEW UI is the parent-invitation screen (#26).

---

## 6. AI service integration

### 6.1 Architecture

```
Flutter app
    │
    │ POST /teacher/ai/sessions/{id}/messages/  (SSE stream)
    ▼
Django backend  (proxies + persists)
    │
    │ POST https://ai.alochi.internal/generate
    ▼
FastAPI AI service
    │
    │ Gemini Flash API (key in env)
    ▼
Gemini Flash 2.0
```

### 6.2 Streaming via SSE

Flutter'da `dio` + `SseClient` (kichik wrapper). Backend `text/event-stream` qaytaradi:

```
event: token
data: {"text": "Salom"}

event: token
data: {"text": "! Dars"}

event: token
data: {"text": " rejasini..."}

event: structured
data: {"type": "lesson_plan", "plan": {...}}

event: done
data: {"message_id": 1234, "tokens_used": 847}
```

UI bo'lim-bo'lim render qiladi (real LLM hissi).

### 6.3 Structured output (lesson plan)

Backend Gemini'ga maxsus prompt yuboradi:
```
Output JSON only:
{
  "type": "lesson_plan",
  "title": "...",
  "duration_min": 45,
  "stages": [{"time_min": 5, "title": "...", "description": "..."}],
  "homework_suggestion": "..."
}
```

Flutter `LessonPlanCardWidget` shu strukturani render qiladi (header + 5 stage rows + "+ Vazifaga qo'sh" CTA).

### 6.4 Templates (`AiTemplate` static list)

Frontend'da hardcoded 6 template (mockup'da ko'rsatilgan):

```dart
enum AiTemplate {
  lessonPlan(label: 'Dars rejasi', icon: 'D', color: brand,
             prompt: 'Quyidagi mavzu uchun 45-daqiqalik dars rejasini tuz: '),
  testQuestions(label: 'Test savollari', icon: 'T', color: info,
                prompt: 'Quyidagi mavzu bo\'yicha 10 ta test savol yarat: '),
  parentMessage(label: 'Ota-onaga xabar', icon: 'X', color: success,
                prompt: 'Ota-onaga quyidagi vaziyat bo\'yicha xabar matnini yoz: '),
  homework(label: 'Uy vazifasi', icon: 'U', color: Color(0xFF7C3AED),
           prompt: 'Quyidagi mavzu uchun uy vazifa misollarini tayyorla: '),
  simplify(label: 'Soddalashtirish', icon: 'S', color: warning,
           prompt: 'Quyidagi mavzuni 5-guruh bolasi tushunadigan tilda yoz: '),
  rubric(label: 'Baholash mezonlari', icon: 'B', color: Color(0xFFDB2777),
         prompt: 'Quyidagi vazifa uchun adolatli baholash mezonlarini ber: ');
}
```

Tap → composer ga prompt yuklanadi va kursor "..." dan keyin keladi.

### 6.5 Token budget

- Per session: 32K tokens kontekst (Gemini Flash limit)
- Per user/day: 100K tokens (backend enforces)
- O'tib ketganda: graceful "Bugungi limit tugadi, ertaga davom eting"

---

## 7. Offline-first sync strategy

Qo'qonda internet yomon. App **offline-first** ishlashi shart.

### 7.1 Read path

```
Request data
    │
    ▼
Check Hive cache  ──> exists & fresh ──> return cached
    │
    │ stale or missing
    ▼
Fetch network
    ├─ success: update Hive, return
    └─ failure: return cached (with stale flag) + show offline banner
```

### 7.2 Write path (critical operations)

Davomat, baholar, xabarlar — offline'da ham ishlashi kerak:

```dart
class PendingOp {
  final String id;                    // uuid
  final OpType type;                  // markAttendance, saveGrade, sendMessage, ...
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retries;
  final String? lastError;
}
```

1. Foydalanuvchi "Saqlash" tugmasini bosadi
2. **Optimistic update** — UI darrov yangilanadi
3. `PendingOp` Hive `pending_ops_box`'ga qo'shiladi
4. **Connectivity service** internet kelganda queue'ni quyadi
5. Server javob qaytarsa — pending op o'chiriladi
6. Server xato qaytarsa — `retries++`, exponential backoff, 3 marta'dan keyin user'ga xabar

### 7.3 Stale data UX (mockup #19)

- Top'da `AlochiOfflineBanner` (amber)
- "Yangilangan: 2 soat oldin" sarlavha ostida
- Content opacity 0.7
- Save tugmalari amber: "Saqlanadi (internet kelganda yuboriladi)"

### 7.4 Sync triggers

- App foreground'ga chiqqanda (Lifecycle)
- Connectivity status change (off → on)
- Har 60 sekundda timer (agar app aktiv bo'lsa)
- User pull-to-refresh

### 7.5 Conflict resolution

- **Davomat:** server wins (oxirgi yozuv qabul). Client warning ko'rsatadi: "Sizning davomat allaqachon ustaringiz tomonidan o'zgartirilgan"
- **Baholar:** same — server wins
- **Xabarlar:** never conflict (append-only)
- **Profile:** PATCH 409 → reload, foydalanuvchiga o'zgarishlarni qaytadan kiritishni so'rash

---

## 8. Per-screen specifications

Har ekran uchun bir xil format: Route → File paths → Widget tree → State → API → States (loading/error/empty) → Navigation → Acceptance criteria.

### 8.1 Onboarding · Auth · Main (8 ta ekran)

---

#### Screen 14 — Welcome (Onboarding 1/3)

**Route:** `/onboarding/welcome`
**Files:**
- `features/onboarding/presentation/screens/welcome_screen.dart`
- `features/onboarding/presentation/widgets/floating_brand_composition.dart`
- `features/onboarding/presentation/onboarding_provider.dart`

**Widget tree:**
```
Scaffold (background: white)
└── SafeArea
    └── Column
        ├── _SkipBar (top right "O'tkazib yuborish")
        ├── Expanded(child: FloatingBrandComposition())   // 6 ta floating shape + center "A"
        ├── _OnboardingText(
        │     title: "Xush kelibsiz, Ustoz!",  // "Ustoz" teal em
        │     subtitle: "Guruhingizni cho'ntakda olib yuring..."
        │   )
        ├── _PageDots(current: 0, total: 3)
        └── Padding · AlochiButton.primary(
              label: "Davom etish ›",
              onPressed: () => context.go('/onboarding/capabilities')
            )
```

**State:** `onboardingProvider` (StateNotifier) — tracks current page, completion status. Stored in `SharedPreferences` `has_completed_onboarding` bool.

**API:** None (fully client-side).

**States:**
- Loading: N/A
- Error: N/A
- Empty: N/A

**Navigation:**
- → `/onboarding/capabilities` (Davom etish)
- → `/auth/login` (O'tkazib yuborish — sets `has_completed_onboarding=true`)

**Edge cases:**
- Agar foydalanuvchi allaqachon onboard bo'lgan — `SplashRoute` ushbu ekranni o'tkazib yuboradi.
- Back button (Android) → exit app (no back from welcome).

**Acceptance criteria:**
- [ ] Floating shape'lar to'g'ri pozitsiyalarda (6 ta, mockup'ga mos)
- [ ] "Ustoz" so'zi teal (#1F6F65) bilan ranglanadi
- [ ] "Davom etish" CTA ink (#111827) ga ega, bosish 200ms scale animatsiya
- [ ] Skip → SharedPreferences yangilanadi, qaytib kelmaydi
- [ ] Skeleton page indicator (1/3 active teal)

---

#### Screen 15 — Capabilities (Onboarding 2/3)

**Route:** `/onboarding/capabilities`
**Files:**
- `features/onboarding/presentation/screens/capabilities_screen.dart`
- `features/onboarding/presentation/widgets/fanned_cards.dart`

**Widget tree:**
```
Scaffold (white)
└── SafeArea
    └── Column
        ├── _SkipBar (with back arrow)
        ├── Expanded(child: FannedCards(   // 3 ta card stacked rotating
        │     cards: [
        │       _AttendanceMiniCard(),    // 28/3/1
        │       _GradesMiniCard(),        // 4 ta rangli baho
        │       _AiMiniCard(),            // "Dars rejasi tayyor"
        │     ],
        │   ))
        ├── _OnboardingText("Hammasi bir joyda")
        ├── _PageDots(current: 1, total: 3)
        └── AlochiButton.primary("Davom etish ›")
```

**Acceptance criteria:**
- [ ] 3 ta card -6°/+4°/-3° aylanish bilan stack
- [ ] Page enter animation: kartalar fade-in stagger (300ms, 100ms delay)
- [ ] Capabilities mini-stats real ko'rinishda (raqamlar haqiqiy formatda)

---

#### Screen 16 — Telegram setup (Onboarding 3/3)

**Route:** `/onboarding/telegram`
**Files:**
- `features/onboarding/presentation/screens/telegram_onboard_screen.dart`
- `features/onboarding/presentation/widgets/telegram_chat_preview.dart`

**Widget tree:**
```
Scaffold
└── Column
    ├── _SkipBar
    ├── _TelegramComposition
    │   ├── _ChatPreviewCard (3 ta bubble: in/out/sys)
    │   ├── _BlueTBadge (green online dot)
    │   └── _ParentAvatars (4 ta + "+12")
    ├── _OnboardingText("Telegram orqali tezkor aloqa")
    ├── _BenefitsList (3 ta ✓ checks)
    ├── _PageDots(current: 2)
    └── Column
        ├── AlochiButton.primary("Telegram'ni ulash va boshlash", icon: TelegramIcon)
        └── TextButton("Hozircha o'tkazib yuborish")
```

**Navigation:**
- "Telegram'ni ulash" → `/onboarding/complete` → `/profile/telegram` (parent-invite screen #26 — yangi modelda) — V1.2'da bu onboarding ekran yangi modelga moslashtirilgan: ota-onalarga link ulashish ko'rsatkichi
- "Hozircha skip" → `/auth/login`

**Acceptance criteria:**
- [ ] Chat preview real layout (in/out bubbles + sys "Davomat avto yangilandi" Telegram-blue tile)
- [ ] +12 avatar overlap pattern (3 cards margin -12px)
- [ ] Skip flow auth screen'ga olib boradi, telegram link keyinroq

---

#### Screen 1 — Login

**Route:** `/auth/login`
**Files:**
- `features/auth/presentation/screens/login_screen.dart`
- `features/auth/presentation/auth_provider.dart`
- `features/auth/data/auth_repository.dart`

**Widget tree:**
```
Scaffold (white, no AppBar)
└── SafeArea
    └── Padding · Column
        ├── _BrandLockup        // Teal "A" 48px + "A'lochi" 24px
        ├── SizedBox(height: 60)
        ├── Text("Xush kelibsiz", style: AppText.display)
        ├── Text("O'qituvchi hisobingizga kiring...", AppText.bodyL)
        ├── SizedBox(height: 36)
        ├── AlochiInput(
        │     label: "Email yoki telefon",
        │     value: state.identifier,
        │     onChanged: notifier.setIdentifier,
        │     keyboardType: TextInputType.emailAddress,
        │   )
        ├── AlochiInput(
        │     label: "Parol",
        │     value: state.password,
        │     onChanged: notifier.setPassword,
        │     obscure: state.obscurePassword,
        │     trailing: TextButton("Ko'rsatish"/"Yashirish"),
        │   )
        ├── _ForgotPasswordLink (right-aligned, brand color)
        ├── SizedBox(height: 24)
        ├── AlochiButton.primary(
        │     label: state.isLoading ? null : "Kirish",
        │     loading: state.isLoading,
        │     onPressed: state.canSubmit ? notifier.login : null,
        │   )
        ├── Spacer
        └── _AdminContactHint   // "Hisobingiz yo'qmi? Maktab admini bilan bog'laning"
```

**State:** `LoginState { identifier, password, obscurePassword, isLoading, error }`

**API:**
- POST `/auth/login/` body: `{identifier, password}` → `{access, refresh, user}`

**Error states:**
- 401: "Email yoki parol noto'g'ri" (snackbar)
- 429: "Juda ko'p urinish, 5 daqiqa kuting"
- Network: "Internet yo'q. Tekshirib qaytadan urining" (offline banner)

**Acceptance criteria:**
- [ ] Email/parol bo'sh bo'lsa "Kirish" disabled (brandTint rang)
- [ ] Login ✓ → tokens flutter_secure_storage'ga, currentUserProvider yangilanadi, `/dashboard` ga
- [ ] "Parolni unutdingiz?" → `/auth/forgot` (V1.1 web link)
- [ ] Loading'da CTA spinner ko'rsatadi, input'lar disabled
- [ ] Avto-fill (iOS keychain / Android autofill) ishlaydi

---

#### Screen 2 — Dashboard

**Route:** `/dashboard` (tab 0 root)
**Files:**
- `features/dashboard/presentation/screens/dashboard_screen.dart`
- `features/dashboard/presentation/widgets/today_lessons_horizontal_list.dart`
- `features/dashboard/presentation/widgets/lesson_card.dart`
- `features/dashboard/presentation/widgets/lesson_card_active.dart`
- `features/dashboard/presentation/widgets/concerns_section.dart`
- `features/dashboard/presentation/dashboard_provider.dart`

**Widget tree:**
```
Scaffold (background: surface)
├── body: RefreshIndicator(onRefresh: notifier.refresh, child:
│     CustomScrollView(slivers: [
│       SliverToBoxAdapter(
│         _GreetingHeader(name: "Ustoz", notifBadge: state.unreadNotifs)
│       ),
│       SliverToBoxAdapter(
│         _SectionHeader("Bugungi darslarim · ${state.todayLessons.length}",
│           trailing: TextButton("Hammasi", → /classes))
│       ),
│       SliverToBoxAdapter(
│         SizedBox(height: 200,
│           child: ListView.separated(
│             scrollDirection: Axis.horizontal,
│             padding: EdgeInsets.symmetric(horizontal: 16),
│             separatorBuilder: SizedBox(width: 10),
│             itemCount: state.todayLessons.length,
│             itemBuilder: (i) {
│               final lesson = state.todayLessons[i];
│               return lesson.isActive
│                 ? LessonCardActive(            // Black bg, teal "HOZIR" badge
│                     lesson: lesson,
│                     onTap: () => context.push('/lesson/${lesson.id}')
│                   )
│                 : LessonCard(                  // White bg, status pillalar
│                     lesson: lesson,
│                     onTap: () => context.push('/lesson/${lesson.id}')
│                   );
│             }
│           )
│         )
│       ),
│       SliverToBoxAdapter(
│         _SectionHeader("Diqqat talab",
│           trailing: TextButton("Hammasi", → /todos))
│       ),
│       SliverPadding(child: SliverList(items: [
│         ConcernRow(type: overdue,
│                    title: "Vazifa muddati o'tdi",
│                    subtitle: "6-A Algebra · 20 ta o'quvchi qoldi"),
│         ConcernRow(type: messages,
│                    title: "Yangi xabarlar",
│                    subtitle: "Daniyor T. otasi va 2 ta boshqa",
│                    badge: 3),
│         ConcernRow(type: telegramMissing,
│                    title: "2 ta ota-ona Telegram'ga ulanmagan",
│                    subtitle: "5-A · invite link yuborish"),
│       ]))
│     ])
│   )
└── bottomNavigationBar: AlochiBottomNav(currentIndex: 0)
```

**Lesson card variants:**

**LessonCardActive** (currently in progress OR next within 30 min):
- 230px wide × 168px height, bg `#18181B`, white text
- Top row: teal "HOZIR" badge (or "KEYINGI" if not yet started) + time range
- Class pill (teal tint on black) + subject name
- Description line ("32 o'quvchi · {topic}")
- Sticky teal CTA "Darsni ochish ›"

**LessonCard** (other lessons today):
- 210px wide × 168px height, white bg, line border
- Time range gray
- Class pill teal + subject
- "30 o'quvchi · 2 soat keyin" gray
- Optional CTA "Tayyorlanish" (bottom, gray) for next-up

**State:** `dashboardSummaryProvider` (FutureProvider, 5min stale), `todayLessonsProvider` (derived from summary), `pendingTodosProvider` (derived).

```dart
@freezed
class TodayLesson with _$TodayLesson {
  const factory TodayLesson({
    required int id,
    required int classId,
    required String classCode,        // "5-A"
    required String subjectName,      // "Matematika"
    required DateTime startsAt,
    required DateTime endsAt,
    required int studentCount,
    String? topic,                    // "Kasrlar bilan amallar"
    @Default(LessonStatus.upcoming) LessonStatus status,
    // Computed: isActive, hoursUntilStart, isCurrentlyHappening
  }) = _TodayLesson;
}

enum LessonStatus { upcoming, active, completed, missed }
```

**API:**
- GET `/teacher/dashboard/summary/` → `{ today_lessons: [{id, class, subject, starts_at, ends_at, student_count, topic, status}], pending_todos: [{type, title, subtitle, link, count}], unread_notifications: 3 }`

**States:**
- Loading: skeleton — greeting + 3 lesson card placeholders horizontally + 2-3 concern rows
- Error: cached data + offline banner
- Empty (no lessons today): replaced section with `AlochiEmptyState.todayLessons` ("Bugun darsingiz yo'q · Eski guruhlarni ko'rish" CTA → /classes)

**Navigation:**
- Active lesson card → `/lesson/:id` (Dars boshqaruvi screen #27)
- Other lesson card → `/lesson/:id` (read-only or upcoming view)
- "Hammasi" today's lessons → `/lessons/today` (V1.2, V1.1: scroll list)
- Concern row overdue → `/homework/:id`
- Concern row messages → `/messages` (tab 3)
- Concern row Telegram missing → `/profile/telegram` (#26)
- Notification bell → `/notifications`

**Edge cases:**
- 0 lessons today → empty state replaces card section
- 6+ lessons → horizontal scroll comfortable
- Lesson currently happening → status = active (highlighted black card)
- All lessons completed → show "Bugungi darslar tugadi · 4 dars yakunlandi" green tile

**Acceptance criteria:**
- [ ] Today's lessons horizontal scroll smooth (60fps)
- [ ] Active lesson black card prominent, others white
- [ ] HOZIR badge faqat lessons.starts_at ≤ now ≤ lessons.ends_at
- [ ] KEYINGI badge agar 30 min ichida boshlanadi
- [ ] Lesson card tap → /lesson/:id (Dars boshqaruvi)
- [ ] Empty state agar bugun dars yo'q
- [ ] Concern rows max 3 ta default ko'rsatiladi, "Hammasi" tugmasi qolganlarini ochadi
- [ ] Pull-to-refresh ishlaydi (1.5s minimum)
- [ ] Notification bell badge: 1+ unread → teal dot

---

#### Screen 3 — Guruhlar list

**Route:** `/classes` (tab 1 root)
**Files:**
- `features/classes/presentation/screens/classes_list_screen.dart`
- `features/classes/presentation/widgets/class_card.dart`
- `features/classes/presentation/classes_provider.dart`

**Widget tree:**
```
Scaffold
├── body: Column
│     ├── _Header (title "Guruhlar" + iconbtn search)
│     ├── _FilterChips ([Hammasi(N), Bugun, Boshlang'ich, ...])
│     └── Expanded(
│           RefreshIndicator(child:
│             ListView.separated(
│               padding: EdgeInsets.symmetric(horizontal: 14),
│               separatorBuilder: SizedBox(10),
│               itemCount: state.classes.length,
│               itemBuilder: (i) => ClassCard(
│                 classData: state.classes[i],
│                 onTap: () => context.push('/classes/${id}'),
│               ),
│             )
│           )
│         )
└── bottomNavigationBar: AlochiBottomNav(currentIndex: 1)
```

**ClassCard structure:**
```
Container (radius xl, white, border line)
└── Padding (l)
    ├── Row (
    │     AlochiPill.brand("5-A"),
    │     Column(title "Matematika", subtitle "32 o'quvchi · Bugun 09:00"),
    │     ChevronRightIcon,
    │   )
    └── Row (
          Expanded(
            Column(
              Row(label "Davomat", percent colored)
              AlochiProgressBar(value: 0.88, color: derived from value)
            )
          ),
          Column(right-aligned, "O'rtacha", "4.2" teal)
        )
```

**State:** `classesListProvider` (FutureProvider, 1h stale).

**API:**
- GET `/teacher/classes/` → `[{id, code, subject_name, students_count, next_lesson_at, attendance_pct, avg_grade}]`

**States:**
- Loading: 3-4 skeleton cards
- Error: cached + offline banner
- Empty: AlochiEmptyState illustration + "Guruh biriktirilmagan"

**Acceptance criteria:**
- [ ] Progress bar rang derived: ≥90% green, 75-89% teal (brand), <75% amber
- [ ] Filter chips active = ink, inactive = outline gray
- [ ] Tap card → `/classes/{id}` slide transition

---

#### Screen 4 — Guruh Detail

**Route:** `/classes/:id`
**Files:**
- `features/classes/presentation/screens/class_detail_screen.dart`
- `features/classes/presentation/widgets/class_stats_row.dart`
- `features/classes/presentation/widgets/class_tabs.dart`
- `features/classes/presentation/widgets/student_row.dart`

**Widget tree:**
```
Scaffold
├── appBar: AlochiAppBar(
│     leading: BackButton,
│     title: Column("5-A · Matematika", subtitle "32 o'quvchi"),
│     actions: [MoreIcon]
│   )
├── body: Column
│     ├── ClassStatsRow (28/32, 4.2 teal, 87% green)
│     ├── ClassTabs (4 ta: O'quvchilar / Davomat / Baholar / Tahlil)
│     └── Expanded(
│           switch (state.activeTab) {
│             students => StudentsListTab(),
│             attendance => AttendanceHistoryTab(),  // Screen #22
│             grades => GradesHistoryTab(),
│             analytics => AnalyticsTab(),
│           }
│         )
└── bottomNavigationBar: AlochiBottomNav(currentIndex: 1)
```

**State:** `classDetailProvider.family(id)`, `classStudentsProvider.family(id)`, etc.

**API:**
- GET `/teacher/classes/{id}/` (header + stats)
- GET `/teacher/classes/{id}/students/` (lazy on tab open)
- GET `/teacher/classes/{id}/attendance/?period=month` (Tab 2)
- GET `/teacher/classes/{id}/grades/` (Tab 3)
- GET `/teacher/classes/{id}/analytics/` (Tab 4 — V1.1 basic only)

**Tab "O'quvchilar" item structure:**
```
Row (
  AlochiAvatar(initials "AT", size 38),
  Column (
    Text("Abdullayev Toshmatov", titleS),
    Text("Davomat 92% · O'rt. 4.5", caption color: gray2 OR amber if low)
  ),
  AlochiGradeBadge(value: 5, size: 22),  // last grade
)
onTap: → /classes/{classId}/students/{studentId}
```

**Acceptance criteria:**
- [ ] 4 ta tab teal underline (active 2px, animated 200ms)
- [ ] Tab loading skeleton (4 satr)
- [ ] Student row low attendance amber (<75%), low avg amber (<3.5)
- [ ] More menu: "Guruhdan chiqarish" (admin-only, hidden if !isOwner), "Eksport CSV"

---

#### Screen 20 — Bola profili

**Route:** `/classes/:classId/students/:studentId`
**Files:**
- `features/classes/presentation/screens/student_profile_screen.dart`
- `features/classes/presentation/widgets/student_hero_section.dart`
- `features/classes/presentation/widgets/parent_contact_card.dart`
- `features/classes/presentation/widgets/attendance_calendar.dart`
- `features/classes/presentation/widgets/teacher_notes_section.dart`

**Widget tree:**
```
Scaffold
├── appBar: AlochiAppBar(back, no title, actions: [MoreIcon])
├── body: SingleChildScrollView, Column
│     ├── StudentHeroSection (avatar 84, name, class pill, XP badge, 2 CTA)
│     ├── _ThreeStatTiles (Davomat 64% amber, O'rtacha 3.2 amber, 14 vazifa)
│     ├── ParentContactCard (otasi teal + onasi pink, T + phone buttons)
│     ├── AttendanceCalendar (14 days, color tiles)
│     ├── _RecentGrades (so'nggi 5 baho)
│     └── TeacherNotesSection (private, "Faqat siz ko'rasiz")
└── bottomNavigationBar: AlochiBottomNav(currentIndex: 1)
```

**State:** `studentProfileProvider.family(studentId)`, `teacherNotesProvider.family(studentId)`.

**API:**
- GET `/teacher/students/{id}/` → student + parents + recent grades + 14d attendance
- GET `/teacher/students/{id}/notes/` → private notes
- POST `/teacher/students/{id}/notes/` → add note `{text}`
- DELETE `/teacher/students/{id}/notes/{noteId}/`

**Hero CTAs:**
- "Otaga yozish" (teal) → `/messages/compose?recipientId={fatherUserId}&prefill=studentContext`
- "Eslatma yubor" (secondary) → action sheet: SMS / Telegram / Push

**Calendar tile rules:**
- Dars kuni present → green
- Late → amber
- Absent → red
- Dars kuni emas (dam olish, bayram) → gray
- Bugun → border 2px brand

**Acceptance criteria:**
- [ ] Davomat <75% va O'rt. <3.5 → "Diqqat talab" amber tag
- [ ] Otasi/onasi T tugmasi: bog'langan → telegram blue, bog'lanmagan → gray
- [ ] Phone tugma → tel:// intent
- [ ] "Ustoz izohi" "Faqat siz ko'rasiz" — teal "+" CTA bilan yangi qo'shish
- [ ] Note delete: long-press → swipe-to-delete pattern

---

#### Screen 27 — Dars boshqaruvi (unified workflow)

**Route:** `/lesson/:lessonId`
**Files:**
- `features/lesson/presentation/screens/lesson_workflow_screen.dart`
- `features/lesson/presentation/widgets/lesson_header.dart`
- `features/lesson/presentation/widgets/workflow_stepper.dart`
- `features/lesson/presentation/widgets/lesson_step_attendance.dart`
- `features/lesson/presentation/widgets/lesson_step_homework_review.dart`
- `features/lesson/presentation/widgets/lesson_step_grading.dart`
- `features/lesson/presentation/widgets/lesson_step_new_homework.dart`
- `features/lesson/presentation/lesson_workflow_provider.dart`

**Concept:**

Bu yangi ekran — **Dashboard'dan tap qilinadigan markaziy workflow**. Bitta darsga kirgan ustoz to'rtta qadamni ketma-ket bajaradi: davomat → kechagi vazifa tekshirish → bugungi baho/aktivlik → yangi vazifa berish.

**Widget tree:**
```
Scaffold (background: surface)
├── appBar: LessonHeader (
│     leading: BackButton,
│     title: Column (
│       Row (AlochiPill.brand("5-A") + Text("Matematika")),
│       Text("Bugun · 09:00 — 09:45", caption)
│     ),
│     trailing: _LiveStatusPill (animated green dot + "Davom etmoqda"),
│   )
├── body: Column
│     ├── WorkflowStepper (
│     │     // 4-segment progress bar with dot indicator at current
│     │     steps: ["Davomat", "Vazifa", "Baho", "Yangi"],
│     │     currentIndex: state.currentStep,
│     │     completedSteps: state.completedSteps,
│     │   )
│     └── Expanded(
│           SingleChildScrollView, Column (
│             // 4 ta step card — completed (green compact), active (teal expanded), locked (gray collapsed)
│             LessonStepCard.attendance(
│               status: state.attendanceStatus,
│               summary: "28 keldi · 3 kech · 1 yo'q",
│               onEdit: () => notifier.expand(0)
│             ),
│             LessonStepCard.homeworkReview(
│               status: state.homeworkStatus,
│               topic: "Kasrlar",
│               submitted: 18, total: 32,
│               unsubmittedList: state.unsubmittedStudents,
│               onRemindAll: notifier.remindAll,
│               onComplete: notifier.completeStep
│             ),
│             LessonStepCard.grading(
│               status: state.gradingStatus,        // Locked initially
│               // Expanded: 4-grade buttons + activity rating per student
│             ),
│             LessonStepCard.newHomework(
│               status: state.newHomeworkStatus,    // Locked initially
│               // Expanded: title + desc + due date chips + Telegram poll toggle
│             ),
│           )
│         )
│   // No bottom nav — focused workflow
```

**Step card variants:**

**Completed step** (green compact):
```
Container (white bg, radius xl, border green-light)
└── Row (
      _CheckTile (30 green ✓),
      Column (Text("1. Davomat belgilandi" titleS), Text(summary, caption)),
      TextButton("Tahrirlash", green) — re-expands
    )
```

**Active step** (teal tinted, expanded):
```
Container (white bg, radius xl, border brand-light)
├── _StepHeader (gradient teal tint, number tile + title)
├── _StepBody (variant-specific content — see below)
└── _StepFooter (
      gradient teal-soft, dashed top border,
      Row (
        AlochiButton.secondary("Hammaga eslatma", teal-tinted) — context-specific,
        AlochiButton.primary("Tugatish va keyingisi ›", brand)
      )
    )
```

**Locked step** (gray, collapsed, opacity 0.55):
```
Container (white bg, radius xl, border line, opacity 0.55)
└── Row (
      _NumberTile (30 gray F4F5F7),
      Column (Text(label, gray), Text(hint, gray2)),
      _LockIcon (small)
    )
```

**Step 1 — Davomat (Attendance):**

Inline reuses `AttendanceMarkingScreen` body components (LiveStatsRow, AllPresentDashedCta, StudentAttendanceRow list). State delegates to `attendanceMarkingProvider.family((classId, today))`.

Key difference from standalone screen #5: integrated into stepper, "Saqlash" CTA renamed "Tugatish va keyingisi ›".

**Step 2 — Vazifa tekshirish (Homework review):**

```
_StepBody:
├── Section header "Topshirilmagan · 14" (teal right-aligned "Hammasi")
├── ListView of unsubmitted students (first 3 visible, rest collapse)
│     Each row: Avatar 28, Name, "● Hali yo'q [· oxirgi 2 ham]", "Eslatma" teal chip
├── "+ 12 ta o'quvchi" expand link
└── (V1.2: list of submitted with view-submission tap)
```

State: `homeworkReviewProvider.family(classId)` — finds yesterday's homework for this class, returns submission status. If no homework yesterday → step auto-marked done with "Kecha vazifa berilmagan" message.

**Step 3 — Baho/Aktivlik (Grading):**

```
_StepBody:
├── _RatingTabs (Topic baholar / Bugungi aktivlik)
├── Tab Topic baholar:
│     Reuses GradesEntryScreen body — TopicCard + GradeButtonsRow per student
├── Tab Bugungi aktivlik (NEW):
│     Per-student row: 3 rating buttons (Yaxshi-yashil / O'rta-amber / Zaif-qizil)
│     Optional comment per student
```

State: `lessonGradingProvider.family(lessonId)` — manages both topic grades and activity ratings. Activity rating saved to backend as new `GradeTopic(type='activity')` (uses existing model).

**Step 4 — Yangi vazifa berish (New homework):**

```
_StepBody:
├── AlochiInput (label "Sarlavha")
├── AlochiInput.multiline (label "Tavsif", 3-4 rows)
├── QuickDateChips (Erta · 3 kun · 1 hafta · Custom)
├── HomeworkToggleRow.telegramPoll (T blue, on by default)
├── HomeworkToggleRow.reminder (! amber, on)
└── _PublishButton ("Vazifa berish va darsni yakunlash" full width brand)
```

State: `lessonNewHomeworkProvider.family(lessonId)` — local draft, on publish: POST `/teacher/homework/` with `{class_id, ...}`. Lesson marks complete.

**Master state — `lessonWorkflowProvider.family(lessonId)`:**

```dart
@freezed
class LessonWorkflowState with _$LessonWorkflowState {
  const factory LessonWorkflowState({
    required Lesson lesson,
    required int currentStep,                  // 0-3
    @Default(<int>{}) Set<int> completedSteps, // {0, 1} after first 2 done
    required AttendanceStatus attendanceStatus,
    required HomeworkReviewStatus homeworkStatus,
    required GradingStatus gradingStatus,
    required NewHomeworkStatus newHomeworkStatus,
    @Default(false) bool isCompleting,
    String? error,
  }) = _LessonWorkflowState;
  
  bool get canProceedToNext => completedSteps.contains(currentStep);
  bool get isFullyComplete => completedSteps.length == 4;
}

enum StepStatus { locked, active, inProgress, completed }
```

**API:**
- GET `/teacher/lessons/{lessonId}/` → `{lesson, class, today_attendance_status, yesterday_homework, ...}`
- All step-specific writes use existing endpoints (§5.3): attendance/mark, grades/bulk, homework/, homework/{id}/remind/

**No new backend endpoint needed** — Dars boshqaruvi is purely a frontend orchestration over existing primitives.

**Navigation:**
- ← back → returns to Dashboard, lesson partial state preserved (Hive draft)
- "Tugatish va keyingisi ›" → advances `currentStep`, expands next, marks current `completed`
- After Step 4 publish → snackbar "Dars yakunlandi · 4 qadam bajarildi" → auto-pop to Dashboard

**Edge cases:**
- Lesson is "upcoming" (not yet started) → screen opens read-only with "Boshlanishini kuting" + Davomat preview
- Lesson is "missed" (past, no actions taken) → screen opens with "Bu darsni o'tkazib yuboribsiz · Eslatma yuborish" CTA
- User exits mid-flow → next time opens this lesson, `currentStep` restored from server
- All 4 steps already done → screen shows "Yakunlangan dars" recap view (each step compact green)

**Acceptance criteria:**
- [ ] Stepper progress bar 4 segment — completed yashil, active teal, locked gray
- [ ] Active step gradient teal tinted header, expanded body
- [ ] Locked steps opacity 0.55, lock icon, untappable
- [ ] Step 1 Davomat: reuses existing 3-toggle UI, Saqlash CTA renamed
- [ ] Step 2 Vazifa: list of unsubmitted students + "Hammaga eslatma" + "Tugatish ›"
- [ ] Step 3 Baho: tabbed (topic baho / bugungi aktivlik) — V1.1 minimum: just activity 3-rating
- [ ] Step 4 Yangi vazifa: minimal form + Telegram poll toggle + publish
- [ ] Each "Tugatish va keyingisi" → completes current, expands next
- [ ] Final publish → "Dars yakunlandi" snackbar + back to Dashboard
- [ ] Mid-flow exit → state preserved (Hive), resumed on reopen
- [ ] Performance: 32 students Step 1 render ≤500ms

---

### 8.2 Workflows (9 ta ekran)

---

#### Screen 5 — Davomat belgilash

**Route:** `/attendance/take?classId=X&date=Y`
**Files:**
- `features/attendance/presentation/screens/attendance_marking_screen.dart`
- `features/attendance/presentation/widgets/live_stats_row.dart`
- `features/attendance/presentation/widgets/all_present_dashed_cta.dart`
- `features/attendance/presentation/widgets/student_attendance_row.dart`
- `features/attendance/presentation/attendance_marking_provider.dart`

**Widget tree:**
```
Scaffold
├── appBar: AlochiAppBar(back, title "Davomat belgilash")
├── body: Column
│     ├── _ClassDatePills (
│     │     classPill: "5-A · Matematika ⌄" (teal tinted),
│     │     datePill: "Bugun" (gray)
│     │   )
│     ├── LiveStatsRow (12/2/1/17, real-time updates from state)
│     ├── AllPresentDashedCta (
│     │     onPressed: notifier.markAllPresent,
│     │     visible: state.unmarkedCount == state.total
│     │   )
│     ├── Expanded(
│     │     ListView.builder(
│     │       itemCount: students.length,
│     │       itemBuilder: (i) => StudentAttendanceRow(
│     │         student: students[i],
│     │         status: state.statuses[students[i].id],
│     │         onChange: (s) => notifier.setStatus(students[i].id, s),
│     │       ),
│     │     )
│     │   )
│     └── _StickySaveButton (
│           visible: state.hasUnsavedChanges,
│           label: "Saqlash",
│           badge: "${state.markedCount} / ${state.total}",
│           loading: state.isSaving,
│           onPressed: state.canSave ? notifier.save : null,
│         )
└── // No bottom nav (modal-feeling)
```

**StudentAttendanceRow:**
```
Container (white, radius l)
└── Row (
      AlochiAvatar (38),
      Expanded(Text(student.shortName, AppText.bodyL)),
      AlochiAttendanceToggle (3-state: ✓ green / − amber / ✕ red,
        size 32, value: status, onChanged: callback)
    )
```

**State:** `attendanceMarkingProvider.family((classId, date))`.

```dart
@freezed
class AttendanceMarkingState with _$AttendanceMarkingState {
  const factory AttendanceMarkingState({
    required int classId,
    required DateTime date,
    required List<Student> students,
    required Map<int, AttendanceStatus> statuses,
    @Default(false) bool isSaving,
    @Default(false) bool hasUnsavedChanges,
    String? error,
  }) = _AttendanceMarkingState;
  
  // Computed: presentCount, lateCount, absentCount, unmarkedCount, canSave, markedCount
}
```

**API:**
- GET `/teacher/attendance/?class_id=X&date=Y` (load existing, may be 404 first time)
- POST `/teacher/attendance/mark/` body: `{class_id, date, statuses: {studentId: status}}`

**Offline:**
- Foydalanuvchi belgilaydi → optimistic state update
- Save bosadi → `PendingOp(type: markAttendance, payload: {...})` Hive'ga
- UI yashil snackbar: "Saqlandi (internet kelganda yuboriladi)" agar offline

**Acceptance criteria:**
- [ ] 3-toggle ish: tap status → instant rang o'zgarishi (no debounce)
- [ ] Live stats real-time yangilanadi (1 ta tap = stats yangi)
- [ ] "Hammasi keldi" CTA — 1 tap → barcha 32 ga `present`
- [ ] Sticky CTA badge "${marked}/${total}" yangilanadi
- [ ] Belgilanmagan o'quvchi qolsa CTA disabled (brandTint), tap'da snackbar "1 ta o'quvchi belgilanmagan"
- [ ] Save success → snackbar yashil "Davomat saqlandi" + auto-pop screen
- [ ] Save failure (network) → red snackbar + retry button + queue'ga
- [ ] Class change ⌄ → class picker modal (Cupertino style)
- [ ] Date change ⌄ → date picker (max: today, min: 30 days ago)

---

#### Screen 22 — Davomat tarixi (Guruh detail Davomat tab)

**Route:** `/classes/:id` tab "Davomat" (not separate route)
**Files:**
- `features/attendance/presentation/widgets/attendance_history_tab.dart`
- `features/attendance/presentation/widgets/period_chips.dart`
- `features/attendance/presentation/widgets/stacked_bar_chart.dart`
- `features/attendance/presentation/widgets/concerns_card.dart`

**Widget tree:**
```
Column (inside ClassDetail tab body)
├── PeriodChips (Hafta / Oy active / Chorak)
├── _SummaryCard (
│     percent: "89%" (color: green),
│     label: "Aprel · 22 dars kuni",
│     trend: "↑ 3.2%" (green pill),
│     legend: ●Keldi ●Kech ●Yo'q,
│     chart: StackedBarChart(days: state.dailyAggregates),
│   )
├── ConcernsCard (   // "Past davomatli o'quvchilar"
│     icon: red ! tile,
│     title: "Past davomatli o'quvchilar",
│     items: state.lowAttendanceStudents.take(3).map(StudentMiniRow).toList()
│   )
└── (V1.1: cut from scope) ListView of daily aggregates
```

**StackedBarChart:**
```dart
class StackedBarChart extends StatelessWidget {
  final List<DayAggregate> days;
  // Renders: each day = vertical bar with 3 segments
  //   bottom green (present%), middle amber (late%), top red (absent%)
  // Today bar: teal label below
  // Holiday: empty bar (height 0)
}
```

**State:** `attendanceHistoryProvider.family((classId, period))`.

**API:**
- GET `/teacher/attendance/history/?class_id=X&period=week|month|quarter`
- Response:
  ```json
  {
    "summary": { "percent": 89.0, "delta_pct": 3.2, "trend": "up" },
    "daily": [
      { "date": "2026-04-22", "present": 28, "late": 3, "absent": 1, "is_lesson_day": true },
      ...
    ],
    "low_attendance_students": [...]
  }
  ```

**Acceptance criteria:**
- [ ] Period chip o'zgartirish → state qaytadan yuklaydi (loading skeleton)
- [ ] Bugun bar teal label (boshqalari gray)
- [ ] Bayram kuni bar bo'sh, label gray
- [ ] Trend up green ↑, down red ↓, flat gray −
- [ ] Past davomatli student tap → `/classes/{id}/students/{studentId}`

---

#### Screen 7 — Baholar entry

**Route:** `/grades/enter?classId=X&topicId=Y` (yoki classId only — birinchi marta topic create)
**Files:**
- `features/grades/presentation/screens/grades_entry_screen.dart`
- `features/grades/presentation/widgets/topic_card.dart`
- `features/grades/presentation/widgets/grade_buttons_row.dart`
- `features/grades/presentation/widgets/grade_comment_modal.dart`
- `features/grades/presentation/grades_entry_provider.dart`

**Widget tree:**
```
Scaffold
├── appBar: AlochiAppBar(back, title "Baholar")
├── body: Column
│     ├── _ClassDatePills (5-A ⌄, 3-may)
│     ├── TopicCard (
│     │     icon: teal "M",
│     │     title: state.topic.title,
│     │     progress: "${graded} / ${total} baholandi · ${percent}%",
│     │     bar: AlochiProgressBar(value, color: brand)
│     │   )
│     └── Expanded(
│           ListView.builder(
│             itemBuilder: (i) => _StudentGradeRow(
│               student: students[i],
│               currentGrade: state.grades[students[i].id]?.value,
│               hasComment: state.grades[students[i].id]?.comment != null,
│               onGradeChange: (v) => notifier.setGrade(students[i].id, v),
│               onCommentTap: () => _openCommentModal(students[i]),
│             )
│           )
│         )
└── // No bottom nav
```

**_StudentGradeRow:**
```
Container (white, radius l, padding 10)
└── Row (
      AlochiAvatar(34),
      Expanded(Column(name, "O'rt. 4.5" caption with color)),
      GradeButtonsRow (4 buttons: 2 red, 3 amber, 4 brand, 5 green; active filled, inactive outline),
      _CommentToggle (✎ teal if has, gray if not)
    )
```

**State:** `gradesEntryProvider.family((classId, topicId))`.

**API:**
- GET `/teacher/grade-topics/?class_id=X` (list, pick or create)
- GET `/teacher/grades/?class_id=X&topic_id=Y`
- POST `/teacher/grades/bulk/` body: `[{student_id, value, comment}, ...]`

**Comment modal (bottom sheet):**
```
ModalBottomSheet
└── Padding · Column
    ├── "Izoh — {student.name}" titleS
    ├── AlochiInput.multiline (4 lines)
    ├── Row (Bekor / Saqlash brand)
```

**Acceptance criteria:**
- [ ] Tap baho tugma → instant fill rang (200ms scale animation)
- [ ] O'rtacha avto-hisoblash (eski baholar + yangisi)
- [ ] Topic mavjud emas → "Yangi topic yarating" empty state
- [ ] Save → bulk POST, success → teal snackbar
- [ ] Comment "✎" — teal = bor, gray2 = yo'q
- [ ] State persistence: restart screen → state Hive'dan tiklanadi (draft)

---

#### Screen 8 — Vazifalar list

**Route:** `/homework` (tab 2 root)
**Files:**
- `features/homework/presentation/screens/homework_list_screen.dart`
- `features/homework/presentation/widgets/homework_card.dart`
- `features/homework/presentation/widgets/status_pill.dart`
- `features/homework/presentation/homework_list_provider.dart`

**Widget tree:**
```
Scaffold
├── body: Column
│     ├── _Header (title "Vazifalar", AlochiButton.icon("+", brand) → '/homework/new')
│     ├── _FilterChips (Hammasi(N), Faol(N) brand, O'tgan, Tugagan)
│     └── Expanded(
│           ListView.separated(
│             itemBuilder: (i) => HomeworkCard(homework: state.list[i])
│           )
│         )
└── bottomNavigationBar: AlochiBottomNav(currentIndex: 2)
```

**HomeworkCard structure:**
```
Container (white, radius xl, border line)
└── Padding (l)
    ├── Row (Pill brand "5-A", "Matematika" bold, StatusPill (BUGUN amber / FAOL teal / O'TGAN red / TUGADI green))
    ├── Text(homework.title, titleS)
    ├── Text(homework.description, caption gray)
    ├── Row (Text("18/32 topshirdi"), Text("56%" colored))
    ├── AlochiProgressBar (color derived from percent)
    ├── (if has telegram poll) Row (small T blue tile, "Poll: 21/32 javob")
    └── (if status==overdue) "Hammaga eslatma yubor" red dashed CTA (full width)
onTap: → /homework/{id}
```

**State:** `homeworkListProvider.family(filter)` where filter is HomeworkFilter enum.

**API:**
- GET `/teacher/homework/?status=all|active|overdue|finished&cursor=X&limit=20`

**Acceptance criteria:**
- [ ] Status pill rang to'g'ri (4 ta variant)
- [ ] O'tgan card "Hammaga eslatma" tap → POST `/homework/{id}/remind/` → snackbar
- [ ] Tugagan card opacity 0.7
- [ ] Pull-to-refresh ishlaydi
- [ ] Endless scroll (cursor pagination)
- [ ] Filter chip tap → loading skeleton 4 ta card

---

#### Screen 9 — Vazifa yaratish

**Route:** `/homework/new?classId=X` (classId optional, picker bo'lmasa)
**Files:**
- `features/homework/presentation/screens/homework_create_screen.dart`
- `features/homework/presentation/widgets/quick_date_chips.dart`
- `features/homework/presentation/widgets/homework_toggle_row.dart`
- `features/homework/presentation/widgets/file_attachments_input.dart`
- `features/homework/presentation/homework_create_provider.dart`

**Widget tree:**
```
Scaffold
├── appBar: _ModalAppBar (
│     leading: TextButton("Bekor"),
│     title: "Yangi vazifa",
│   )
├── body: SingleChildScrollView, Column
│     ├── _ClassPicker (teal-tinted card, dropdown)
│     ├── AlochiInput(label "Sarlavha")
│     ├── AlochiInput.multiline(label "Tavsif", min 3 rows, max 8)
│     ├── _DueDateSection (
│     │     QuickDateChips (Bugun / Erta / 3 kun / 1 hafta / Custom),
│     │     selected indication brand,
│     │     custom → DatePicker (Cupertino)
│     │   )
│     ├── HomeworkToggleRow.telegramPoll (T blue, on by default)
│     ├── HomeworkToggleRow.reminder (! amber, on)
│     ├── HomeworkToggleRow.autoTrack (✓ green, on)
│     ├── (V1.1: cut) FileAttachmentsInput (camera, gallery, document)
│     └── _PublishButton (teal, sticky bottom, label: "Nashr etish · {classCode} guruhga yuborish")
```

**State:** `homeworkCreateProvider`.

```dart
@freezed
class HomeworkDraft with _$HomeworkDraft {
  const factory HomeworkDraft({
    int? classId,
    @Default('') String title,
    @Default('') String description,
    DateTime? dueAt,
    @Default(true) bool telegramPoll,
    @Default(true) bool reminder,
    @Default(true) bool autoTrack,
    @Default(<File>[]) List<File> attachments,
  }) = _HomeworkDraft;
  
  bool get canPublish => classId != null && title.isNotEmpty && dueAt != null;
}
```

**API:**
- POST `/teacher/homework/` multipart body for files

**Acceptance criteria:**
- [ ] Class pre-selected agar classId param keldi
- [ ] Quick date chips (Bugun=today 22:00, Erta=tomorrow 22:00, 3 kun, 1 hafta)
- [ ] Custom chip → CupertinoDatePicker
- [ ] Toggle on=brand, off=line
- [ ] Publish button — `canPublish` false → brandTint disabled
- [ ] Success → snackbar "Vazifa yuborildi" + auto-pop, list yangilanadi
- [ ] Network error → form preserved, "Qaytadan urinib ko'ring"

---

#### Screen 21 — Vazifa detail

**Route:** `/homework/:id`
**Files:**
- `features/homework/presentation/screens/homework_detail_screen.dart`
- `features/homework/presentation/widgets/homework_hero_card.dart`
- `features/homework/presentation/widgets/homework_tabs.dart`
- `features/homework/presentation/widgets/poll_results_card.dart`
- `features/homework/presentation/widgets/bulk_remind_bar.dart`
- `features/homework/presentation/widgets/submission_row.dart`

**Widget tree:**
```
Scaffold
├── appBar: AlochiAppBar(back, title Column(pill+"Vazifa", "Matematika · 3-may"), actions: [more])
├── body: SingleChildScrollView, Column
│     ├── HomeworkHeroCard (
│     │     status pill (BUGUN amber, etc.),
│     │     title titleS,
│     │     description bodyM,
│     │     submissionsRow ("18/32 · 14 qoldi · 56%"),
│     │     AlochiProgressBar,
│     │     dueRow (deadline countdown amber, "Tahrirlash" link),
│     │   )
│     ├── HomeworkTabs (Topshirilmagan(14) | Topshirgan(18) | Poll(21))
│     ├── (if poll exists) PollResultsCard (
│     │     blue header "Telegram poll natijalari",
│     │     3 ta progress bars (Tushundim 76% green, Qisman 19% amber, Tushunmadim 5% red)
│     │   )
│     ├── BulkRemindBar (
│     │     dashed teal,
│     │     "{notSubmittedCount} ta o'quvchi",
│     │     "Hammaga eslatma" brand button
│     │   )
│     └── _SubmissionsList (per active tab)
└── bottomNavigationBar: AlochiBottomNav(currentIndex: 2)
```

**SubmissionRow:**
```
Row (
  AlochiAvatar(34),
  Expanded(
    Column(
      Text(student.shortName, bodyL),
      Row(red dot, "Hali yo'q",
          if pattern: " · oxirgi 2 vazifa ham" red)
    )
  ),
  _RemindButton (teal tinted bg, "T" blue icon + "Eslatma")
)
```

**State:** `homeworkDetailProvider.family(homeworkId)`, `pollResultsProvider.family(homeworkId)`.

**API:**
- GET `/teacher/homework/{id}/` (full detail)
- GET `/teacher/homework/{id}/poll-results/` (separate, may not exist)
- POST `/teacher/homework/{id}/remind/` body: `{student_ids: []}` (yoki bo'sh = hammaga)

**"Pattern signal" logic:**
- Backend `submission_pattern` flag qaytaradi: `{student_id: "missed_last_2"}`
- Frontend agar shunday bo'lsa, satr ostida red text "oxirgi 2 vazifa ham"

**Acceptance criteria:**
- [ ] Default tab "Topshirilmagan" (action items first)
- [ ] Poll bor bo'lsa Poll Results Card ko'rsatiladi
- [ ] "Hammaga eslatma" → confirm dialog → POST → snackbar
- [ ] Student row "T" tugma — agar parent telegram link yo'q bo'lsa, gray + "Telegram bog'lanmagan" tooltip
- [ ] Pattern signal red text faqat backend yuborganda

---

#### Screen 23 — Compose new message

**Route:** `/messages/compose?recipientId=X` (recipientId optional)
**Files:**
- `features/messages/presentation/screens/message_compose_screen.dart`
- `features/messages/presentation/widgets/recipient_chips_input.dart`
- `features/messages/presentation/widgets/quick_select_chips.dart`
- `features/messages/presentation/widgets/ai_template_chips.dart`
- `features/messages/presentation/message_compose_provider.dart`

**Widget tree:**
```
Scaffold
├── appBar: _ModalAppBar (
│     leading: "Bekor",
│     title: "Yangi xabar",
│     trailing: AlochiButton.send ("Yuborish ↑" brand)
│   )
├── body: Column
│     ├── _ModeBar (3 ta: Bitta active ink / Guruhga / Bir nechta)
│     ├── RecipientChipsInput (label "Kimga", chips with × delete)
│     ├── QuickSelectChips (
│     │     "5-A Hammasi (32)" pill teal,
│     │     "Davomat past (3)" + brand,
│     │     "Vazifa topshirmagan (14)" + brand
│     │   )
│     ├── AlochiInput (label "Mavzu (ixtiyoriy)")
│     ├── Expanded(
│     │     AlochiInput.multiline (label "Matn", flex)
│     │   )
│     ├── _CharCounter ("187 / 1000" right-aligned)
│     ├── AiTemplateChips (
│     │     ✦ AI bilan yozish (teal tinted),
│     │     ! Davomat eslatma (amber),
│     │     ★ Tabriklash (green)
│     │   )
│     └── _ComposerToolbar (
│           +Attach,
│           Telegram toggle pill (teal when on),
│         )
```

**State:** `messageComposeProvider`.

```dart
@freezed
class ComposerState with _$ComposerState {
  const factory ComposerState({
    @Default(ComposeMode.single) ComposeMode mode,
    @Default(<RecipientRef>[]) List<RecipientRef> recipients,
    String? subject,
    @Default('') String body,
    @Default(true) bool sendViaTelegram,
    @Default(false) bool isSending,
    String? error,
  }) = _ComposerState;
  
  bool get canSend => recipients.isNotEmpty && body.isNotEmpty && !isSending;
}
```

**API:**
- POST `/teacher/messages/compose/` body: `{recipient_ids, subject?, body, telegram_send}`
- Quick select endpoints:
  - GET `/teacher/students/?class_id=X&attendance_lt=75`
  - GET `/teacher/homework/{id}/missing-students/` (if context)

**Acceptance criteria:**
- [ ] Pre-fill recipientId param → chip darrov ko'rinadi
- [ ] Mode tab — "Bitta" recipient cap 1, "Bir nechta" no cap
- [ ] Quick select chip tap → bulk add (snackbar "3 ta qo'shildi")
- [ ] AI template tap → composer'ga prefix prompt yuklaydi, kursor matn maydoniga
- [ ] Telegram toggle on (default) → teal, off → gray
- [ ] Send → POST → success snackbar + auto-pop chat thread'ga (yoki list'ga agar group)

---

#### Screen 10 — Xabarlar list

**Route:** `/messages` (tab 3 root)
**Files:**
- `features/messages/presentation/screens/conversations_list_screen.dart`
- `features/messages/presentation/widgets/conversation_row.dart`
- `features/messages/presentation/conversations_provider.dart`

**Widget tree:**
```
Scaffold
├── body: Column
│     ├── _Header (title "Xabarlar", icons: search + plus brand)
│     ├── _SearchBar (gray input, "Ota-onani izlash...", on tap → navigate to search)
│     ├── _FilterChips (Hammasi(24) ink, O'qilmagan(3) brand, 5-A, Guruhlar)
│     └── Expanded(
│           ListView.separated (
│             separatorBuilder: Divider(F4F5F7),
│             itemBuilder: (i) => ConversationRow(conv: state.list[i])
│           )
│         )
└── bottomNavigationBar: AlochiBottomNav(currentIndex: 3)
```

**ConversationRow:**
```
Padding (11x24)
└── Row (
      AlochiAvatar(48, with optional online dot for parents OR brandSoft+teal for groups),
      Expanded(
        Column (
          Row (Text(name) bold + AlochiPill.brand(classCode small) + Spacer + Text(time, color: teal if recent else gray)),
          Row (Expanded(Text("${prefix}: ${preview}", maxLines 1)) + UnreadBadge OR ✓✓ blue OR green dot),
        )
      )
    )
```

**Prefix rules:**
- Parent message → `"${parentRole}:"` (Otasi:/Onasi:)
- Own message → `"Siz:"`
- Group message (group chat) → no prefix on text but avatar is teal-tinted

**State:** `conversationsListProvider` (StreamProvider, WebSocket subscription for live updates).

**API:**
- GET `/teacher/conversations/?cursor=X&limit=20`
- WS `/ws/conversations/` events: `{type: "new_message", conversation_id, last_message, unread_count}` → update list

**Acceptance criteria:**
- [ ] Live updates via WS (no manual refresh)
- [ ] Unread count badge brand circle
- [ ] Recent timestamp teal, eski gray
- [ ] Group chat avatar = brandSoft bg + classCode in brand
- [ ] ✓✓ blue indicator for read sent messages
- [ ] Search input → `/messages/search`
- [ ] Plus brand → `/messages/compose`

---

#### Screen 11 — Chat thread

**Route:** `/chat/:conversationId`
**Files:**
- `features/messages/presentation/screens/chat_thread_screen.dart`
- `features/messages/presentation/widgets/chat_header.dart`
- `features/messages/presentation/widgets/child_context_card.dart`
- `features/messages/presentation/widgets/message_bubble.dart`
- `features/messages/presentation/widgets/typing_indicator.dart`
- `features/messages/presentation/widgets/ai_suggestions_chips.dart`
- `features/messages/presentation/widgets/chat_composer.dart`
- `features/messages/presentation/chat_thread_provider.dart`

**Widget tree:**
```
Scaffold (resizeToAvoidBottomInset: true)
├── appBar: ChatHeader (back, avatar, name + online + classPill, more)
├── body: Column
│     ├── ChildContextCard (
│     │     avatar 38,
│     │     name + "Davomat 64% amber, O'rtacha 3.2 amber",
│     │     "Profil ›" CTA
│     │   )
│     ├── Expanded(
│     │     ListView.builder (
│     │       reverse: true,  // newest at bottom
│     │       itemBuilder: (i) {
│     │         final msg = state.messages[i];
│     │         if (msg.isDateSeparator) return _DateSep("Bugun");
│     │         if (msg.isTyping) return TypingIndicator();
│     │         return MessageBubble(
│     │           text: msg.text,
│     │           isOutgoing: msg.isFromTeacher,
│     │           timestamp: msg.timestamp,
│     │           readReceipt: msg.readReceipt
│     │         );
│     │       }
│     │     )
│     │   )
│     ├── AiSuggestionsChips (visible if state.showAiSuggestions)
│     └── ChatComposer (
│           +attach button,
│           text input (radius 100, gray bg),
│           send button (circle, brand if has text)
│         )
```

**MessageBubble:**
```
Padding(8, align: out=end / in=start)
└── Constrained (maxWidth: 78%)
    └── Container (
          padding: 9x13,
          radius: 18,
          radius bottomRight: 6 (if out) OR bottomLeft: 6 (if in),
          color: out=brand / in=white+border line
        )
        └── Column (
              Text(text, color: out=white / in=ink),
              if (showTime || readReceipt)
                Row (Text(time small gray) + readReceipt? "✓✓" blue : null)
            )
```

**ChildContextCard:**
- Tap → `/classes/:classId/students/:studentId` (Bola profili #20)
- Visible only if conversation is parent-related (not group, not admin)

**State:** `chatThreadProvider.family(conversationId)` (StreamNotifier with WS).

**API:**
- GET `/teacher/conversations/{id}/messages/?cursor=X&limit=30`
- POST `/teacher/conversations/{id}/messages/` body `{text, attachments?}`
- WS `/ws/chat/{id}/` events: typing, new_message, read_receipt

**AI suggestions:**
- Backend tomonidan trigger: oxirgi 3 xabardan ortiq parent answer kutilmasa, GET `/teacher/ai/suggest-reply/?conversation_id=X` → 3 ta tezkor javob
- Tap suggestion → composer'ga yuklanadi

**Offline:**
- Send offline → `PendingOp(type: sendMessage)` + bubble status: "Yuborilmoqda..." (clock icon)
- Tiklanganda → status: ✓✓

**Acceptance criteria:**
- [ ] Child context card top, tap → student profile
- [ ] Bubbles correct color (out brand white text, in white)
- [ ] Read receipt ✓ sent, ✓✓ delivered, ✓✓ blue read
- [ ] Typing indicator 3 nuqta animation (1s pulse)
- [ ] Send button gray when empty, brand when has text
- [ ] Keyboard appear → list auto-scroll to bottom
- [ ] Attach menu: rasm / kamera / hujjat (Cupertino sheet)
- [ ] Send failure → red icon + "Qaytadan" inline tap

### 8.3 AI · Settings · Patterns (9 ta ekran)

---

#### Screen 12 — AI welcome

**Route:** `/ai`
**Files:**
- `features/ai_assistant/presentation/screens/ai_welcome_screen.dart`
- `features/ai_assistant/presentation/widgets/ai_hero_greeting.dart`
- `features/ai_assistant/presentation/widgets/ai_template_card.dart`
- `features/ai_assistant/presentation/widgets/recent_sessions_list.dart`
- `features/ai_assistant/presentation/ai_provider.dart`

**Widget tree:**
```
Scaffold
├── appBar: _AiAppBar (
│     back,
│     title: Column("✦ AI yordamchi", "5-A · Matematika · Faol green"),
│     actions: [TextButton("Tarix" brand)]
│   )
├── body: SingleChildScrollView, Column
│     ├── AiHeroGreeting (
│     │     gradient teal tint,
│     │     "A" mark 48,
│     │     "Assalomu alaykum, Ustoz!",
│     │     "Bugun nima bilan yordam beraman?..."
│     │   )
│     ├── _TemplatesGrid (2x3 of AiTemplateCard)
│     ├── RecentSessionsList (so'nggi 3-5 sessions, full list TextButton "Hammasi")
│     └── _Composer (input + send disabled when empty)
└── // No bottom nav (it's a tool)
```

**AiTemplateCard:**
```
Container (white, radius xl, border line, padding l, min-height 96)
└── Column (
      _IconTile (color: template.color, label: template.icon, 32),
      Text(template.label, titleS),
      Text(template.description, caption),
    )
onTap: () => context.push('/ai/chat?template=${template.name}')
```

**State:** `aiSessionsListProvider`, `aiTemplatesProvider` (static).

**API:**
- GET `/teacher/ai/sessions/?limit=5`
- POST `/teacher/ai/sessions/` (called on first message in /ai/chat)

**Acceptance criteria:**
- [ ] 6 ta template har biri o'z rangida (mockup'ga mos)
- [ ] Hero card gradient teal → light
- [ ] Recent session tap → `/ai/chat?sessionId=X`
- [ ] Template tap → `/ai/chat?template=X` (yangi session, prefix prompt)
- [ ] Composer "AI'dan so'rang..." input — Enter yoki send → yangi session yaratadi

---

#### Screen 13 — AI chat (lesson plan)

**Route:** `/ai/chat?sessionId=X|template=Y`
**Files:**
- `features/ai_assistant/presentation/screens/ai_chat_screen.dart`
- `features/ai_assistant/presentation/widgets/ai_message_bubble.dart`
- `features/ai_assistant/presentation/widgets/lesson_plan_card.dart`
- `features/ai_assistant/presentation/widgets/test_questions_card.dart` (later)
- `features/ai_assistant/presentation/widgets/follow_up_chips.dart`
- `features/ai_assistant/presentation/ai_chat_provider.dart`

**Widget tree:**
```
Scaffold
├── appBar: _AiChatAppBar (
│     back,
│     A mark 36,
│     title: Column("AI yordamchi" + brand pill template name, "5-A · Matematika · Yozayapti green"),
│     actions: [more]
│   )
├── body: Column
│     ├── Expanded(
│     │     ListView.builder (
│     │       reverse: true,
│     │       itemBuilder: (i) {
│     │         final msg = state.messages[i];
│     │         if (msg.role == ai && msg.structuredOutput != null) {
│     │           return LessonPlanCard(plan: msg.structuredOutput);
│     │         }
│     │         return AiMessageBubble(message: msg);
│     │       }
│     │     )
│     │   )
│     ├── FollowUpChips (
│     │     visible if state.lastMessage.suggestions.isNotEmpty,
│     │     items: ["+ Test savollari", "+ Uy vazifa misollari", "+ Soddaroq qil"]
│     │   )
│     └── _AiComposer (input + send)
```

**LessonPlanCard:**
```
Container (white, radius xxl, border brand light)
├── _Header (gradient teal, icon "D", title, "5-guruh · Matematika · 45 daq", "TAYYOR" green badge)
├── Column (padding l)
│     ├── For each stage:
│     │   _StageRow (
│     │     _TimePill ("5 DAQ" teal),
│     │     Column (Text title bold, Text description caption)
│     │   )
└── _Footer (
      AlochiButton.primary "+ Vazifaga qo'sh" (teal, full flex),
      AlochiButton.icon "⧉" copy,
      AlochiButton.icon "↻" regenerate
    )
```

**State:** `aiChatProvider.family(sessionId)` — StreamNotifier listens to SSE stream.

**API:**
- GET `/teacher/ai/sessions/{id}/messages/`
- POST `/teacher/ai/sessions/{id}/messages/` (returns SSE stream)
- POST `/teacher/ai/lesson-plan/{messageId}/to-homework/` body `{class_id, due_at}` → creates homework

**Streaming render:**
- Token event → append to bubble text (smooth typewriter feel)
- Structured event → switch bubble to LessonPlanCard render
- Done event → enable composer, save final message

**"+ Vazifaga qo'sh" flow:**
1. Tap → bottom sheet `_PublishLessonPlanSheet` with class picker + date picker
2. Confirm → POST → `Navigator.pushReplacement('/homework/{newId}')` (yangi yaratilgan vazifa detail)

**Acceptance criteria:**
- [ ] Stream tokens render smoothly (no jank)
- [ ] Lesson plan card structurali render (5 stage rows)
- [ ] "+ Vazifaga qo'sh" → bottom sheet → POST → vazifa detail screen
- [ ] Copy ⧉ → clipboard + snackbar
- [ ] Regenerate ↻ → POST `/regenerate` (kept for V1.2 if backend ready)
- [ ] Follow-up chip tap → composer'ga yuklanadi
- [ ] Token limit reached error → red banner "Bugungi limit tugadi"
- [ ] Network drop mid-stream → partial bubble + "Davom ettirish" retry button

---

#### Screen 6 — Profil

**Route:** `/profile` (tab 4 root)
**Files:**
- `features/profile/presentation/screens/profile_screen.dart`
- `features/profile/presentation/widgets/profile_hero.dart`
- `features/profile/presentation/widgets/pride_card.dart`
- `features/profile/presentation/widgets/profile_stats_row.dart`
- `features/profile/presentation/widgets/profile_settings_list.dart`
- `features/profile/presentation/profile_provider.dart`

**Widget tree:**
```
Scaffold
├── body: SingleChildScrollView, Column
│     ├── ProfileHero (
│     │     avatar 84 with brand ring + green online dot,
│     │     name display,
│     │     "Matematika · Aziziy maktab"
│     │   )
│     ├── PrideCard (
│     │     gradient teal,
│     │     icon star,
│     │     title "Bu hafta 96% davomat",
│     │     subtitle "Top 3 o'qituvchidan birisiz"
│     │   )
│     ├── ProfileStatsRow (3 cards: 4 guruh / 124 o'quvchi / 8 yil)
│     ├── ProfileSettingsList (
│     │     items: [
│     │       SettingsItem(P brand, "Profil ma'lumotlari", route: /profile/edit),
│     │       SettingsItem(L red, "Parolni o'zgartirish", route: /profile/password),
│     │       SettingsItem(T telegramBlue, "Telegram", trailing: state.tgLinked ? "● Ulangan green" : "Ulanmagan", route: /profile/telegram),
│     │       SettingsItem(i info, "Til", trailing: "O'zbekcha"),
│     │       SettingsItem(M purple, "Mavzu", trailing: "Tizim"),
│     │       SettingsItem(B amber, "Bildirishnomalar", route: /profile/notifications),
│     │     ]
│     │   )
│     └── _LogoutButton (red, white bg, full width)
└── bottomNavigationBar: AlochiBottomNav(currentIndex: 4)
```

**State:** `currentTeacherProvider`, `profileStatsProvider`.

**API:**
- GET `/teacher/profile/` (full profile + stats)

**Acceptance criteria:**
- [ ] Pride card faqat agar weeklyAttendancePct >= 90% (else show another stat)
- [ ] Telegram qatori "● Ulangan" yashil yoki "Ulanmagan" gray
- [ ] Logout → confirm dialog → POST → clear secureStorage → /auth/login
- [ ] Apple-style colored squares left of label (mockup'ga mos: teal/red/blue/amber/purple)

---

#### Screen 24 — Profil edit

**Route:** `/profile/edit`
**Files:**
- `features/profile/presentation/screens/profile_edit_screen.dart`
- `features/profile/presentation/widgets/avatar_uploader.dart`
- `features/profile/presentation/widgets/subjects_chips_input.dart`

**Widget tree:**
```
Scaffold
├── appBar: _ModalAppBar (
│     leading "Bekor",
│     title "Profil ma'lumotlari",
│     trailing: TextButton("Saqlash" brand if hasChanges)
│   )
├── body: SingleChildScrollView, Column
│     ├── AvatarUploader (
│     │     current avatar 96,
│     │     teal "+" tap → image picker (camera/gallery),
│     │     "Rasmni almashtirish" link
│     │   )
│     ├── _SectionHeader("Asosiy ma'lumot")
│     ├── _SectionCard (
│     │     Row (AlochiInput "Ism" + AlochiInput "Familiya"),
│     │     AlochiInput "Email" disabled + "O'zgartirib bo'lmaydi" hint,
│     │     AlochiInput "Telefon"
│     │   )
│     ├── _SectionHeader("Kasbiy ma'lumot")
│     ├── _SectionCard (
│     │     AlochiInput.multiline "Bio" 200 char limit,
│     │     SubjectsChipsInput "Fanlar"
│     │   )
│     └── AlochiButton.primary "O'zgarishlarni saqlash" (sticky bottom)
```

**State:** `profileEditProvider` (StateNotifier with draft).

**API:**
- PATCH `/teacher/profile/` partial body
- POST `/teacher/profile/avatar/` multipart `{avatar: file}`

**Acceptance criteria:**
- [ ] hasChanges true → save button teal enabled
- [ ] Email field disabled + L lock icon
- [ ] Avatar tap → action sheet (Kamera / Galereya / Bekor)
- [ ] Subjects chip × → confirm popup
- [ ] Save → invalidate currentTeacherProvider → snackbar "Saqlandi" → pop

---

#### Screen 25 — Parol o'zgartirish

**Route:** `/profile/password`
**Files:**
- `features/profile/presentation/screens/password_change_screen.dart`
- `features/profile/presentation/widgets/password_strength_meter.dart`
- `features/profile/presentation/widgets/password_requirements_list.dart`

**Widget tree:**
```
Scaffold
├── appBar: AlochiAppBar(back, title "Parolni o'zgartirish",
│     actions: TextButton("Saqlash" brand if state.canSave else gray))
├── body: SingleChildScrollView, Column
│     ├── _WarningBanner (
│     │     amber tile + "Parolni o'zgartirgandan so'ng barcha qurilmalardan chiqarib yuborilasiz..."
│     │   )
│     ├── _SectionCard("Joriy parol", AlochiInput.password)
│     ├── _SectionCard(
│     │     "Yangi parol",
│     │     AlochiInput.password,
│     │     PasswordStrengthMeter (4 segment, value derived from rules),
│     │     PasswordRequirementsList (5 ta rule, ✓ matched green / ○ unmatched gray)
│     │   )
│     ├── _SectionCard(
│     │     "Tasdiqlash",
│     │     AlochiInput.password,
│     │     _MatchIndicator (✓ green "Parollar mos keladi" if matches)
│     │   )
│     └── AlochiButton.primary "Talablar to'liq bajarilsa saqlanadi"
│           (disabled: brandTint if !canSave)
```

**State:** `passwordChangeProvider`.

```dart
@freezed
class PasswordChangeState with _$PasswordChangeState {
  const factory PasswordChangeState({
    @Default('') String currentPassword,
    @Default('') String newPassword,
    @Default('') String confirmPassword,
    @Default(false) bool obscure1,
    @Default(false) bool obscure2,
    @Default(false) bool obscure3,
    @Default(false) bool isSaving,
    String? error,
  }) = _PasswordChangeState;
  
  // Computed:
  PasswordRules get rules;  // {minLength, hasUpper, hasLower, hasDigit, hasSpecial}
  PasswordStrength get strength;  // weak/medium/strong/very_strong
  bool get matchesConfirm;
  bool get canSave;
}
```

**Password rules (5 ta):**
1. Kamida 8 belgi
2. Bir bosh harf (A-Z)
3. Bir kichik harf (a-z)
4. Bir raqam (0-9)
5. Maxsus belgi (! @ # $)

**Strength:**
- 0-1 met: weak (red)
- 2 met: medium (amber)
- 3-4 met: strong (teal)
- 5 met: very strong (green)

**API:**
- POST `/auth/password/change/` body: `{current_password, new_password}`

**Error handling:**
- 401 (current wrong) → field error red border + "Joriy parol noto'g'ri"
- 400 (new same as old) → "Yangi parol eskisidan farq qilishi kerak"

**Acceptance criteria:**
- [ ] Strength meter 4 segment fill rang derived
- [ ] Each rule has matched=green ✓ vs unmatched=gray ○
- [ ] Confirm match → green ✓ "Parollar mos keladi" inline
- [ ] Save disabled (brandTint) until all rules met + match
- [ ] Save success → toast "Parol o'zgartirildi" → auto-logout → /auth/login
- [ ] Eye toggle works per field

---

#### Screen 26 — Telegram (ota-onalarni taklif qilish)

**Route:** `/profile/telegram` (yoki `/teacher/telegram-parents`)
**Files:**
- `features/telegram/presentation/screens/telegram_parents_screen.dart`
- `features/telegram/presentation/widgets/group_subscription_chips.dart`
- `features/telegram/presentation/widgets/group_subscription_status_card.dart`
- `features/telegram/presentation/widgets/group_invite_qr_widget.dart`
- `features/telegram/presentation/widgets/unlinked_parents_card.dart`
- `features/telegram/presentation/telegram_parents_provider.dart`

**Widget tree:**
```
Scaffold
├── appBar: AlochiAppBar(back, title "Ota-onalar Telegram'da")
├── body: SingleChildScrollView, Column
│     ├── _ExplainerBanner (
│     │     blue tinted card with T icon,
│     │     "Sizning Telegram akkauntingiz kerak emas.
│     │      Ota-onalar QR yoki link orqali bot'ga obuna bo'lishadi —
│     │      siz app'dan yozganda bot ularga yuboradi"
│     │   )
│     ├── GroupSubscriptionChips (
│     │     horizontal scroll,
│     │     each chip: "5-A 28/30" with active=ink, inactive=outline,
│     │     onChange: (groupId) => notifier.selectGroup(groupId)
│     │   )
│     ├── GroupSubscriptionStatusCard (
│     │     title: "5-A · Matematika ota-onalari",
│     │     percent: "93%" (color: green),
│     │     progress: AlochiProgressBar(value: 0.93),
│     │     legend: "● 28 ulangan · ● 2 ulanmagan"
│     │   )
│     ├── GroupInviteQrWidget (
│     │     160x160 qr_flutter,
│     │     data: "https://t.me/alochi_uz_bot?start=group_${groupId}",
│     │     center logo: blue T
│     │   )
│     ├── _Caption ("Ota-onalar QR ni Telegram bilan skan qiladilar →
│     │             bot ularga ${child} haqida hammasini yuboradi")
│     ├── Row(
│     │     AlochiButton.telegram("↗ Linkni ulashish", flex 1) → Share.share(...),
│     │     AlochiButton.secondary("QR ni saqlash", flex 1) → save image to gallery
│     │   )
│     ├── _InviteLinkBox (
│     │     gray bg,
│     │     "Invite link" overline,
│     │     mono "t.me/alochi_uz_bot?start=5A",
│     │     "⧉ Nusxa" button
│     │   )
│     └── UnlinkedParentsCard (
│           red "!" tile + "${count} ta ota-ona ulanmagan",
│           list of unlinked parents (name + "SMS yubor" teal button each),
│           SMS via existing /teacher/notifications/sms/ endpoint
│         )
```

**State:** `telegramParentsProvider` (StateNotifier with selected group + per-group data).

```dart
@freezed
class TelegramParentsState with _$TelegramParentsState {
  const factory TelegramParentsState({
    required int selectedGroupId,
    required List<GroupSubscription> groups,        // all teacher's groups with stats
    @Default(<UnlinkedParent>[]) List<UnlinkedParent> unlinkedParents,
    @Default(false) bool isLoading,
    String? error,
  }) = _TelegramParentsState;
}

@freezed
class GroupSubscription with _$GroupSubscription {
  const factory GroupSubscription({
    required int groupId,
    required String groupCode,                       // "5-A"
    required String subjectName,
    required int totalParents,
    required int linkedParents,
    required String inviteUrl,                       // "https://t.me/alochi_uz_bot?start=5A"
    required String inviteCode,                      // "5A" or "abc123"
  }) = _GroupSubscription;
  
  const GroupSubscription._();
  double get linkPct => linkedParents / totalParents;
  bool get isFullyLinked => linkedParents == totalParents;
}
```

**API:**
- GET `/teacher/telegram/groups-status/` → `[{group_id, group_code, total_parents, linked_parents, invite_url, invite_code}]`
- GET `/teacher/telegram/groups/{groupId}/unlinked-parents/` → `[{parent_id, parent_name, child_name, phone}]`
- POST `/teacher/notifications/sms/` body `{parent_id, message: "Telegram'ga ulanish: ..."}` (existing endpoint, repurposed)

**No active polling needed** — status updates on dashboard refresh; this screen pulls fresh on open.

**QR code generation:**
- `qr_flutter` package, ErrorCorrectLevel.M
- Data: `inviteUrl` (already includes start parameter so bot knows which group to subscribe parent to)
- White bg, brand-color modules optional, blue T logo overlay (32px)

**Group switch behavior:**
- Tapping different group chip → state updates, QR regenerates, status card updates (no additional fetch needed — all groups data loaded on open)

**Sharing:**
- "↗ Linkni ulashish" → `Share.share(state.selectedGroup.inviteUrl, subject: "5-A guruh ota-onalari Telegram'iga ulanish")`
- Native share sheet (iOS/Android)

**SMS reminder flow:**
- Tap "SMS yubor" on unlinked parent row → confirm dialog "${name} ga SMS yuborish?"
- Send → POST endpoint
- Success → snackbar "SMS yuborildi" + row marked "SMS yuborilgan"
- Failed → red snackbar + retry

**Backend architecture (REFERENCE — NO CHANGES):**

Backend bot (`@alochi_uz_bot`) maintains:
- Per-parent subscription to specific groups (via `start={group_code}` deep link)
- When teacher sends message via app — backend dispatches via bot to all linked parents in that group
- When parent replies in Telegram — backend's bot webhook routes to teacher's app inbox (creates Conversation)
- Teacher replies in app → backend sends via bot back to parent's Telegram

Teacher's Telegram account is **never linked**. Bot is school-side only.

**Acceptance criteria:**
- [ ] No teacher Telegram link UI anywhere
- [ ] Per-group QR generates from `invite_url`, scannable from Telegram
- [ ] Group chip switch instant (no flash, smooth swap)
- [ ] Status card percent + progress bar animate on switch
- [ ] Share button → native share sheet
- [ ] QR save → device gallery (storage permission handled)
- [ ] Unlinked parents list — SMS button → POST → snackbar
- [ ] Empty state if all groups 100% linked: "Hammasi ulangan!" green tile
- [ ] Loading: 3-4 group chips skeleton + status card placeholder

---

#### Screen 17 — Empty state (Pattern)

**Implementation:** `shared/widgets/alochi_empty_state.dart` — universal reusable.

```dart
class AlochiEmptyState extends StatelessWidget {
  final EmptyStateVariant variant;
  final String title;
  final String description;
  final String? primaryCtaLabel;
  final VoidCallback? onPrimaryTap;
  final String? secondaryCtaLabel;
  final VoidCallback? onSecondaryTap;
  
  // variant: classes, homework, messages, attendance, ai
  //   Each variant has its own illustration widget
}
```

**Variants:**

| Variant | Title | Description | Primary CTA |
|---|---|---|---|
| `classes` | "Hali guruh biriktirilmagan" | "Maktab admini sizga guruh biriktirsa, bu yerda darhol paydo bo'ladi" | "Maktab admini bilan bog'lanish" |
| `homework` | "Vazifa yo'q" | "Birinchi vazifani yarating va Telegram orqali guruhga yuboring" | "+ Yangi vazifa" |
| `messages` | "Xabarlar yo'q" | "Telegram bog'lansa ota-onalar bilan tezkor aloqa boshlanadi" | "Telegram'ni ulash" |
| `attendance` | "Bugun davomat belgilanmagan" | "Bir tap bilan boshlang" | "Davomatni boshlash" |
| `ai` | "AI yordamchi tayyor" | "Birinchi savolingizni yozing yoki shablon tanlang" | (skip — composer focus) |

**Illustration:**
- Teal-tinted box (F4FAF8) + dashed border (BCD9D1)
- Variant-specific minimal icons (desk shapes, message tile, etc.)
- 160×160 size, centered

**Acceptance criteria:**
- [ ] Reusable widget — har feature'da ishlaydi
- [ ] Illustration variant'ga mos
- [ ] Primary CTA teal, secondary text-only gray
- [ ] Padding 32px har taraf
- [ ] Center vertically (Scaffold body Expanded)

---

#### Screen 18 — Loading skeleton (Pattern)

**Implementation:** `shared/widgets/alochi_skeleton.dart` — base shimmer + variant-specific.

```dart
class AlochiSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  // Animates opacity 1 → 0.55 → 1 (1.6s loop)
}
```

**Variant skeletons:**

| Screen | Skeleton structure |
|---|---|
| Dashboard | Greeting placeholder + black hero card placeholder + 4 quick action tiles + 2 todo rows |
| Guruhlar list | 4 ta class card placeholder (avatar+text+bar) |
| Guruh students | 6 ta row (avatar 38 + name 90 + caption 60 + grade tile) |
| Vazifalar list | 3 ta homework card (pill+title+description+bar) |
| Xabarlar list | 5 ta conversation row (avatar 48 + name + preview) |
| Chat thread | 3-4 ta bubble alternating sides |
| AI chat | 2 ta bubble + input |
| Bola profili | hero + 3 stats + parent card + calendar + notes |

**Refresh hint:** Top of list — small spinner + "Yangilanmoqda..." (if pull-to-refresh + offline cache active).

**Acceptance criteria:**
- [ ] Pulse animation smooth (no flicker)
- [ ] Layout structure matches real screen (width/heights)
- [ ] No loading spinner OR skeleton — only one
- [ ] First-time fetch (cold cache) → skeleton 100%
- [ ] Cached fetch → real data with stale flag, no skeleton

---

#### Screen 19 — Error / Offline (Pattern)

**Implementation:** Mix of:
- `shared/widgets/alochi_offline_banner.dart` — top global banner
- `shared/widgets/alochi_error_toast.dart` — bottom red error tile
- Per-screen: opacity 0.7 on cached content

**Top OfflineBanner:**
```
Container (amber bg, border bottom amber-light)
└── Row (
      _IconTile (24x24 amber square + ! white),
      Column (Text "Internet yo'q" bold, Text "Eski ma'lumot ko'rsatilmoqda" small),
      TextButton "Qayta ulan" amber-ink
    )
```

**Bottom ErrorToast:**
```
Container (white, radius xl, border red light, shadow soft red)
└── Row (
      _IconTile (36 red soft + ! red),
      Column (Text title bold, Text description caption),
      AlochiButton.danger "Qaytadan"
    )
```

**Triggers:**

| Trigger | Banner | Toast |
|---|---|---|
| Connectivity offline | top banner shows | — |
| Sync queue retry success | banner hides + toast green "Saqlandi" | — |
| Save action failed (network) | — | toast red "Davomat saqlanmadi" + Qaytadan |
| API 5xx | — | toast red "Server xatosi" + Qaytadan |
| API 401 | redirect to login | — |

**Stale data UX:**
- Header shows: "Yangilangan: 2 soat oldin"
- Content: opacity 0.7
- Pull-to-refresh: spinner + "Yangilanish urinilmoqda..."

**Acceptance criteria:**
- [ ] Banner top sticky, doesn't scroll with content
- [ ] Wi-Fi icon dimmed (signal bars opacity 0.3)
- [ ] Sync queue success → green snackbar "5 ta amal yuborildi"
- [ ] Toast Qaytadan → re-enqueues PendingOp
- [ ] Banner disappears smoothly on reconnect (300ms slide-up)

---

## 9. 7-day sprint plan

**Boshlanish:** 2026-05-04 (Dushanba) · **Yakunlanish:** 2026-05-10 (Yakshanba) · **Release:** v1.1.0
**Daily standup:** 09:00 — Telegram'da o'zingizga rasm qo'shish (kechki yakun + ertangi reja)
**Resources:** 6-8 soat/kun Claude Code, 2-3 parallel agent sessions, real qurilma testing har kun
**Branch strategy:** `v1.1-mobile-redesign` ga PR'lar, har kun mergerga `dev`

### Day 0 — Bugun, Yakshanba 2026-05-03 (Foundation prep)

**Maqsad:** Branch + theme + audit. Tomorrow boshlash uchun toza poydevor.

**Checklist:**
- [ ] Branch yaratish: `git checkout -b v1.1-mobile-redesign` (Alochi_app repo)
- [ ] Eski Flutter kodi audit (15-20 daq):
  - [ ] State management aniqlash (Riverpod / Bloc / Provider)
  - [ ] Existing widget'lar ro'yxati (qaysi qayta ishlatish mumkin)
  - [ ] Eski theme.dart ko'chirilishi kerakmi
- [ ] `lib/theme/` papkasini yaratish:
  - [ ] `colors.dart` — AppColors (12 token)
  - [ ] `typography.dart` — AppText (10 style)
  - [ ] `spacing.dart` — AppSpacing
  - [ ] `radii.dart` — AppRadius
  - [ ] `theme.dart` — AlochiTheme.light wiring
- [ ] `flutter pub get` + `dart run build_runner build` — freezed/json_serializable
- [ ] Git commit: "chore: design system tokens (theme/colors/typography/spacing/radii)"

**Acceptance criteria:**
- [ ] `flutter analyze` 0 errors
- [ ] Yangi theme MaterialApp'ga ulangan
- [ ] Existing screens hech qaerda crash qilmaydi (regression)
- [ ] Branch push qilingan, dev'ga merge qilingan emas (PR draft holatida)

**Agent prompt (Claude Code):**
```
Audit the existing Flutter codebase at /Users/max/PycharmProjects/AlochiSchool/alochi_maktab/.
List: state management library used, widget reuse opportunities, package dependencies.
Then create lib/theme/ with colors.dart, typography.dart, spacing.dart, radii.dart, theme.dart following the spec in teacher-tz.md §2. Use AppColors with 12 tokens (brand, semantic, grade colors). Run flutter analyze to verify zero errors. Do not touch any existing screen yet.
```

---

### Day 1 — Dushanba (Design system widgets + Login + Dashboard)

**Maqsad:** Reusable widgetlar va birinchi 2 ekran (Login, Dashboard).

**Checklist:**
- [ ] **Reusable widgets (8 ta):**
  - [ ] `AlochiButton` (primary/secondary/dashed/danger/icon variants)
  - [ ] `AlochiPill` (brand/amber/green/red/info)
  - [ ] `AlochiAvatar` (initials, size variants, online dot, brand ring)
  - [ ] `AlochiInput` (filled, with label, password obscure)
  - [ ] `AlochiCard` (white, radius xl, border line)
  - [ ] `AlochiProgressBar` (color derived from value)
  - [ ] `AlochiBottomNav` (5 tabs, brand active)
  - [ ] `AlochiAppBar` (back, title column, actions)
- [ ] **Login screen (#1):**
  - [ ] `features/auth/presentation/screens/login_screen.dart`
  - [ ] `auth_provider.dart` + `auth_repository.dart`
  - [ ] DTO: `LoginRequestDto`, `LoginResponseDto`
  - [ ] dio interceptor: bearer token attach + refresh on 401
  - [ ] flutter_secure_storage uchun token persist
- [ ] **Dashboard screen (#2):**
  - [ ] `features/dashboard/presentation/screens/dashboard_screen.dart`
  - [ ] `TodayAttendanceHeroCard` (black #18181B)
  - [ ] `TodayLessonsHorizontalList` (PageScrollPhysics, snap)
  - [ ] `LessonCardActive` (black bg #18181B + HOZIR badge + teal CTA)
  - [ ] `LessonCard` (white bg, time + class + subject)
  - [ ] `ConcernsSection` (3 ta default + "Hammasi" expand)
  - [ ] `dashboardSummaryProvider` (FutureProvider, 5min stale)
- [ ] Real qurilma test: iPhone 12 Mini (kichkina ekran) + Samsung Galaxy A51 (Android)
- [ ] Git commits per task (no Co-Authored-By)

**Acceptance criteria:**
- [ ] Login: noto'g'ri parol → red snackbar, to'g'ri → /dashboard
- [ ] Dashboard "Bugungi darslarim" gorizontal scroll (4 ta dars), aktiv dars qora HOZIR badge bilan
- [ ] Empty state: bugun dars yo'q → "Bugun darsingiz yo'q · Eski guruhlarni ko'rish"
- [ ] Concern row tap → tegishli sahifaga (overdue → vazifa, messages → chat, telegram → /profile/telegram)
- [ ] Pull-to-refresh 1.5s spinner
- [ ] iPhone 12 Mini'da overflow yo'q
- [ ] Test: Max's account bilan real login → real dashboard
- [ ] Aktiv dars tap → /lesson/:id (placeholder Day 2 ga qoldiriladi)

**Agent prompt:**
```
Day 1 of v1.1-mobile-redesign sprint. Implement 8 reusable widgets in lib/shared/widgets/ exactly as specified in teacher-tz.md §2.4. Then implement Login screen (§8.1 Screen 1) and Dashboard screen (§8.1 Screen 2). Dashboard layout: greeting + horizontal scroll today's lessons (active lesson black card with HOZIR badge + teal "Darsni ochish" CTA, others white) + concerns section. Use Riverpod for state. Wire auth interceptor in lib/core/api/dio_client.dart with token refresh on 401. Test on iPhone 12 Mini simulator. Do NOT modify backend. Lesson card tap creates a placeholder route /lesson/:id (full Dars boshqaruvi screen comes Day 2). Commit after each screen.
```

---

### Day 2 — Seshanba (Guruhlar + Guruh detail + Davomat belgilash)

**Maqsad:** Tab 1 (Guruhlar) + eng kritik workflow (Davomat).

**Checklist:**
- [ ] **Reusable widgets (qoldiq):**
  - [ ] `AlochiStatusDot`
  - [ ] `AlochiGradeBadge`
  - [ ] `AlochiAttendanceToggle` (3-state)
- [ ] **Guruhlar list (#3):**
  - [ ] `features/classes/presentation/screens/classes_list_screen.dart`
  - [ ] `ClassCard` widget
  - [ ] `classesListProvider`
  - [ ] Filter chips
- [ ] **Guruh Detail (#4):**
  - [ ] `class_detail_screen.dart` + 4 ta tab body widgets
  - [ ] `ClassStatsRow`
  - [ ] `ClassTabs` controller
  - [ ] Tab 1 (O'quvchilar) — `StudentRow` widget
  - [ ] Tab 2-3-4 — placeholder (Day 4-5'da to'ldiriladi)
- [ ] **Davomat belgilash (#5):**
  - [ ] `attendance_marking_screen.dart`
  - [ ] `LiveStatsRow` real-time
  - [ ] `AllPresentDashedCta`
  - [ ] `StudentAttendanceRow`
  - [ ] `attendanceMarkingProvider`
  - [ ] `_StickySaveButton` with badge
- [ ] **Dars boshqaruvi shell (#27):**
  - [ ] `features/lesson/presentation/screens/lesson_workflow_screen.dart`
  - [ ] `LessonHeader` (back, group + subject + time, live status pill)
  - [ ] `WorkflowStepper` (4-segment progress + step labels)
  - [ ] `LessonStepCard` 3 variants (completed green / active teal / locked gray)
  - [ ] Step 1 (Davomat) — embed `attendance_marking_screen` body components
  - [ ] Steps 2-4 — locked placeholders ("Day 3-4'da to'ldiriladi")
  - [ ] `lessonWorkflowProvider.family(lessonId)` — orchestration state
  - [ ] GET `/teacher/lessons/{id}/`
  - [ ] "Tugatish va keyingisi ›" CTA — advances step
- [ ] **Offline sync skeleton:**
  - [ ] `lib/core/sync/sync_queue.dart` — Hive box for PendingOps
  - [ ] `connectivity_service.dart` — connectivity_plus integration
  - [ ] `isOnlineProvider`
  - [ ] Davomat save → optimistic + queue if offline
- [ ] Real qurilma: airplane mode test (Davomat belgilash → offline saqlash → tiklanish)
- [ ] End-to-end test: Dashboard → tap aktiv dars card → Dars boshqaruvi (#27) Step 1 → Davomat belgilash → save

**Acceptance criteria:**
- [ ] Guruhlar list 4 ta guruh real backend'dan
- [ ] Tap guruh → detail → Tab 1 students render
- [ ] Davomat: 32 ta o'quvchi, 3-toggle har biri, save → backend
- [ ] Offline: airplane mode → Davomat save → "Saqlanadi (internet kelganda)"
- [ ] Internet on → queue avto-flush, snackbar "Saqlandi"
- [ ] Hammasi keldi CTA → 32 ta o'quvchi present
- [ ] Dars boshqaruvi (#27) shell: stepper progress 1/4, Step 1 expanded with Davomat
- [ ] Davomat saqlash → step 1 marked completed (green compact), Step 2 locked placeholder
- [ ] Dashboard → tap dars → Dars boshqaruvi end-to-end ishlaydi

**Agent prompt:**
```
Day 2. Implement Guruhlar list (#3), Guruh Detail (#4 — only Students tab), Davomat belgilash (#5), and Dars boshqaruvi shell (#27 — only Step 1 functional, Steps 2-4 locked placeholders) per teacher-tz.md §8.1, §8.2. Critical: implement offline-first sync queue (§7.2) — attendance saves must work offline and auto-flush on reconnect. Verify end-to-end flow: Dashboard → tap active lesson card → Dars boshqaruvi opens → mark attendance in Step 1 → save → step turns green compact. Test airplane mode flow on real device. Use existing endpoints in §5.3, do NOT create new backend routes. Commit per screen.
```

---

### Day 3 — Chorshanba (Baholar + Vazifalar list + Vazifa create)

**Maqsad:** Baholar entry + Vazifa workflow.

**Checklist:**
- [ ] **Reusable widget:**
  - [ ] `AlochiGradeButton` (4-button row, 2/3/4/5 colored)
- [ ] **Baholar entry (#7):**
  - [ ] `grades_entry_screen.dart`
  - [ ] `TopicCard` (teal "M" icon)
  - [ ] `GradeButtonsRow`
  - [ ] Comment modal (bottom sheet)
  - [ ] `gradesEntryProvider`
  - [ ] Bulk POST + offline queue
- [ ] **Vazifalar list (#8):**
  - [ ] `homework_list_screen.dart`
  - [ ] `HomeworkCard` (status pillalar 4 variant)
  - [ ] Filter chips
  - [ ] `homeworkListProvider.family(filter)`
  - [ ] Endless scroll (cursor pagination)
- [ ] **Vazifa yaratish (#9):**
  - [ ] `homework_create_screen.dart`
  - [ ] `QuickDateChips`
  - [ ] `HomeworkToggleRow` (3 ta toggle)
  - [ ] `homeworkCreateProvider` (HomeworkDraft)
  - [ ] POST + Telegram poll integration
- [ ] Test: 5-A guruhga real vazifa yaratib, 1 ota-onaga Telegram orqali keladimi

**Acceptance criteria:**
- [ ] Baholar entry: 4 ta tugma rang (2 red / 3 amber / 4 brand / 5 green), tap fill rang
- [ ] O'rtacha avto-hisoblash
- [ ] Comment modal: kirit + saqla → ✎ teal aksent
- [ ] Vazifalar list: 4 ta status pill rang to'g'ri
- [ ] Vazifa create: Quick date chip "Erta" → tomorrow 22:00 set
- [ ] Yaratilgan vazifa Telegram'da bot orqali guruhga keladi
- [ ] Status pillalar: BUGUN amber, FAOL brand, O'TGAN red, TUGADI green

**Agent prompt:**
```
Day 3. Implement Baholar entry (#7), Vazifalar list (#8), Vazifa yaratish (#9) per spec. Use existing endpoints. Test with real backend at api.alochi.org — create a homework for 5-A, verify Telegram bot delivers to a test parent's chat. Commit per screen.
```

---

### Day 4 — Payshanba (Xabarlar list + Chat thread + WebSocket)

**Maqsad:** Tab 3 (Xabarlar) — eng murakkab realtime feature.

**Checklist:**
- [ ] **Xabarlar list (#10):**
  - [ ] `conversations_list_screen.dart`
  - [ ] `ConversationRow` (prefiks: Otasi:/Onasi:/Siz:)
  - [ ] Search bar
  - [ ] Filter chips (Hammasi/O'qilmagan/5-A/Guruhlar)
  - [ ] `conversationsListProvider` (StreamProvider)
- [ ] **WebSocket integratsiya:**
  - [ ] `lib/core/realtime/ws_client.dart` (web_socket_channel)
  - [ ] Auth: query param token yoki header
  - [ ] Auto-reconnect with backoff
  - [ ] Subscribe to `/ws/conversations/`
  - [ ] Heartbeat ping/pong
- [ ] **Chat thread (#11):**
  - [ ] `chat_thread_screen.dart`
  - [ ] `ChatHeader` with online indicator
  - [ ] `ChildContextCard` (top sticky-ish)
  - [ ] `MessageBubble` (out brand, in white)
  - [ ] `TypingIndicator` (3 dots animation)
  - [ ] `AiSuggestionsChips` (conditional)
  - [ ] `ChatComposer` (input + send)
  - [ ] `chatThreadProvider.family(id)` (StreamNotifier)
  - [ ] WS `/ws/chat/{id}/` events
  - [ ] Send offline → bubble status "Yuborilmoqda..."
- [ ] **Bola profili (#20)** — quick implementation (Guruh detail'dan tap qila olish):
  - [ ] `student_profile_screen.dart`
  - [ ] All sections (hero, stats, parents, calendar, recent grades, notes)

**Acceptance criteria:**
- [ ] Xabarlar list real backend, prefikslar to'g'ri (Otasi: / Siz:)
- [ ] WS ulanadi, yangi xabar darrov ko'rinadi (no refresh)
- [ ] Chat thread: out bubble brand, in white border line
- [ ] Send offline → clock icon → online'da ✓✓
- [ ] Read receipt ✓✓ blue
- [ ] Child context card tap → student profile (#20)
- [ ] Student profile 14-day calendar render
- [ ] Test: 2 ta qurilmadan suhbat → realtime ko'rsatadi

**Agent prompt:**
```
Day 4. Implement Xabarlar list (#10), Chat thread (#11), Bola profili (#20). Critical: WebSocket integration with reconnect logic. Use existing /ws/conversations/ and /ws/chat/{id}/ endpoints. Test realtime by sending message from web teacher panel and verifying it appears in mobile within 1s. Commit per screen.
```

---

### Day 5 — Juma (AI flow + Telegram parent-invite)

**Maqsad:** AI yordamchi (eng diqqatga sazovor feature) + Telegram ota-onalarni taklif qilish (yangi model).

**Checklist:**
- [ ] **AI welcome (#12):**
  - [ ] `ai_welcome_screen.dart`
  - [ ] `AiHeroGreeting` (gradient teal)
  - [ ] `AiTemplateCard` x6 (har biri o'z rangida)
  - [ ] `RecentSessionsList`
  - [ ] `aiSessionsListProvider`
  - [ ] Bottom composer
- [ ] **AI chat with lesson plan (#13):**
  - [ ] `ai_chat_screen.dart`
  - [ ] `AiMessageBubble` (token streaming)
  - [ ] `LessonPlanCard` (structured render — header, 5 stage rows, footer CTA)
  - [ ] `FollowUpChips` (+ Test / + Soddaroq qil)
  - [ ] `aiChatProvider` (StreamNotifier)
  - [ ] SSE client wrapper for `dio`
  - [ ] "+ Vazifaga qo'sh" → bottom sheet → POST to-homework
- [ ] **Telegram — ota-onalar (#26 — yangi model):**
  - [ ] `telegram_parents_screen.dart`
  - [ ] `_ExplainerBanner` ("Sizning Telegram akkauntingiz kerak emas...")
  - [ ] `GroupSubscriptionChips` (horizontal, with linked/total badge per group)
  - [ ] `GroupSubscriptionStatusCard` (% + progress bar + legend)
  - [ ] `GroupInviteQrWidget` (qr_flutter, 160×160, blue T overlay)
  - [ ] `_InviteLinkBox` (mono link + copy button)
  - [ ] `UnlinkedParentsCard` (list of parents not yet subscribed + SMS button)
  - [ ] `telegramParentsProvider` (StateNotifier)
  - [ ] GET `/teacher/telegram/groups-status/`
  - [ ] GET `/teacher/telegram/groups/{id}/unlinked-parents/`
  - [ ] Share link via `share_plus` package (native share sheet)
  - [ ] SMS reminder via existing `/teacher/notifications/sms/`
  - [ ] **NO teacher account linking** — teacher's Telegram never touched
- [ ] Test: AI lesson plan → "+ Vazifaga qo'sh" → real homework created in 5-A
- [ ] Test: Real ota-ona QR skan → bot'da `/start group_5A` → backend `TelegramLink` created → ulangan parents +1 (real-time refresh)
- [ ] Test: Unlinked parent SMS yuborish → real SMS arrived

**Acceptance criteria:**
- [ ] AI welcome 6 template card mockup'ga mos
- [ ] AI chat: token streaming smooth (no jank)
- [ ] Lesson plan card render structurali (5 stage rows + teal time pillalar)
- [ ] "+ Vazifaga qo'sh" → bottom sheet (class picker + date) → POST → vazifa detail screen
- [ ] Telegram screen: 4 ta guruh chips, har birida correct linked/total
- [ ] Group chip switch → QR + status card instant update
- [ ] QR generates correctly, scannable from real Telegram app → opens bot deep link
- [ ] "Linkni ulashish" → native share sheet (Telegram, WhatsApp, SMS, ...)
- [ ] Unlinked parent "SMS yubor" → POST → snackbar success → row marked
- [ ] **No "Telegram'ni ulang" UI for teacher anywhere in app**

**Agent prompt:**
```
Day 5. Implement AI welcome (#12), AI chat with lesson plan (#13), and Telegram parent-invitation screen (#26 — NEW MODEL, see §5.7 architecture). Critical: SSE streaming for AI tokens, structured output detection for lesson plan card render, "+ Vazifaga qo'sh" bottom sheet flow. For Telegram screen, USE THE NEW PARENT-INVITATION MODEL — teacher's personal Telegram is NEVER linked. Display per-group QR codes and invite links. Parents subscribe to bot via deep link, backend dispatches messages on teacher's behalf. Use existing endpoints listed in §5.3. Use qr_flutter for QR generation, share_plus for native share sheet. Test full flow with real parent device scanning real QR. Commit per screen.
```

---

### Day 6 — Shanba (Profile + Profile edit + Parol + Onboarding)

**Maqsad:** Profile flow va onboarding (3 → 1 ekranga qisqartirilgan).

**Checklist:**
- [ ] **Profile (#6):**
  - [ ] `profile_screen.dart`
  - [ ] `ProfileHero` (avatar 84 with brand ring)
  - [ ] `PrideCard` (teal gradient)
  - [ ] `ProfileStatsRow`
  - [ ] `ProfileSettingsList` (Apple-style colored squares)
  - [ ] Logout flow
- [ ] **Profile edit (#24):**
  - [ ] `profile_edit_screen.dart`
  - [ ] `AvatarUploader` (camera + gallery picker via `image_picker`)
  - [ ] `SubjectsChipsInput`
  - [ ] PATCH `/teacher/profile/`
  - [ ] Multipart avatar upload
- [ ] **Parol (#25):**
  - [ ] `password_change_screen.dart`
  - [ ] `PasswordStrengthMeter` (4 segment)
  - [ ] `PasswordRequirementsList` (5 ta rule)
  - [ ] `_MatchIndicator`
  - [ ] POST `/auth/password/change/` + auto-logout
- [ ] **Onboarding (cut to 1 screen):**
  - [ ] `welcome_screen.dart` (Welcome only)
  - [ ] `FloatingBrandComposition`
  - [ ] Skip "Capabilities" + "Telegram" — V1.2 deferred
  - [ ] First-launch routing: SharedPreferences `has_completed_onboarding`
- [ ] Localization audit:
  - [ ] Hamma string `intl_uz.arb`'ga ko'chirilgan
  - [ ] No hardcoded "Ustoz", "Yaxshi", etc.

**Acceptance criteria:**
- [ ] Profile: pride card faqat haftalik 90%+ bo'lsa
- [ ] Avatar tap → Cupertino sheet (Kamera/Galereya/Bekor) → upload → reflect
- [ ] Parol: 5 ta rule check + match → save enabled, mismatch → red border
- [ ] Onboarding 1 ekran (Welcome) → Login (3-screen V1.2)
- [ ] First launch → onboarding, second launch → login direct

**Agent prompt:**
```
Day 6. Implement Profile (#6), Profile edit (#24), Password change (#25), single-screen Welcome onboarding (#14). Cut multi-step onboarding to single Welcome screen — defer #15 and #16 to V1.2. Avatar upload uses image_picker package, multipart POST. Localization: move all strings to intl_uz.arb. Commit per screen.
```

---

### Day 7 — Yakshanba (Patterns + QA + Release)

**Maqsad:** Empty/Loading/Error patterns to'liq integratsiya, real qurilma QA, v1.1.0 release.

**Checklist:**
- [ ] **Pattern widgets:**
  - [ ] `AlochiEmptyState` — 5 ta variant (classes, homework, messages, attendance, ai)
  - [ ] `AlochiSkeleton` — base + 8 ta screen variant
  - [ ] `AlochiOfflineBanner` — global top
  - [ ] `AlochiErrorToast` — bottom red
- [ ] **Per-screen integration:**
  - [ ] Hamma list ekranlarda empty state
  - [ ] Hamma list ekranlarda skeleton
  - [ ] Top'da global offline banner (connectivity)
  - [ ] Save-failed da error toast
- [ ] **Real qurilma QA (3 ta o'qituvchi):**
  - [ ] Max (iPhone)
  - [ ] Test teacher 1 (Android, slow network)
  - [ ] Test teacher 2 (older Android, low memory)
  - [ ] Davomat belgilash full flow
  - [ ] Vazifa create → Telegram'ga keladi
  - [ ] Chat thread realtime
  - [ ] Offline → online sync
- [ ] **Bug fixes:** QA topgan barcha bug'lar
- [ ] **Performance check:**
  - [ ] Cold start < 3s
  - [ ] Davomat screen 32 students render < 500ms
  - [ ] Chat scroll 60fps
- [ ] **Release prep:**
  - [ ] Version bump: `pubspec.yaml` → 1.1.0
  - [ ] Changelog
  - [ ] APK build + sign
  - [ ] iOS archive + TestFlight
- [ ] **Deploy + announce:**
  - [ ] Aziziy maktabda 5 ta o'qituvchiga TestFlight invite
  - [ ] Telegram'da xabar qoldirish

**Acceptance criteria:**
- [ ] Hamma list ekranlarda empty state ko'rsatiladi (test by clearing data)
- [ ] Skeleton loading har ekranga mos
- [ ] Offline → online sync 3+ pending op flush
- [ ] 3 ta real teacher QA — kritik bug yo'q
- [ ] APK + iOS build muvaffaqiyatli
- [ ] TestFlight beta team get notification
- [ ] Cold start avg 2.5s (Pixel 4a)

**Agent prompt:**
```
Day 7 — final day. Implement pattern widgets (Empty/Loading/Error) per §8.3. Integrate into all list screens (classes, homework, messages, attendance) and detail screens. Build APK and iOS archive. Coordinate QA session with 3 teachers. Bug fix list at end of day. Release v1.1.0 to TestFlight + Play Console internal track. No new features after Day 7 morning — only fixes.
```

---

### Sprint summary table

| Day | Date | Screens shipped | Key deliverables |
|---|---|---|---|
| 0 | 03-May | — | Theme tokens, branch, audit |
| 1 | 04-May | #1, #2 | 8 widgets, Login, Dashboard (today's lessons horizontal scroll) |
| 2 | 05-May | #3, #4 (1 tab), #5, #27 shell | Guruhlar, Guruh detail (students), Davomat, **Dars boshqaruvi shell + Step 1**, offline sync |
| 3 | 06-May | #7, #8, #9, #27 step 2-3 | Baholar, Vazifalar list + create, **Dars boshqaruvi Steps 2 & 3 functional** |
| 4 | 07-May | #10, #11, #20, #27 step 4 | Xabarlar list, Chat thread, WS, Bola profili, **Dars boshqaruvi Step 4 (yangi vazifa)** |
| 5 | 08-May | #12, #13, #26 | AI welcome, AI chat + lesson plan export, **Telegram parent-invitation (new model — no teacher account linking)** |
| 6 | 09-May | #6, #24, #25, #14 | Profile, Edit, Password, single-screen Welcome |
| 7 | 10-May | #17, #18, #19 + QA | Patterns, QA, v1.1.0 RELEASE |

**Total shipped:** 22 ekran (cuts: Compose, Vazifa detail with poll, Tahlil tab, Onboarding 2/3 + 3/3 V1.2 ga ko'chirildi). **Yangi:** Dars boshqaruvi (#27) — markaziy unified workflow.

---

## 10. Quality gates & testing

### 10.1 Code quality

- [ ] `flutter analyze` — 0 errors, 0 warnings (treat warnings as errors)
- [ ] `dart format` — har commit oldidan
- [ ] `flutter test` — minimum coverage 40% (V1.1), targeting 60% (V1.2)
- [ ] No `print()` — `AppLogger` ishlatish
- [ ] No hardcoded strings — `intl_uz.arb`
- [ ] No hardcoded colors — `AppColors.*`
- [ ] No hardcoded text styles — `AppText.*`
- [ ] No `setState` in feature screens — Riverpod only
- [ ] No `BuildContext` across `await` boundary without `mounted` check

### 10.2 Testing strategy (V1.1 minimum)

| Test type | Coverage | Tools |
|---|---|---|
| **Unit** | Provider logic, mappers, utilities | `flutter_test`, `mocktail` |
| **Widget** | Per-screen render + interaction | `flutter_test` |
| **Integration** | Critical flows (login → davomat → save) | `integration_test` |
| **Manual QA** | 3 ta real teacher, 5 cheklash + 5 happy path | Real qurilmalar |

**Critical flows for integration tests:**
1. Login (real backend) → Dashboard renders
2. Davomat: pick class → mark all students → save → success
3. Davomat offline: airplane → mark → save → online → flush
4. Vazifa create → publish → appears in list
5. Chat: send → ✓✓ → receive WS reply → renders

### 10.3 Performance targets

| Metric | Target | Tool |
|---|---|---|
| Cold start (P50) | ≤ 2.5s | Manual stopwatch on Pixel 4a |
| Cold start (P95) | ≤ 4s | Same |
| Dashboard time-to-interactive | ≤ 1.5s | Same |
| List scroll fps | ≥ 60fps | DevTools performance overlay |
| Davomat 32 students render | ≤ 500ms | Profile mode timer |
| Memory peak | ≤ 200MB | DevTools memory panel |
| APK size | ≤ 25MB (release) | `flutter build apk` output |

### 10.4 Localization

- [ ] Barcha string `intl_uz.arb`'da
- [ ] Sana formati: O'zbekcha (3-may, Bugun, Erta, 2 daq oldin)
- [ ] Pluralization: "1 o'quvchi" / "5 o'quvchi" / "21 o'quvchi"
- [ ] Currency: yo'q (V1.1)
- [ ] V1.2: Russian + English support hozirdan key-only struktura tayyorlash

### 10.5 Accessibility

V1.1 minimum:
- [ ] Semantic labels for icon-only buttons
- [ ] Min tap target 44x44 (iOS) / 48x48 (Android)
- [ ] Color contrast WCAG AA (teal brand on white = 3.4:1 — OK for non-text, NOT for body text — never use brand for body)
- [ ] Screen reader: "Davomat: 28 / 32 keldi"
- [ ] Dynamic font scale support (system text size up to 130%)

V1.2: full WCAG AA, dark mode

### 10.6 Crash reporting

- Sentry SDK integratsiya (existing)
- DSN env'dan
- User context: teacher_id (no PII)
- Breadcrumbs: route changes, API calls, auth events
- Critical alerts: crash rate > 1% release'da

### 10.7 Pre-release checklist (Day 7 evening)

- [ ] All Day 1-7 acceptance criteria green
- [ ] 3 teacher QA pass
- [ ] No P0/P1 bugs open
- [ ] APK signed + uploaded to Play Console internal
- [ ] iOS archive uploaded to TestFlight
- [ ] Release notes drafted (Uzbek)
- [ ] Sentry source maps uploaded
- [ ] Backend version compatible (api.alochi.org reads `X-App-Version` header)
- [ ] Telegram bot ready for new poll types (existing — confirmed)
- [ ] Server logs monitoring ready (DigitalOcean alerts)

---

## 11. Cuts & deferrals (scope guardrails)

### 11.1 In scope for V1.1 (22 ekran)

**Tab 0 — Bosh:** Dashboard (today's lessons horizontal scroll)
**Tab 1 — Guruhlar:** Guruhlar list, Guruh detail (faqat O'quvchilar tab), Bola profili, Davomat belgilash, Davomat tarixi (basic in detail tab)
**Tab 2 — Vazifalar:** Vazifalar list, Vazifa create, Vazifa detail (basic — submission list + bulk remind, NO poll results card)
**Tab 3 — Xabarlar:** Xabarlar list, Chat thread (NO Compose new — V1.2)
**Tab 4 — Profil:** Profil, Profil edit, Parol, **Telegram (ota-onalarni taklif qilish — yangi model)**
**Central workflow:** **Dars boshqaruvi (#27 — yangi)** — unified 4-step lesson workflow
**AI:** AI welcome, AI chat with lesson plan export
**Auth:** Login, single-screen Welcome onboarding
**Patterns:** Empty / Loading / Error (universal)

### 11.2 Cut to V1.2 (5 ekran)

| Screen | Reason | V1.2 priority |
|---|---|---|
| **Onboarding 2/3 (Capabilities)** | 1-screen welcome enough for v1; animation work deferred | Medium |
| **Onboarding 3/3 (Telegram setup)** | Telegram parent-invite via Profile menyu | Low |
| **Compose new message** | Chat thread covers most cases; advanced compose later | High |
| **Vazifa detail with Poll results** | Poll display only, send/track in V1.1 | Medium |
| **Guruh detail Tahlil tab** | V1.1: web link → /teacher/groups/:id (deeplink) | Low |

### 11.3 Cut from per-screen (V1.1 simplifications)

- **Bola profili (#20):** No "Ustoz izohi" CRUD UI (read-only display, add via web)
- **Davomat tarixi (#22):** Stacked chart minimal — no zoom, no daily detail tap
- **Profile (#6):** No "Bildirishnomalar" inner page (toast preferences) — V1.2
- **Settings:** No "Til" + "Mavzu" inner pages — system theme + Uzbek only
- **Vazifa create (#9):** No file attachments — V1.2 (camera/document)
- **AI chat (#13):** No "Regenerate" ↻ — V1.2 backend support
- **AI chat (#13):** No copy ⧉ — V1.2 (or simple TextSelection)
- **Xabarlar list (#10):** No search — V1.2 (just filter chips)
- **Compose:** No quick-select chips ("Davomat past (3)") — V1.2 endpoints

### 11.4 Backend changes — STRICT POLICY

**No new endpoints.** Mobile uses existing endpoints exactly as documented in §5.3.

If a screen NEEDS data not available in current API:
1. **Option 1 (preferred):** Mobile derives from existing data (e.g., `lowAttendanceStudents` derived client-side from class/students endpoint)
2. **Option 2:** Cut feature to V1.2
3. **Option 3 (last resort, requires approval):** Backend additive change ONLY (new field on existing endpoint, non-breaking)

**Forbidden:**
- New backend models
- New endpoints
- Schema changes
- Auth flow changes
- Telegram bot logic changes

### 11.5 Risk register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Existing Flutter codebase uses Bloc, not Riverpod | Med | High | Day 0 audit; if Bloc, adapt providers to Bloc syntax (estimated +1 day) |
| Backend API endpoints don't match §5.3 exactly | Med | High | Day 0 verify with curl; report mismatches; align before Day 1 |
| Telegram bot doesn't deliver to new test parents | Low | Med | Day 3 test with real account; fallback: web-only Telegram link |
| iOS TestFlight review delay | Med | Med | Submit Day 6 evening; Android-first if delayed |
| Slow Qo'qon internet during QA | High | Low | Test in airplane mode + 2G simulator |
| AI Gemini quota exceeded mid-sprint | Low | Med | Monitor token usage daily; have fallback "Bugungi limit tugadi" UX ready |
| Real teacher reports critical UX issue Day 7 | High | Med | Buffer 4 hours Day 7 for emergency fixes |

### 11.6 V1.2 roadmap (Sprint +1, +2 weeks)

**Sprint +1 (1 week, 2026-05-11 → 2026-05-17):**
- Compose new message
- Onboarding 2/3 ekranlar
- Vazifa detail Poll results card
- File attachments (Vazifa create)
- Xabarlar search
- AI regenerate + copy

**Sprint +2 (1 week, 2026-05-18 → 2026-05-24):**
- Guruh detail Analytics tab
- Dark mode
- Russian localization
- Notification preferences
- Davomat tarixi advanced (zoom, daily tap)
- Performance optimization

**V1.3+ (uzoq muddat):**
- Parent app (alohida, lekin shared modules)
- Student app (gamification)
- Admin app
- Offline-first improvements (full DB sync)
- Push notifications (FCM/APNS)

---

## Appendix A — Agent prompt template

Har kun uchun standart prompt:

```
You are working on the A'lochi Teacher Mobile v1.1 sprint, Day {N}.

Repository: rusthype/Alochi_app (Flutter)
Branch: v1.1-mobile-redesign
Reference: teacher-tz.md (this file)
Mockups: alochi-teacher-ui.html (open in browser)

Today's scope per teacher-tz.md §9 Day {N}:
{paste daily checklist}

Constraints:
- NO backend changes (use existing endpoints from §5.3)
- NO emoji in code (Lucide / Material Icons only)
- NO Co-Authored-By in commits
- Follow design tokens from §2 (no ad-hoc colors / styles)
- Match existing state management pattern (audited Day 0)
- Universal "Ustoz" salutation, never personal name

Workflow:
1. Read mockup for screen visually (alochi-teacher-ui.html)
2. Read screen spec (teacher-tz.md §8)
3. Implement widget tree → state → API → states → navigation
4. Verify acceptance criteria
5. Real device test on iPhone 12 Mini OR Pixel 4a
6. Commit with message format: "feat({feature}): {what}"
7. Update CHANGELOG.md

Report back when done with:
- ✓ acceptance criteria met
- ⚠ blockers
- 🔍 questions for the team
```

---

## Appendix B — Style enforcement rules

**Forbidden in code:**
```dart
// ❌ Color(0xFF1F6F65)
// ✓ AppColors.brand

// ❌ TextStyle(fontSize: 14, ...)
// ✓ AppText.bodyM

// ❌ EdgeInsets.all(16)
// ✓ EdgeInsets.all(AppSpacing.l)

// ❌ Text("Ustoz")
// ✓ Text(S.of(context).teacherSalutation)

// ❌ print('debug')
// ✓ AppLogger.d('debug')

// ❌ Navigator.push(context, MaterialPageRoute(builder: ...))
// ✓ context.push('/route') — go_router only

// ❌ FutureBuilder<List<X>>(...)
// ✓ ref.watch(xProvider) — Riverpod only

// ❌ const TextStyle(fontFamily: 'Roboto')
// ✓ const TextStyle() — uses theme default
```

**Linter config (`analysis_options.yaml`):**
```yaml
analyzer:
  errors:
    invalid_annotation_target: ignore
    avoid_print: error
  exclude:
    - '**.g.dart'
    - '**.freezed.dart'

linter:
  rules:
    avoid_print: true
    prefer_const_constructors: true
    use_super_parameters: true
    avoid_unnecessary_containers: true
    sized_box_for_whitespace: true
    sort_pub_dependencies: true
```

---

**END OF TZ**

> _Bu hujjat 26 ta ekrandan iborat o'qituvchi mobil ilovasining to'liq texnik spetsifikatsiyasi. Kunlik checklist'lar bilan 7 kunda v1.1.0 release. Brand teal (#1F6F65) — A'lochi'ning ovozi. Ustoz cho'ntakda._
