# A'lochi Mobile App — GEMINI.md

> Gemini CLI uchun loyiha konteksti. Sessiya boshlanganda avtomatik o'qiladi.

## Loyiha haqida

**A'lochi** — O'zbekiston maktab o'quvchilari uchun gamified ta'lim platformasi. Mobil ilovaning **bitta APK** ichida 3 ta rol bor: o'quvchi (student), ota-ona (parent), ustoz (teacher). Login orqali avtomatik aniqlanadi.

**Joriy holat (2026-05):** Student/Parent funksiyalari yozilgan. **Teacher (ustoz)** funksiyalari V1.1 sprint'ida qo'shilmoqda — 7 kunlik reja, 22 ta yangi ekran.

**Sizning (Gemini) asosiy vazifangiz:** Flutter Android ilovasi uchun ustoz qismini quyish. Day 0 tugadi (theme tokenlar tayyor). Hozir Day 1-7 sprint davom etmoqda.

## Texnologiyalar

- **Flutter:** 3.41.4 stable, Dart 3.8+ null safety majburiy
- **State management:** flutter_riverpod 2.6.1
- **Routing:** go_router 14.8.1
- **HTTP:** Dio (lib/core/api/api_client.dart) — api.alochi.org bilan ulangan
- **Charts:** fl_chart 0.69.2
- **Storage:** flutter_secure_storage + Hive + sqflite
- **Icons:** Material Icons + lucide_icons (NEVER emoji)
- **Java JDK:** 17 (NOT 26 — Gradle xato beradi)
- **Android SDK:** 36.0.0
- **Min Android:** 8.0 (API 26)
- **Target:** Android-only (V1.1 da iOS YO'Q)

## Loyiha tuzilmasi

```
alochi_app/
├── lib/
│   ├── main.dart                  ← Entry point
│   ├── app/                       ← MaterialApp + router
│   ├── theme/                     ← Design tokens (Day 0 da yaratildi)
│   │   ├── colors.dart            ← AppColors — brand teal #1F6F65
│   │   ├── typography.dart        ← AppTextStyles — 10 style
│   │   ├── spacing.dart           ← AppSpacing
│   │   ├── radii.dart             ← AppRadii
│   │   └── theme.dart             ← AlochiTheme.light Material 3
│   ├── core/
│   │   ├── api/                   ← api_client.dart, auth_api.dart
│   │   ├── models/                ← UserModel, etc.
│   │   └── storage/               ← secure_storage, hive
│   ├── shared/
│   │   ├── constants/
│   │   └── widgets/               ← 8 reusable widget (Day 1 da yaratiladi)
│   └── features/
│       ├── auth/                  ← MAVJUD — login_screen, auth_provider
│       ├── landing/               ← MAVJUD — student/parent landing
│       ├── journey/               ← MAVJUD — student journey
│       ├── shop/                  ← MAVJUD — student shop
│       ├── tests/                 ← MAVJUD — student tests
│       ├── gamification/          ← MAVJUD — XP, leaderboard
│       ├── parent/                ← MAVJUD — parent dashboard
│       └── teacher/               ← YANGI — V1.1 sprint'ida yaratiladi
│           ├── auth/              ← Day 1
│           ├── dashboard/         ← Day 1
│           ├── groups/            ← Day 2-3
│           ├── attendance/        ← Day 2
│           ├── homework/          ← Day 3
│           ├── messages/          ← Day 4
│           ├── ai/                ← Day 5
│           ├── telegram/          ← Day 5
│           └── profile/           ← Day 6
├── docs/                          ← TZ + sprint plan + UX kit + mockup
│   ├── DESIGN.md
│   ├── teacher-tz.md              ← 3500+ qator texnik topshiriq
│   ├── sprint-plan.md             ← 7-kunlik sprint plan
│   ├── ux-kit.md                  ← Cross-cutting patterns
│   ├── day-0-readiness.md         ← Setup checklist
│   └── mockup/
│       └── alochi-teacher-ui.html ← 27 ekran mockup
└── assets/
    ├── animations/                ← MAVJUD
    ├── icons/                     ← MAVJUD
    ├── images/                    ← MAVJUD
    ├── branding/                  ← YANGI — logo, app icon, splash
    └── avatars/                   ← YANGI — 6 ta default avatar
```

## Backend API

**Base URL:** `https://api.alochi.org/api/v1`
**Auth:** JWT (POST `/auth/login` — trailing slash YO'Q, `username` field)

### Login (real, verified 2026-05-04)

```bash
curl -X POST https://api.alochi.org/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"shoiraxon_0579","password":"NDRNLxVHYu"}'
```

Response: `{access, access_token, user: {id, username, name, role: "teacher", school, schoolId}}`

### Test akkauntlar (panel teacher'lar)

| Username | Password | Tafsilot |
|---|---|---|
| `shoiraxon_0579` | `NDRNLxVHYu` | Yusupova Shoiraxon, 2-guruh Math, 11 student |
| `muyassarxon_7066` | `m6XyaAY5CX` | Hamraqulova, English, 10 student |
| `teacher_39` | `Teacher@39` | Niyazova (legacy) |

### Asosiy teacher endpoint'lari (verified)

```
GET  /teacher/panel/dashboard/         → attendance_today, top_students, weekly_activity
GET  /teacher/panel/groups/            → results: [{id, name, subject, student_count}]
GET  /teacher/panel/groups/{id}/attendance/  → per-student daily attendance
POST /teacher/attendance/save/         → davomatni saqlash
GET  /teacher/students/                → o'quvchilar ro'yxati
GET  /teacher/students/{id}/portfolio/ → bola profili
GET  /teacher/grades/                  → baholar
POST /teacher/grades/set/              → baho qo'yish
GET  /teacher/timetable/               → haftalik jadval
GET  /teacher/homework/                → vazifalar
POST /teacher/homework/{hw_id}/remind/ → eslatma
GET  /teacher/messages/                → conversations
POST /teacher/messages/{id}/send/      → xabar yuborish
GET  /teacher/notifications/
GET  /teacher/profile/
GET  /teacher/settings/profile/
GET  /teacher/ai/chat/                 → AI yordamchi
GET  /teacher/analytics/
GET  /teacher/reports/
```

To'liq endpoint matrix: `docs/teacher-tz.md` §5.3

### Yetishmaydigan endpoint'lar (V1.1 da boshqa agent yozadi)

```
GET /teacher/telegram/groups-status/                    — per-group parent stats
GET /teacher/telegram/groups/{id}/unlinked-parents/     — ulanmagan ota-onalar
```

## Loyihani ishga tushirish

```bash
# Java 17 majburiy (JDK 26 ishlamaydi)
export JAVA_HOME=$(/usr/libexec/java_home -v 17)

# Dependencies
flutter pub get

# Kodi tekshirish
flutter analyze          # 0 errors talab qilinadi

# Telefonda ishga tushirish
flutter devices
flutter run -d 24115RA8EG  # Galaxy A51 / Xiaomi

# APK build
flutter build apk --debug
```

## Brand qoidalari

**Asosiy ranglar:**
- Brand teal: `#1F6F65` (logodan olingan, qattiq)
- Accent coral: `#E8954E` — STRICT 4 o'rin: AI welcome, AI tile, Pride card, achievements
- Status: success `#0F9A6E`, warning `#D97706`, danger `#DC2626`, info `#0EA5E9`

**Universal salutation:** "Ustoz" (ism qo'shilmaydi)

**Terminologiya:**
- "Sinflar" → "Guruhlar" (global)
- "Class" → "Group"

**Logo:** `assets/branding/tree-silhouette.svg` (multi-color daraxt)

## Sprint statusi (V1.1 — 03-May → 10-May 2026)

| Kun | Sana | Maqsad | Status |
|---|---|---|---|
| Day 0 | 03-May Sun | Theme tokens, setup | ✅ Tugadi (719e972) |
| Day 1 | 04-May Mon | 8 widget + Login + Dashboard | 🟡 Hozir |
| Day 2 | 05-May Tue | Guruhlar + Davomat + Dars #27 shell | ⏳ |
| Day 3 | 06-May Wed | Baholar + Vazifalar + Dars Steps 2-3 | ⏳ |
| Day 4 | 07-May Thu | Xabarlar + Bola profili + Dars Step 4 | ⏳ |
| Day 5 | 08-May Fri | AI + Telegram parents | ⏳ |
| Day 6 | 09-May Sat | Profile + Onboarding | ⏳ |
| Day 7 | 10-May Sun | Patterns + QA + RELEASE | ⏳ |

**Branch:** `v1.1-mobile-redesign`

## Loyiha qoidalari (har kun amal qiling)

### KO'CHA QILINADIGAN
- ❌ Hech qanday emoji kodda — `Lucide` / `Material Icons` faqat
- ❌ `Co-Authored-By` commit'larda
- ❌ Seed/fake data hech qaerda
- ❌ Mavjud student/parent screen kodi modifikatsiya qilinmaydi
- ❌ Yangi backend endpoint qo'shilmaydi (Telegram dan tashqari)
- ❌ JDK 26 (faqat 17)
- ❌ Yangi dependency `pubspec.yaml`'ga so'ramasdan qo'shilmaydi
- ❌ iOS bilan ishlash (V1.1 Android-only)

### MAJBURIY QILINADIGAN
- ✅ Har kun `flutter analyze` 0 errors
- ✅ Real qurilma test (Xiaomi `24115RA8EG`)
- ✅ Brand teal `#1F6F65` qattiq
- ✅ Theme tokens'dan foydalanish (`AppColors.brand`, etc.)
- ✅ Har screen alohida commit
- ✅ `dart format` har commit'dan oldin
- ✅ Code in English, comments in Uzbek

## Mandatory coding rules

### Theme tokens — never hardcode
```dart
// CORRECT
Container(color: AppColors.brand)
Text('Salom', style: AppTextStyles.titleM)

// WRONG
Container(color: Color(0xFF1F6F65))
```

### ID parsing
```dart
final id = json['id']?.toString() ?? '';
```

### List safety
```dart
if (list.isEmpty) return [];
return list.map((e) => Model.fromJson(e)).toList();
```

### API calls
```dart
try {
  final result = await api.getDashboard();
  return result;
} catch (e, stackTrace) {
  debugPrint('Dashboard error: $e');
  rethrow;
}
```

### Avatar colors (deterministic)
```dart
Color getAvatarColor(String name) {
  final hash = name.codeUnits.fold(0, (prev, e) => prev + e);
  final colors = [
    AppColors.brand, Colors.indigo, Colors.purple,
    Colors.teal, Colors.orange, Colors.pink,
  ];
  return colors[hash % colors.length];
}
```

## Common bugs to avoid

1. **`Size.fromHeight(48)` Row ichida xato** → `Size(0, 48)` ishlatish
2. **JDK 26 Gradle bilan ishlamaydi** → JDK 17 majburiy
3. **`/auth/login`'da trailing slash bo'lmaydi** → boshqa endpoint'larda bor
4. **Login response'da `email: ""`** — to'g'ri, ustozlarda email yo'q
5. **`role: "teacher"` lekin `school: null`** — panel-only teacher
6. **Advisories warning `pub get`'da** — ignore qilish mumkin

## Custom commands (slash commands)

`.gemini/commands/` ichida 4 ta rol:
- `/flutter` — Flutter mobile engineering ish
- `/ui` — UI/widget dizayn
- `/qa` — Test va regression tekshiruvlar
- `/pm` — Sprint koordinatsiyasi va scope decisions

Ishlatish:
```
/flutter Build Day 1 — 8 widgets + login + dashboard
/ui Create AlochiButton variants per docs/teacher-tz.md §2
/qa Run Day 1 acceptance check
/pm Backend mismatch — what do we do?
```

## Bog'liq loyihalar

| Loyiha | Yo'l | Repo |
|---|---|---|
| Backend (Django) | `~/PycharmProjects/AlochiSchool/alochi/alochi_backend/` | `rusthype/alochi` |
| Web frontend (Next.js) | `~/PycharmProjects/alochi-main/` | yo'q |
| School backend | `~/PycharmProjects/AlochiSchool/alochi_maktab/` | `rusthype/Alochi_school` |
| **Mobile (BU LOYIHA)** | `~/PycharmProjects/AlochiSchool/alochi_app/` | `rusthype/Alochi_app` |

**Server:** `198.163.206.64`, SSH port 2222, user `alochi-deployer`

## Asosiy hujjatlar (har kun o'qing)

1. `docs/teacher-tz.md` — Texnik topshiriq
2. `docs/sprint-plan.md` — Day 0-7 reja
3. `docs/ux-kit.md` — Cross-cutting patterns
4. `docs/mockup/alochi-teacher-ui.html` — 27 ekran mockup

## Verification before commit

```bash
flutter analyze              # 0 errors required
dart format lib/             # format
flutter build apk --debug    # must succeed
```

## Foydali skript'lar

```bash
# Real backend bilan login test
TOKEN=$(curl -s -X POST https://api.alochi.org/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"shoiraxon_0579","password":"NDRNLxVHYu"}' \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['access'])")

# Endpoint test
curl -H "Authorization: Bearer $TOKEN" \
  https://api.alochi.org/api/v1/teacher/panel/dashboard/ | python3 -m json.tool
```

## Hisobot tili

Har vazifadan keyin **Uzbek tilida** hisobot bering:
- Yaratilgan fayllar
- `flutter analyze` natijasi
- APK debug size
- Commit SHA
- Real qurilma test natijasi
- Bloklar
- Keyingi qadam taklifi
