# A'lochi Teacher Mobile v1.1 — Design & Sprint Bundle

**Versiya:** 1.0 · 2026-05-04
**Loyiha:** rusthype/Alochi_app (Flutter mobile · O'qituvchi ilovasi)
**Brand:** A'lochi · Deep Teal `#1F6F65`

---

## Bundle ichidagi fayllar

```
alochi-teacher-v1.1/
├── README.md                          # Bu fayl
├── docs/
│   ├── teacher-tz.md                  # Texnik topshiriq (3524 qator) — har screen specifikatsiyasi
│   ├── sprint-plan.md                 # 7-kunlik sprint reja (Day 0 → Day 7)
│   ├── ux-kit.md                      # Cross-cutting pattern'lar (toast, modal, animatsiya, validation)
│   └── day-0-readiness.md             # Bugungi backend audit + Apple/Google account setup
├── mockup/
│   └── alochi-teacher-ui.html         # 27 ta ekran interaktiv mockup (210KB)
└── assets/
    ├── README.md                      # Brand asset setup yo'riqnomasi
    ├── branding/
    │   ├── logo-fullcolor.jpg         # A'lochi multi-color daraxt logo (640×640)
    │   ├── tree-silhouette.svg        # Single-color tree (16-1024px scalable)
    │   ├── app-icon-1024.svg          # iOS app icon master (teal bg + white tree)
    │   ├── app-icon-foreground.svg    # Android adaptive icon foreground
    │   └── splash.svg                 # Splash screen (multi-color leaves + wordmark)
    └── avatars/
        └── avatar-1.svg ... avatar-6.svg  # 6 ta default o'quvchi avatari
```

---

## Qaysi faylni qachon ishlatasiz

### Sprint boshlamasdan oldin (BUGUN)
1. **`docs/day-0-readiness.md`** → backend audit qilish, Apple Developer enrollment, Play Console
2. **`docs/teacher-tz.md` §5.3** → backend endpoint matrix bilan API javoblarini solishtirish

### Day 0 (sprint setup kuni)
1. **`docs/sprint-plan.md`** Day 0 bo'limi → branch yaratish, theme tokenlar yozish
2. **`docs/teacher-tz.md` §1-§3** → folder structure, color tokens, state management
3. **`assets/README.md`** → app icon va splash screen generation buyruqlari
4. **`assets/branding/`** → Flutter loyihaning `assets/branding/` papkasiga ko'chirish

### Day 1-7 (har kuni)
1. **`docs/sprint-plan.md`** kun bo'limini ochib vazifalar checklistini bajarish
2. Claude Code agentga shu kunning **agent prompt**'ini yuborish
3. **`docs/teacher-tz.md` §8**'dan tegishli screen spec'larini o'qish
4. **`docs/ux-kit.md`** dan toast/modal/animation pattern'lariga murojaat qilish
5. **`mockup/alochi-teacher-ui.html`** ni brauzerda ochib UI nuqtai nazaridan tasdiqlash

### Day 7 (release kuni)
1. **`docs/sprint-plan.md`** Day 7 bo'limi → patterns + QA + release
2. **`assets/README.md`** §8 → App Store/Play Console asset talablari

---

## Brand qoidalar (har kun amal qiling)

- ❌ Hech qanday emoji kodda — Lucide / Material Icons faqat
- ❌ Backend'ga yangi endpoint qo'shilmaydi — mavjudlaridan foydalaniladi (TZ §11.4)
- ❌ `Co-Authored-By` commit'larda yo'q
- ❌ Seed/fake data hech qaerda
- ❌ Mavjud screen kodi rivojsiz o'zgartirilmaydi (faqat refactor zaruriy bo'lsa)
- ✅ Har kun `flutter analyze` 0 errors
- ✅ Har screen bo'yicha alohida commit
- ✅ Real qurilmada test (iPhone 12 Mini + Samsung Galaxy A51)
- ✅ Brand teal `#1F6F65` qattiq — boshqa rang yo'q
- ✅ Coral accent `#E8954E` — faqat AI / Pride / achievements / milestones (4 ta o'rin)

---

## V1.1 yetkazib beriladigan 22 ekran

**Tab 0 — Bosh:** Dashboard (today's lessons horizontal scroll)
**Tab 1 — Guruhlar:** Guruhlar list, Guruh detail, Bola profili, Davomat belgilash, Davomat tarixi
**Tab 2 — Vazifalar:** Vazifalar list, Vazifa create, Vazifa detail
**Tab 3 — Xabarlar:** Xabarlar list, Chat thread
**Tab 4 — Profil:** Profil, Profil edit, Parol, Telegram (ota-onalarni taklif qilish)
**Markaziy workflow:** Dars boshqaruvi (#27 — unified 4-step lesson workflow)
**AI:** AI welcome, AI chat with lesson plan export
**Auth:** Login, Welcome onboarding
**Patterns:** Empty / Loading / Error

V1.2 ga qoldirilgan: Onboarding 2/3 + 3/3, Compose new message, Vazifa detail poll results, Guruh detail Tahlil tab.

---

## Texnologiya stack

- **Frontend:** Flutter 3.x · Riverpod 2.x · Hooks · freezed
- **State:** flutter_secure_storage · Hive · connectivity_plus
- **UI:** Material 3 · flutter_svg · qr_flutter · share_plus · lucide_icons
- **Network:** dio 5 + interceptors (auth refresh + offline queue)
- **Backend:** Django 5 (mavjud) · FastAPI Gemini AI service · PostgreSQL
- **WebSocket:** chat real-time
- **Push:** FCM (V1.1 setup, V1.2 advanced features)

---

## Hozirgi sprint blocker'lar (bugun hal qilish)

🔴 **Apple Developer enrollment** — bugun boshlasangiz 24-48 soat ($99/yil)
🔴 **Google Play Console** — bugun $25 to'lov, bir necha soat tasdiqlash
🔴 **Backend API audit** — `day-0-readiness.md` ichidagi curl buyruqlar bilan
🔴 **alochi.org/privacy va /terms** mavjudligini tekshirish

Bularsiz Day 7 release imkonsiz.

---

## Kontakt va resurslar

- **Repo:** https://github.com/rusthype/Alochi_app
- **API:** https://api.alochi.org
- **Web:** https://alochi.org
- **Bot:** @alochi_uz_bot

---

## Litsenziya

A'lochi internal — confidential. Tashqi tarqatishga ruxsat berilmagan.

---

**Ishlash uchun tayyor — sprint boshlash mumkin.**
