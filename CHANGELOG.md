# Changelog — A'lochi Teacher Mobile

## v1.3.0 — 2026-05-10 (V1.1 Sprint Release)

### Yangi xususiyatlar
- **Ustoz paneli** — to'liq 22 ekranli yangi ustoz interfeysi
- **Dars boshqaruvi (#27)** — 4 bosqichli unified workflow:
  1. Davomat belgilash (real-time)
  2. Uy vazifasini tekshirish
  3. Aktivlikni baholash (Zaif/O'rta/Yaxshi)
  4. Darsni yakunlash + yangi vazifa berish
- **AI yordamchi** — dars rejasi tuzishda Claude AI yordam beradi
- **Telegram ota-onalar** — bot orqali ota-onalarni ulash, QR kod, unlinked ro'yxat
- **WebSocket real-time chat** — ustoz ↔ ota-ona/o'quvchi xabarlar
- **Davomat tarixi** — haftalik/oylik/choraklik barchart + past davomatlilar

### Yangi ekranlar (22 ta)
- Login (yangi dizayn)
- Dashboard (darslar gorizontal scroll + telegram mini-karta)
- Guruhlar ro'yxati + Guruh detali
- Davomat olish + Davomat tarixi
- Baholar + Baho kiritish
- Vazifalar ro'yxati + Yaratish + Detali
- Xabarlar ro'yxati + Chat thread + Compose
- Bola profili (portfolio view)
- AI welcome + AI chat
- Telegram parents + Broadcast + Unlinked parents
- Haftalik jadval + Dars detali
- Profil + Profil tahrirlash + Parol o'zgartirish + Haqida
- Onboarding (intro + features + ready)
- Bildirishnomalar

### Design system
- Brand teal `#1F6F65` — barcha komponentlarda bir xil
- 5 ta theme fayl: colors, typography, spacing, radii, theme
- 17 ta shared widget: AlochiButton, AlochiCard, AlochiAvatar, AlochiSkeleton, va boshqalar
- Material 3 + AlochiTheme.light

### Texnik
- Flutter 3.41.4 (stable)
- flutter_riverpod 2.6.1 — state management
- go_router 14.8.1 — navigatsiya
- WebSocket (ws_client.dart) — real-time messaging
- Hive + flutter_secure_storage — offline cache + JWT
- Firebase Messaging — push notifications
- `flutter analyze`: 0 issues
- `dart format`: 100% formatted

### Bug fixlar
- temp fix fayl o'chirildi
- `dart format` barcha fayllar (39 fayl formatlandi)
- Trailing slash xatosi tuzatildi (`/auth/login`)

---

## v1.2.0 (rejalashtirilgan — V1.2 Sprint)

- Onboarding animatsiyalari (screen 2/3, 3/3)
- Guruh detali Tahlil tab
- Topic-based grading (Dars Step 3 to'liq)
- Dark mode
- Compose new message screen
- Tug'ilgan kun va mukofotlar

---

## v1.0.6 — 2026-03-20

- fix: iOS CocoaPods + Windows installer path detection

## v1.0.0 — 2026-03-20

- init: A'lochi cross-platform Flutter app (182 fayl)
