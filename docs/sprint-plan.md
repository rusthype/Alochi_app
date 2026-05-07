# A'lochi Teacher Mobile v1.1 — 7-Day Sprint Plan

**Reja muddati:** 03-May (Yakshanba) → 10-May (Yakshanba)
**Maqsad:** Yangi mobile UX'ni 27 ta ekran bilan ishga tushirish
**Repo:** `rusthype/Alochi_app` · branch `v1.1-mobile-redesign`
**Reference:** `docs/teacher-tz.md`, `docs/ux-kit.md`, `docs/alochi-teacher-ui.html`, `assets/branding/` + `assets/avatars/`

---

## Loyiha qoidalari (har kun amal qiling)

- ❌ Hech qanday emoji kodda — Lucide / Material Icons faqat
- ❌ Backend'ga yangi endpoint qo'shilmaydi — mavjudlaridan foydalaniladi
- ❌ `Co-Authored-By` commit'larda yo'q
- ❌ Seed/fake data hech qaerda
- ❌ Mavjud screen kodi bekor o'zgartirilmaydi (faqat refactor zaruriy bo'lsa)
- ✅ Har kun `flutter analyze` 0 errors
- ✅ Har screen bo'yicha alohida commit
- ✅ Real qurilma'da test (iPhone 12 Mini + Samsung Galaxy A51)

---

## Day 0 — 03-May (Yakshanba) — Setup & Audit

**Maqsad:** Branch ochish, mavjud kodni o'rganish, design token'lar yaratish.

### Vazifalar
- [ ] `git checkout -b v1.1-mobile-redesign`
- [ ] `flutter pub outdated` natijasi yozib qo'yiladi (qaysi paketlar eski)
- [ ] `pubspec.yaml` audit: state mgmt qaysi (Riverpod / Bloc / Provider)
- [ ] Mavjud reusable widget'lar ro'yxati (lib/ ichida)
- [ ] Folder structure §1.4 bilan solishtiriladi — qayerda gap bor
- [ ] `lib/theme/colors.dart` — 18 token (brand teal `#1F6F65`, accent coral, semantic, neutrals)
- [ ] `lib/theme/typography.dart` — 10 style (displayL → caption → monoCode)
- [ ] `lib/theme/spacing.dart` — 7 ta token (xs=4 → xxl=32)
- [ ] `lib/theme/radii.dart` — 7 ta token (xs=6 → round=100)
- [ ] `lib/theme/theme.dart` — `AlochiTheme.light` Material 3
- [ ] `MaterialApp` ga ulash (`lib/app.dart` yoki `main.dart`)
- [ ] `flutter analyze` — 0 errors

### Acceptance
- [ ] `Theme.of(context).colorScheme.primary` = `#1F6F65`
- [ ] Mavjud screen'lar hali ham ochiladi (regression yo'q)
- [ ] Branch push qilindi (draft PR)

### Claude Code prompt
```
You are working on A'lochi Teacher Mobile v1.1 sprint, Day 0.
Repository: /Users/max/PycharmProjects/AlochiSchool/alochi_maktab/
Reference: docs/teacher-tz.md
Branch: v1.1-mobile-redesign

Tasks:
1. Audit pubspec.yaml — report state mgmt library (riverpod / bloc / provider)
2. List existing reusable widgets in lib/
3. Check folder structure against §1.4 in teacher-tz.md — note gaps
4. Create lib/theme/ with 5 files exactly per §2 of teacher-tz.md:
   - colors.dart (18 tokens, brand teal #1F6F65 + accent coral #E8954E)
   - typography.dart (10 styles)
   - spacing.dart (xs=4 to xxl=32)
   - radii.dart (xs=6 to round=100)
   - theme.dart (AlochiTheme.light Material 3)
5. Wire AlochiTheme to MaterialApp
6. Verify flutter analyze: 0 errors, 0 warnings
7. Verify existing screens still build
8. Commit: "chore: design system tokens (theme/colors/typography/spacing/radii)"
9. Push as draft PR

Constraints: NO emoji in code, NO backend changes, NO modifying existing screens, NO Co-Authored-By in commit.

Report back: state mgmt library, theme files created, analyze result, any blockers, PR URL.
```

---

## Day 1 — 04-May (Dushanba) — Login + Dashboard

**Maqsad:** 8 ta reusable widget + Login + yangi Dashboard (gorizontal scroll).

### Ertalab (4 soat) — Reusable widgets
- [ ] `AlochiButton` (primary brand, secondary outline, danger, telegram blue, ghost)
- [ ] `AlochiInput` (label, error, prefix/suffix icon, password toggle)
- [ ] `AlochiCard` (white bg, line border, radius lg, padding 16)
- [ ] `AlochiPill` (brand/info/success/warning/danger variantlari)
- [ ] `AlochiAvatar` (circle, initials, sizes 28/40/64)
- [ ] `AlochiBottomNav` (5 tab, teal aktiv)
- [ ] `AlochiAppBar` (back, title, trailing slot)
- [ ] `AlochiEmptyState` (illustratsiya + sarlavha + CTA)

### Tushdan keyin (4 soat) — Login + Dashboard
- [ ] **Login (#1):**
  - [ ] `login_screen.dart` — teal "A" mark + logo
  - [ ] Email + parol input + remember toggle
  - [ ] Validation, loading state
  - [ ] `loginProvider` → POST `/auth/login/`
  - [ ] Token storage (`flutter_secure_storage`)
  - [ ] Auth interceptor `lib/core/api/dio_client.dart` — 401 handling
- [ ] **Dashboard (#2 — yangi shape):**
  - [ ] `dashboard_screen.dart`
  - [ ] `_GreetingHeader` ("Assalomu alaykum, Ustoz" + notif bell)
  - [ ] `TodayLessonsHorizontalList` (PageScrollPhysics, 230px karta width)
  - [ ] `LessonCardActive` (qora bg `#18181B`, "HOZIR" teal badge, "Darsni ochish" CTA)
  - [ ] `LessonCard` (oq bg, time + class pill + subject + count)
  - [ ] `ConcernsSection` (3 ta default + "Hammasi" expand)
  - [ ] `dashboardSummaryProvider` (FutureProvider, 5 daqiqa stale)
  - [ ] GET `/teacher/dashboard/summary/`

### Acceptance
- [ ] Login: noto'g'ri parol → red snackbar, to'g'ri → /dashboard
- [ ] Dashboard "Bugungi darslarim" gorizontal scroll silliq (60fps)
- [ ] Aktiv dars qora karta + HOZIR badge faqat hozirgi vaqt darsda
- [ ] Empty state: bugun dars yo'q → "Bugun darsingiz yo'q · Eski guruhlarni ko'rish"
- [ ] Concern row tap → tegishli sahifaga (overdue/messages/telegram)
- [ ] Pull-to-refresh 1.5s spinner
- [ ] iPhone 12 Mini'da overflow yo'q
- [ ] Lesson card tap → `/lesson/:id` placeholder route (Day 2'da to'ldiriladi)

### Real qurilma test
- [ ] Max'ning haqiqiy account'i bilan login → real dashboard ko'rinadi
- [ ] iPhone 12 Mini: 3+ ta dars'ni gorizontal scroll qilish

### Claude Code prompt
```
Day 1 of v1.1 sprint. Tasks:
1. Implement 8 reusable widgets in lib/shared/widgets/ exactly per §2.4 of teacher-tz.md (AlochiButton, AlochiInput, AlochiCard, AlochiPill, AlochiAvatar, AlochiBottomNav, AlochiAppBar, AlochiEmptyState).
2. Implement Login screen (#1) per §8.1 — teal "A" mark, email/password inputs, validation, POST /auth/login/, token storage, auth interceptor.
3. Implement Dashboard (#2) — new layout per §8.1: greeting + horizontal scroll today's lessons (active lesson black card #18181B with HOZIR teal badge + "Darsni ochish" CTA, others white card with time/class/subject) + ConcernsSection.
4. Lesson card tap → placeholder route /lesson/:id (full screen comes Day 2).
5. Test on iPhone 12 Mini simulator.

Constraints: Use Riverpod, do NOT modify backend, NO emoji in code.
Commit per screen with "feat(<feature>): <what>".
```

---

## Day 2 — 05-May (Seshanba) — Guruhlar + Davomat + Dars boshqaruvi shell

**Maqsad:** Tab 1 (Guruhlar) + Davomat + yangi unified Dars workflow shell.

### Ertalab (4 soat)
- [ ] **Qoldi reusable widgets:**
  - [ ] `AlochiStatusDot` (●  — yashil/amber/qizil)
  - [ ] `AlochiGradeBadge` (2/3/4/5 rangli)
  - [ ] `AlochiAttendanceToggle` (3-state ✓/−/✕)
- [ ] **Guruhlar list (#3):**
  - [ ] `groups_list_screen.dart`
  - [ ] `GroupCard` widget (teal code badge, davomat bar, o'rtacha)
  - [ ] Filter chips (Hammasi · Bugun · Boshlang'ich)
  - [ ] `groupsListProvider`
- [ ] **Guruh Detail (#4):**
  - [ ] `group_detail_screen.dart` + 4 ta tab placeholder
  - [ ] `GroupStatsRow` (3 stat tile)
  - [ ] Tab 1 (O'quvchilar) — `StudentRow` widget
  - [ ] Tab 2-3-4 — placeholder ("Day 4-5'da to'ldiriladi")

### Tushdan keyin (4 soat)
- [ ] **Davomat belgilash (#5):**
  - [ ] `attendance_marking_screen.dart`
  - [ ] `LiveStatsRow` (real-time count)
  - [ ] `AllPresentDashedCta` ("Hammasi keldi" teal dashed)
  - [ ] `StudentAttendanceRow` (3-toggle)
  - [ ] `attendanceMarkingProvider`
  - [ ] `_StickySaveButton` count badge bilan
- [ ] **Dars boshqaruvi shell (#27):**
  - [ ] `lesson_workflow_screen.dart`
  - [ ] `LessonHeader` (back, group + subject + time, jonli status pill)
  - [ ] `WorkflowStepper` (4-segment progress + step labels)
  - [ ] `LessonStepCard` 3 variant (completed yashil / aktiv teal / locked gray)
  - [ ] Step 1 (Davomat) — `attendance_marking_screen` body komponentlarini embed qilish
  - [ ] Steps 2-4 — locked placeholder
  - [ ] `lessonWorkflowProvider.family(lessonId)`
  - [ ] GET `/teacher/lessons/{id}/`
  - [ ] "Tugatish va keyingisi ›" CTA — qadamni o'tkazish
- [ ] **Offline sync skeleton:**
  - [ ] `lib/core/sync/sync_queue.dart` — Hive box `PendingOps`
  - [ ] `connectivity_service.dart` — `connectivity_plus`
  - [ ] `isOnlineProvider`
  - [ ] Davomat save → optimistic + offline bo'lsa queue

### Acceptance
- [ ] Guruhlar list 4 ta haqiqiy guruh backend'dan
- [ ] Tap guruh → detail → Tab 1 students render
- [ ] Davomat: 32 ta o'quvchi, 3-toggle har biri, save → backend
- [ ] Offline: airplane mode → "Saqlanadi (internet kelganda)" snackbar
- [ ] Internet yoqilganda → queue avto-flush + "Saqlandi"
- [ ] Hammasi keldi CTA → 32 ta o'quvchi present
- [ ] **End-to-end:** Dashboard → tap aktiv dars → Dars boshqaruvi → Step 1 → Davomat belgilash → save → step yashil compact bo'ladi

### Real qurilma test
- [ ] Airplane mode: 5-A davomat belgila → save → "Saqlanadi" → internet yoq → "Saqlandi"
- [ ] Galaxy A51: Dashboard → dars → davomat workflow

### Claude Code prompt
```
Day 2. Tasks:
1. Finish 3 remaining widgets (AlochiStatusDot, AlochiGradeBadge, AlochiAttendanceToggle) per §2.4.
2. Guruhlar list (#3) and Guruh Detail (#4 — only Students tab functional) per §8.1.
3. Davomat belgilash (#5) per §8.2.
4. Dars boshqaruvi shell (#27) per §8.1 — Step 1 fully functional reusing attendance components, Steps 2-4 as locked placeholders.
5. Offline-first sync queue per §7.2 — attendance saves work offline, auto-flush on reconnect.
6. End-to-end test: Dashboard → tap active lesson → Dars boshqaruvi opens → mark attendance → save → step turns green compact.
7. Test airplane mode flow on real device.

Constraints: existing endpoints only, no backend changes, NO emoji.
Commit per screen.
```

---

## Day 3 — 06-May (Chorshanba) — Baholar + Vazifalar + Dars steps 2-3

**Maqsad:** Tab 2 (Vazifalar) + Baholar entry + Dars boshqaruvi step 2 va 3.

### Ertalab (4 soat) — Baholar
- [ ] **Baholar entry (#7):**
  - [ ] `grades_entry_screen.dart`
  - [ ] `TopicCard` (sarlavha + sana)
  - [ ] `GradeButtonsRow` (4 ta tugma, qattiq tanlangan)
  - [ ] Avto-hisoblanadigan o'rtacha
  - [ ] `gradesEntryProvider`
  - [ ] POST `/teacher/grades/bulk/`
- [ ] **Davomat tarixi (#22)** — Guruh detail Davomat tab'iga embed
  - [ ] `attendance_history_widget.dart`
  - [ ] Stacked bar chart minimal (zoom yo'q V1.1)

### Tushdan keyin (4 soat) — Vazifalar
- [ ] **Vazifalar list (#8):**
  - [ ] `homework_list_screen.dart`
  - [ ] `HomeworkRow` (status pill rang-rang)
  - [ ] Filter (Hamma · Faol · O'tgan · Tugadi)
- [ ] **Vazifa create (#9):**
  - [ ] `homework_create_screen.dart`
  - [ ] Quick date chips (Bugun · Erta · 3 kun · 1 hafta)
  - [ ] 3 toggle row (Telegram poll · Eslatma · Avto-kuzatuv)
  - [ ] `homeworkCreateProvider`
- [ ] **Vazifa detail (#21 basic):**
  - [ ] `homework_detail_screen.dart`
  - [ ] Stat hero card
  - [ ] Tab default Topshirilmagan
  - [ ] Bulk remind tugmasi
- [ ] **Dars boshqaruvi Step 2 (Vazifa tekshirish):**
  - [ ] `lesson_step_homework_review.dart`
  - [ ] Topshirilmagan o'quvchilar list
  - [ ] "Eslatma" har birida
  - [ ] "Hammaga eslatma" + "Tugatish va keyingisi"
- [ ] **Dars boshqaruvi Step 3 (Baho/Aktivlik):**
  - [ ] `lesson_step_grading.dart`
  - [ ] Aktivlik 3-rating per student (Yaxshi/O'rta/Zaif)
  - [ ] V1.1 minimum: faqat aktivlik (topic baho V1.2)

### Acceptance
- [ ] Baholar entry: 4 ta tugma rang-rang, tap → backend save
- [ ] Vazifalar list: real backend'dan vazifalar status pill rang-rang
- [ ] Vazifa create: teal CTA, success → list'ga qaytish + snackbar
- [ ] Dars boshqaruvi: Step 2 active → vazifa tekshirildi → Step 3 active
- [ ] Dars boshqaruvi: Step 3 aktivlik baholash → save → Step 4 unlock

### Claude Code prompt
```
Day 3. Tasks:
1. Baholar entry (#7) per §8.2 — TopicCard, 4-color GradeButtonsRow, auto-average.
2. Vazifalar list (#8), Vazifa create (#9), Vazifa detail (#21 basic — submissions list + bulk remind, NO poll results).
3. Davomat tarixi (#22) — embed in Guruh detail Davomat tab, simple stacked bar chart.
4. Dars boshqaruvi Step 2 (homework review) and Step 3 (activity rating) per §8.1 Screen 27.
5. End-to-end: open lesson → complete steps 1-2-3 → step 4 unlocks.

Constraints: existing endpoints, NO backend changes.
Commit per screen.
```

---

## Day 4 — 07-May (Payshanba) — Xabarlar + Bola profili + Dars step 4

**Maqsad:** Tab 3 (Xabarlar) + Bola profili + Dars boshqaruvi yakunlovchi qadam.

### Ertalab (4 soat) — Xabarlar
- [ ] **Xabarlar list (#10):**
  - [ ] `messages_list_screen.dart`
  - [ ] `ConversationRow` (avatar + name + last message + time)
  - [ ] "Otasi:" / "Onasi:" / "Siz:" prefix'lar
  - [ ] Yangi xabarlar yashil ●
  - [ ] `conversationsProvider`
- [ ] **Chat thread (#11):**
  - [ ] `chat_thread_screen.dart`
  - [ ] `ChildContextCard` yuqorida (Davomat % + O'rtacha)
  - [ ] `MessageBubble` (siz teal brand, ota-ona oq border)
  - [ ] `MessageComposer` (multiline)
  - [ ] AI tavsiyalar chip 2 ta tezkor javob
- [ ] **WebSocket integration:**
  - [ ] `lib/core/ws/ws_client.dart`
  - [ ] Reconnect on disconnect
  - [ ] Real-time chat update

### Tushdan keyin (4 soat) — Bola profili + Dars step 4
- [ ] **Bola profili (#20):**
  - [ ] `child_profile_screen.dart`
  - [ ] Avatar 84 + name + 5-A · 14 yosh
  - [ ] 14 kunlik kalendar (yashil/sariq/qizil tile)
  - [ ] 3 ta otasi/onasi T tugmasi
  - [ ] "Ustoz izohi" private notes (read-only V1.1)
- [ ] **Dars boshqaruvi Step 4 (Yangi vazifa):**
  - [ ] `lesson_step_new_homework.dart`
  - [ ] Sarlavha + tavsif input
  - [ ] Quick date chips
  - [ ] Telegram poll toggle (ko'k T)
  - [ ] "Vazifa berish va darsni yakunlash" CTA
  - [ ] Publish → snackbar "Dars yakunlandi" → /dashboard

### Acceptance
- [ ] Xabarlar list: real conversation'lar, yashil ● yangi
- [ ] Chat thread: WebSocket real-time — yangi xabar avtomatik qo'shiladi
- [ ] Bola profili: davomat <75% va o'rtacha <3.5 → amber "Diqqat talab"
- [ ] Dars boshqaruvi: Step 4 publish → vazifa yaratiladi (real backend) → Telegram poll yuboriladi (real bot)
- [ ] Dars yakunlangach Dashboard'ga qaytish + snackbar

### Real qurilma test
- [ ] iPhone Pro va Galaxy A51'da real-time WebSocket sinov
- [ ] Dars yakunlash → real-life test (Max'ning haqiqiy 5-A guruhi)

### Claude Code prompt
```
Day 4. Tasks:
1. Xabarlar list (#10), Chat thread (#11), WebSocket client per §7.3.
2. Bola profili (#20) — avatar, 14-day calendar, 3 buttons (otasi/onasi T/phone), read-only notes.
3. Dars boshqaruvi Step 4 (new homework form) per §8.1 Screen 27.
4. Final lesson workflow: complete all 4 steps → publish → "Dars yakunlandi" snackbar → back to dashboard.
5. Real-time WebSocket test on real device.

Constraints: existing endpoints, NO backend changes.
Commit per screen.
```

---

## Day 5 — 08-May (Juma) — AI yordamchi + Telegram (yangi model)

**Maqsad:** AI flow + Telegram ota-onalarni taklif qilish (NO teacher account linking).

### Ertalab (4 soat) — AI
- [ ] **AI welcome (#12):**
  - [ ] `ai_welcome_screen.dart`
  - [ ] `AiHeroGreeting` (teal gradient)
  - [ ] 6 ta `AiTemplateCard` (har biri o'z rangida)
  - [ ] `RecentSessionsList`
  - [ ] Bottom composer
- [ ] **AI chat with lesson plan (#13):**
  - [ ] `ai_chat_screen.dart`
  - [ ] `AiMessageBubble` (token streaming)
  - [ ] `LessonPlanCard` (header + 5 stage rows + footer CTA)
  - [ ] `FollowUpChips` (+ Test / + Soddaroq qil)
  - [ ] SSE client wrapper for `dio`
  - [ ] "+ Vazifaga qo'sh" → bottom sheet → POST homework

### Tushdan keyin (4 soat) — Telegram (yangi model)
- [ ] **Telegram ota-onalar (#26):**
  - [ ] `telegram_parents_screen.dart`
  - [ ] `_ExplainerBanner` ("Sizning Telegram akkauntingiz kerak emas...")
  - [ ] `GroupSubscriptionChips` (gorizontal, 5-A 28/30 har birida)
  - [ ] `GroupSubscriptionStatusCard` (% + progress bar + legend)
  - [ ] `GroupInviteQrWidget` (`qr_flutter` 160×160 + ko'k T overlay)
  - [ ] `_InviteLinkBox` (mono link + copy)
  - [ ] `UnlinkedParentsCard` (ulanmaganlar list + SMS yubor)
  - [ ] `telegramParentsProvider`
  - [ ] GET `/teacher/telegram/groups-status/`
  - [ ] GET `/teacher/telegram/groups/{id}/unlinked-parents/`
  - [ ] Share via `share_plus` — native share sheet
  - [ ] **Hech qanday teacher account linking UI yo'q**

### Acceptance
- [ ] AI welcome 6 template kartasi mockup'ga to'liq mos
- [ ] AI chat: token streaming silliq (jank yo'q)
- [ ] Lesson plan card render strukturali (5 stage row + teal time pill)
- [ ] "+ Vazifaga qo'sh" → bottom sheet → vazifa real yaratiladi
- [ ] Telegram screen: 4 guruh chips, har birida correct linked/total
- [ ] Group chip switch → QR + status card darrov yangilanadi
- [ ] QR Telegram'dan skan qilinadi → bot deep link ochiladi
- [ ] "Linkni ulashish" → native share sheet
- [ ] Ulanmagan ota-ona "SMS yubor" → POST → snackbar success
- [ ] **App'da hech qaerda "Telegram'ni ulang" UI yo'q ustoz uchun**

### Real qurilma test
- [ ] Real ota-ona telefoni: QR skan → @alochi_uz_bot ochiladi → /start group_5A → bot welcome message
- [ ] Backend tekshirish: `TelegramLink(parent_id, group_id)` yaratildimi
- [ ] App'ga qaytish: ulangan parents +1 ko'rsatadimi

### Claude Code prompt
```
Day 5. Tasks:
1. AI welcome (#12), AI chat with lesson plan (#13) — SSE streaming, structured output detection, "+ Vazifaga qo'sh" bottom sheet.
2. Telegram parent-invitation screen (#26) — NEW MODEL per §5.7. Teacher's personal Telegram is NEVER linked. Display per-group QR codes and invite links. Parents subscribe to bot via deep link, backend dispatches messages. Use existing endpoints in §5.3. Use qr_flutter for QR, share_plus for share sheet. Test full flow with real parent device scanning real QR.

CRITICAL: NO teacher Telegram link UI anywhere. The screen is "Ota-onalar Telegram'da" — purely an invitation tool.

Constraints: existing endpoints, NO backend changes.
Commit per screen.
```

---

## Day 6 — 09-May (Shanba) — Profile + Onboarding

**Maqsad:** Profile flow + onboarding (3 → 1 ekranga qisqartirilgan V1.1).

### Ertalab (4 soat)
- [ ] **Profile (#6):**
  - [ ] `profile_screen.dart`
  - [ ] `ProfileHero` (avatar 84 + brand ring)
  - [ ] `PrideCard` (teal gradient — gamification)
  - [ ] `ProfileStatsRow`
  - [ ] `ProfileSettingsList` (Apple-style colored squares)
  - [ ] Telegram qatori → "5-A: 28/30 ota-ona ulangan" (yangi modelga mos)
  - [ ] Logout flow
- [ ] **Profile edit (#24):**
  - [ ] `profile_edit_screen.dart`
  - [ ] Avatar uploader (teal + tugma)
  - [ ] Email locked (kichkina L ikon)
  - [ ] Fanlar chips teal tinted X bilan
  - [ ] iOS form pattern (Bekor / Saqlash top bar)

### Tushdan keyin (4 soat)
- [ ] **Parol o'zgartirish (#25):**
  - [ ] `password_change_screen.dart`
  - [ ] Amber warning karta
  - [ ] Strength meter 4 segment
  - [ ] 5 ta talab checkbox
  - [ ] Save tugma muted teal disabled state
- [ ] **Welcome onboarding (#14):**
  - [ ] `welcome_onboarding_screen.dart`
  - [ ] Teal "A" mark + atrofdagi shakl'lar
  - [ ] "Ustoz" kichik teal aksent
  - [ ] "O'tkazib yuborish" link top right
  - [ ] First-launch flag (`flutter_secure_storage`)
- [ ] **Loose ends:**
  - [ ] Notification screen (V1.1 minimum)
  - [ ] Logout confirmation dialog
  - [ ] App version info modal

### Acceptance
- [ ] Profile: Pride card "Top 3 o'qituvchidan birisiz" gradient
- [ ] Telegram qatori yangi statusni ko'rsatadi (eski "Ulangan/Ulanmagan" o'rniga "X/Y ota-ona ulangan")
- [ ] Avatar uploader → galereyadan rasm tanlanadi → upload → render
- [ ] Parol: zaif → strength meter 1 segment, kuchli → 4 segment
- [ ] Welcome onboarding faqat birinchi marta ko'rinadi
- [ ] Logout → token o'chiriladi → /auth/login

### Claude Code prompt
```
Day 6. Tasks:
1. Profile (#6) — ProfileHero, PrideCard, ProfileStatsRow, ProfileSettingsList. Telegram row shows "5-A: 28/30 ota-ona ulangan" (NEW model — never "Ulangan/Ulanmagan").
2. Profile edit (#24) — avatar upload, locked email, fanlar chips.
3. Parol o'zgartirish (#25) — strength meter, 5 requirements checklist, disabled save until valid.
4. Welcome onboarding (#14) — single screen, first-launch only.
5. Logout flow, notification screen V1.1 minimum.

Constraints: existing endpoints, NO backend changes.
Commit per screen.
```

---

## Day 7 — 10-May (Yakshanba) — Patterns + QA + RELEASE

**Maqsad:** Universal patterns + sifat tekshiruvi + production release.

### Ertalab (4 soat) — Patterns
- [ ] **Empty state pattern (#17):**
  - [ ] `AlochiEmptyState` final polish
  - [ ] 6 ta variant (no homework, no messages, no attendance, etc.)
- [ ] **Loading skeleton pattern (#18):**
  - [ ] `AlochiSkeleton` (pulse animation 1.6s)
  - [ ] Shimmer effect optional
  - [ ] List skeleton, card skeleton, detail skeleton
- [ ] **Error/Offline pattern (#19):**
  - [ ] Top amber offline banner
  - [ ] "Yangilangan: 2 soat oldin" yozuvi
  - [ ] Bottom red error toast + Qaytadan
  - [ ] Wi-Fi xira ikon offline holatda
- [ ] **List screen integration:**
  - [ ] Guruhlar list → empty/loading
  - [ ] Vazifalar list → empty/loading
  - [ ] Xabarlar list → empty/loading
  - [ ] Davomat list → empty/loading

### Tushdan keyin (3 soat) — QA & Release
- [ ] **QA session — 3 ta o'qituvchi bilan:**
  - [ ] Login → Dashboard → 5-A darsi → Davomat → Vazifa tekshirish → Baho → Yangi vazifa → yakun
  - [ ] Telegram'ga ota-ona taklif qilish (real telefon bilan)
  - [ ] AI lesson plan → Vazifaga qo'shish
  - [ ] Offline rejim sinovi
  - [ ] Bug list yig'ish
- [ ] **Bug fixes:**
  - [ ] Top 5 critical bug
  - [ ] Visual polish (typography, spacing)
  - [ ] Performance (cold start <2.5s Pixel 4a'da)
- [ ] **Build & Release:**
  - [ ] `flutter build apk --release` (Android)
  - [ ] `flutter build ipa --release` (iOS)
  - [ ] APK upload Play Console internal track
  - [ ] iOS upload TestFlight
  - [ ] Release notes: "v1.1 — Yangi mobile UX, 27 ekran, Dars boshqaruvi"

### Acceptance criteria — V1.1 Release Gate
- [ ] `flutter analyze` — 0 errors, 0 warnings
- [ ] `dart format` — barcha fayllar
- [ ] APK size < 50 MB
- [ ] Cold start < 2.5s (Pixel 4a)
- [ ] Memory peak < 300 MB
- [ ] Real backend bilan ishlaydi (no mock)
- [ ] Real Telegram bot bilan ishlaydi
- [ ] Offline mode test pass
- [ ] 3 ta o'qituvchi bilan QA pass

### Real qurilma test
- [ ] iPhone 12 Mini (iOS 16+)
- [ ] iPhone 14/15 Pro
- [ ] Samsung Galaxy A51 (Android 11)
- [ ] Pixel 4a (Android 13)
- [ ] Xiaomi Redmi 9 (kuchsiz qurilma)

### Claude Code prompt
```
Day 7 — final day. Tasks:
1. Pattern widgets (Empty/Loading/Error) per §8.3.
2. Integrate patterns into all list screens (groups, homework, messages, attendance) and detail screens.
3. Build APK and iOS archive.
4. Coordinate QA session with 3 teachers.
5. Bug fix list at end of day.
6. Release v1.1.0 to TestFlight + Play Console internal track.

NO new features after Day 7 morning — only fixes.

Constraints: cold start <2.5s, no analyze warnings, real backend, real Telegram bot.
```

---

## Sprint summary

| Kun | Sana | Ekran | Asosiy ish |
|---|---|---|---|
| 0 | 03-May Ya | — | Theme tokens, branch, audit |
| 1 | 04-May Du | #1, #2 | 8 widget, Login, **yangi Dashboard** |
| 2 | 05-May Se | #3, #4, #5, #27 shell | Guruhlar, Davomat, **Dars boshqaruvi shell + Step 1** |
| 3 | 06-May Cho | #7, #8, #9, #21, #22, #27 step 2-3 | Baholar, Vazifalar, **Dars Steps 2-3** |
| 4 | 07-May Pa | #10, #11, #20, #27 step 4 | Xabarlar, Chat WS, Bola profili, **Dars Step 4 yakun** |
| 5 | 08-May Ju | #12, #13, #26 | AI, **Telegram yangi model** |
| 6 | 09-May Sha | #6, #24, #25, #14 | Profile, Onboarding |
| 7 | 10-May Ya | #17, #18, #19 + QA | Patterns, QA, **v1.1.0 RELEASE** |

**Jami:** 22 ekran V1.1'da · qolganlari V1.2'ga ko'chirilgan
**Yangi:** Dars boshqaruvi (#27) — markaziy unified workflow
**Telegram:** ustoz akkauntsiz, ota-onalar bot'ga obuna model

---

## Kunlik ritual

**Har kun ertalab (15 daq):**
1. `git pull origin v1.1-mobile-redesign`
2. `flutter pub get`
3. Bugungi checklist'ni ochish
4. Claude Code prompt'ni copy-paste qilish

**Har kun kechki (15 daq):**
1. `flutter analyze` → 0 errors bo'lsa o'tkazish
2. `git push origin v1.1-mobile-redesign`
3. Bugungi acceptance ni belgilash
4. Ertangi kun checklist'ini o'qib chiqish

**Hafta oxiri (Day 7):**
- Release notes yozish
- TestFlight + Play Console internal upload
- 3 ustozni qo'ng'iroq qilib QA session belgilash

---

## Kritik xavf nuqtalari

| Xavf | Probability | Reduction |
|---|---|---|
| Backend yangi endpoint kerak bo'lib qolish | Past | TZ §5.3 strict — mavjudlardan foydalanish |
| Offline sync race condition | O'rtacha | Hive box + idempotent endpoint'lar |
| Telegram bot real-time yuklash sekin | O'rtacha | Day 5'da real bot bilan early test |
| AI streaming jank katta lesson plan'da | Past | Day 5 morning mockup'ga moslab debug |
| Bola profili Davomat tarixi katta data | Past | Pagination 14 kun limit |
| Day 7'gacha bug list 30+ ga yetadi | O'rtacha | Day 4-5'da kunlik QA + ranking |

---

## V1.1 dan keyin (V1.2 reja, ma'lumot uchun)

- Onboarding 2/3 va 3/3 (animatsiyalar)
- Vazifa detail full poll results card
- Compose new message screen
- Guruh detail Tahlil tab
- Topic-based grading (Dars Step 3 to'liq)
- Tug'ilgan kun, mukofotlar, gamification
- Dark mode

V1.2 sprint reja keyin tuziladi.
