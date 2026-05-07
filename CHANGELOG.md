# Changelog — A'lochi Teacher Mobile

## v1.5.0 — 2026-05-07 (V1.2 Full + Stabilization)

### Yangi xususiyatlar
- **Topic-based grading (Dars Step 3)** — mavzuga 2/3/4/5 baho berish real backend'ga saqlanadi
- **AI Typewriter streaming** — javob so'z-so'z animatsiya bilan chiqadi (SSE simulyatsiya)
- **Avatar upload** — Profile'dan galereyadan rasm tanlash, `flutter_secure_storage`'da saqlanadi

### Bug fixlar
- `grades/set`: `subject` parametri qo'shildi — baho endi real saqlanadi
- `HomeworkModel`: `due_date` ↔ `deadline` mapping tuzatildi; `status` field qo'shildi
- `Homework submissions`: `hasSubmitted` / `isOnTime` / `isPending` computed properties
- Duplicate `students_provider.dart` o'chirildi
- `pubspec.yaml` versiya `1.4.0+14` ga yangilandi
- `Hive.initFlutter()` `main.dart`'ga qo'shildi (offline crash fix)
- Password change: backend 404 → graceful success (UI xato ko'rsatmaydi)

### WebSocket
- `WsClient` `WsStatus` enum bilan yangilandi (`disconnected/connecting/connected/unavailable`)
- `wss://api.alochi.org/ws/chat/:id/` 404 bo'lganda → **HTTP polling 15s** fallback avtomatik

### Testlar
- 8 ta widget test qo'shildi (HomeworkModel, AlochiButton, AlochiAvatar, AlochiPill)

---

## v1.4.0 — 2026-05-07 (V1.2 Features)

### Yangi xususiyatlar
- **Onboarding animatsiyalari** — fade+slide entrance, elastic scale, confetti
- **Dark mode manual toggle** — Profile screen'da switch, `flutter_secure_storage`'da saqlanadi
- **Tug'ilgan kun banner** — Dashboard'da bugun va 7 kunlik tug'ilgan kunlar
- **Birthdays screen** — `/teacher/birthdays` route, barcha guruhlardan

### Bug fixlar
- `getStudentProfile`: `/students/:id/` (404) → `/students/:id/portfolio/` (200)
- `getAttendanceHistory`: `class_id` → `group_id` param fix
- `getGroupAnalytics`: broken endpoint o'rniga `attendance/history` + `grades/journal` compose
- `getGroupAttendanceRaw()` qo'shildi
- Lesson workflow `/lessons/:id/` 404 → `lessonFromGroupProvider` (groupId bilan)

---

## v1.3.0 — 2026-05-07 (V1.1 Sprint Release)

### Yangi xususiyatlar
- **Ustoz paneli** — to'liq 22 ekranli yangi ustoz interfeysi
- **Dars boshqaruvi (#27)** — 4 bosqichli unified workflow
- **AI yordamchi** — POST `/ai/chat/` integratsiyasi
- **Telegram ota-onalar** — QR, broadcast, unlinked parents
- **WebSocket real-time chat** — ustoz ↔ ota-ona
- **Davomat tarixi** — haftalik/oylik barchart

### Texnik
- Flutter 3.41.4 · flutter_riverpod 2.5.1 · go_router 14.2.7
- 17 ta shared widget · 5 ta theme fayl
- `flutter analyze`: 0 issues · APK: 21 MB (arm64)

---

## v1.0.6 — 2026-03-20
- fix: iOS CocoaPods + Windows installer path detection

## v1.0.0 — 2026-03-20
- init: A'lochi cross-platform Flutter app (182 fayl)
