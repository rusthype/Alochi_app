# A'lochi Teacher Mobile — UX Kit

**Maqsad:** Ilovaning **cross-cutting pattern'lari** — har screen'da takrorlanadigan komponentlar va xulq-atvor. teacher-tz.md screen-specific, bu fayl pattern-specific.

**Auditoriya:** Frontend muhandislar (Day 1-7 implementatsiya), QA (Day 7 tekshiruv).
**Status:** V1.0 · 2026-05-04

---

## 1. Toast / Snackbar tizimi

### 1.1 4 ta turi

| Turi | Color | Lucide icon | Qachon |
|---|---|---|---|
| `success` | `#0F9A6E` | `check-circle` | Saqlandi, yuborildi, tugatildi |
| `error` | `#DC2626` | `alert-circle` | Xato, muvaffaqiyatsiz |
| `warning` | `#D97706` | `alert-triangle` | Diqqat talab |
| `info` | `#1F6F65` brand | `info` | Neutral xabar |

### 1.2 Pozitsiya va xulq-atvor

- **Pozitsiya:** Bottom (safe area + 16dp), full-width minus 16dp gutters
- **Duration:** 3.5s default, error 5s, action bilan 6s
- **Stack:** Yangisi keldi → eskini avto-dismiss qiladi (bir vaqtda 1 ta)
- **Dismiss:** swipe-down, tap, yoki avto
- **Animation:** Slide up 250ms easeOutCubic / down 200ms easeInCubic
- **Action button (optional):** "Bekor qilish", "Ko'rish", "Qayta urinish" — right side

### 1.3 API

```dart
// lib/shared/services/toast_service.dart
class ToastService {
  static void success(BuildContext ctx, String msg, {String? action, VoidCallback? onAction}) {
    _show(ctx, ToastType.success, msg, action: action, onAction: onAction);
  }
  static void error(BuildContext ctx, String msg, {String? action, VoidCallback? onAction}) {
    _show(ctx, ToastType.error, msg, duration: 5, action: action, onAction: onAction);
    HapticFeedback.heavyImpact();
  }
  // warning, info similar
}

// Usage
ToastService.success(context, 'Davomat saqlandi');
ToastService.error(context, 'Internet aloqasi yo\'q', action: 'Qaytadan', onAction: retry);
```

### 1.4 Acceptance

- [ ] Yangi toast eskini auto-dismiss (stack 1)
- [ ] Swipe-down → yopiladi
- [ ] Action button → callback + dismiss
- [ ] Bottom safe area hurmat (notch'li telefonlar)
- [ ] Keyboard ochilsa toast keyboard'dan yuqorida
- [ ] Screen reader: avto-o'qiladi (`semantics: liveRegion`)

---

## 2. Modal va Bottom sheet pattern'lari

### 2.1 3 ta turi

**A. Confirmation dialog** — destructive yoki muhim qaror
```dart
final confirmed = await ConfirmDialog.show(
  context,
  title: 'O\'quvchini guruhdan chiqarish?',
  message: 'Bu amalni qayta tiklab bo\'lmaydi',
  cancelLabel: 'Bekor',
  confirmLabel: 'Chiqarish',
  isDestructive: true,
);
```

**B. Bottom sheet picker** — tanlash (sana, guruh, fan)
```dart
final groupId = await GroupPickerSheet.show(context, currentGroupId: state.groupId);
```

**C. Bottom sheet action menu** — long-press, more menu
```dart
final action = await ActionSheet.show(context, actions: [
  SheetAction(icon: LucideIcons.edit, label: 'Tahrirlash'),
  SheetAction(icon: LucideIcons.share, label: 'Ulashish'),
  SheetAction(icon: LucideIcons.trash, label: 'O\'chirish', isDestructive: true),
]);
```

### 2.2 Visual spec

- **Border radius:** Top 24dp (sheet), all-corners 14dp (dialog)
- **Background:** White, no shadow (sheet sits on backdrop)
- **Drag handle:** 36×4dp pill, gray `#E5E7EB`, top 8dp
- **Padding:** 20dp horizontal, 16dp top, 24dp bottom (safe area)
- **Backdrop:** Black 50% opacity
- **Initial size:** 60% screen, max 90%

### 2.3 Animations

- **Open:** 300ms easeOutCubic, slide-up (sheet) yoki fade+scale (dialog)
- **Close:** 250ms easeInCubic
- **Backdrop fade:** 200ms

### 2.4 Acceptance

- [ ] Bottom sheet drag-to-dismiss
- [ ] Backdrop tap dismiss (faqat non-destructive)
- [ ] Keyboard ochilsa sheet auto-resize
- [ ] Long content scroll, footer sticky
- [ ] iOS Cupertino + Android Material — platform-aware

---

## 3. Animatsiya katalogi

### 3.1 Page transitions

| Tur | Trigger | Duration | Easing |
|---|---|---|---|
| Push (forward) | `context.push('/...')` | 300ms | `Cubic(0.2, 0, 0, 1)` |
| Pop (back) | back button | 250ms | `Cubic(0.4, 0, 0.2, 1)` |
| Tab switch | bottom nav | 200ms | linear cross-fade |
| Modal | sheet, dialog | 300ms | easeOutCubic |

iOS — `CupertinoPageRoute` (slide R→L). Android — `MaterialPageRoute`.

### 3.2 Micro-interactions

| Action | Animation |
|---|---|
| Tugma tap | Scale 0.96 (100ms in, 150ms out) + light haptic |
| Toggle switch | 200ms ease, color cross-fade |
| Card tap | Scale 0.98 (80ms in, 120ms out) |
| Pull-to-refresh | Spinner 80% pull threshold |
| Skeleton shimmer | 1.6s linear loop, opacity 0.4 ↔ 1.0 |
| Snackbar | Slide up 250ms easeOutCubic |
| Tab indicator | Spring (stiffness 400, damping 30) |
| Stepper progress | 400ms easeInOutCubic, fill animation |

### 3.3 Loading hierarchy

**Skeleton** (preferred for content):
- Pulsing rectangles in actual layout positions
- Same dimensions as final content
- 1.6s loop, opacity 0.4 ↔ 1.0
- Use for: lists, detail screens, dashboard

**Spinner** (for actions):
- 24px brand teal `#1F6F65` circular progress
- Used for: login submit, save buttons, brief actions
- **Min display 200ms** to avoid flash

**Progress bar** (for upload/sync):
- Linear, brand teal
- Determinate when % known, indeterminate ko'rinmaydi-default
- Used for: file upload, large list sync

### 3.4 Haptic feedback

| Action | Haptic |
|---|---|
| Button tap | `HapticFeedback.lightImpact()` |
| Toggle | `HapticFeedback.selectionClick()` |
| Tab switch | `HapticFeedback.selectionClick()` |
| Long press | `HapticFeedback.mediumImpact()` |
| Success (save, send) | `HapticFeedback.lightImpact()` |
| Error | `HapticFeedback.heavyImpact()` |
| Pull-to-refresh | `HapticFeedback.mediumImpact()` |

### 3.5 Acceptance

- [ ] Page transitions native to platform
- [ ] Tap haptic feedback ishlaydi (iOS + Android)
- [ ] Skeleton shimmer 60fps (no jank)
- [ ] Spinner min 200ms display (avoid flash)
- [ ] Pull-to-refresh: spinner faqat refreshing paytida

---

## 4. Form validation

### 4.1 Validation timing

- **On blur (default)** — user fokusdan chiqsa
- **On submit (sticky)** — submit'ga bosganda barcha xatolar formAtdan pastda
- **Real-time** — faqat password strength va email format
- **Never on type** — agressiv his qiladi

### 4.2 Visual states

| State | Border | Text | Right icon |
|---|---|---|---|
| Default | `#E5E7EB` 1dp | `#111827` | None |
| Focus | `#1F6F65` brand 2dp | `#111827` | None |
| Error | `#DC2626` 1.5dp | `#DC2626` | `alert-circle` |
| Success | `#0F9A6E` 1.5dp | `#111827` | `check` |
| Disabled | `#F4F5F7` bg | `#9CA3AF` | None |

### 4.3 Error messages

- Below input, 4dp top margin
- 12px font, danger `#DC2626`
- Max 2 lines
- O'zbek: aniq va amaliy
  - ❌ "Email noto'g'ri"
  - ✅ "Email formatda kiritmadingiz: example@gmail.com kabi"
  - ❌ "Parol kuchsiz"
  - ✅ "Parol kamida 8 ta harf bo'lishi kerak"

### 4.4 Common validators

```dart
// lib/shared/validators.dart

String? validateRequired(String? v, [String field = 'Maydon']) =>
  (v == null || v.trim().isEmpty) ? '$field kiritilishi shart' : null;

String? validateEmail(String? v) {
  if (v == null || v.isEmpty) return 'Email kiriting';
  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
    return 'Email formatda kiritmadingiz: example@gmail.com kabi';
  }
  return null;
}

String? validatePhoneUz(String? v) {
  if (v == null || v.isEmpty) return 'Telefon raqamini kiriting';
  final cleaned = v.replaceAll(RegExp(r'\D'), '');
  // 9 raqam (90 1234567) yoki 12 raqam (998 90 123 45 67)
  if (cleaned.length != 9 && cleaned.length != 12) {
    return 'Telefon raqami 9 ta raqamdan iborat: 90 123 45 67';
  }
  return null;
}

String? validatePassword(String? v) {
  if (v == null || v.isEmpty) return 'Parol kiriting';
  if (v.length < 8) return 'Parol kamida 8 ta harf';
  if (!RegExp(r'\d').hasMatch(v)) return 'Parol kamida 1 raqam bo\'lishi kerak';
  return null;
}
```

### 4.5 Submit behavior

```dart
void onSubmit() {
  if (!_formKey.currentState!.validate()) {
    // Birinchi xatoli inputga scroll
    _scrollToFirstError();
    HapticFeedback.heavyImpact();
    return;
  }
  // Proceed
}
```

### 4.6 Acceptance

- [ ] Submit'da barcha xatolar ko'rinadi, birinchi xatoga scroll
- [ ] Error matni kompakt va tushunarli (Uzbek conventions)
- [ ] Password strength meter real-time
- [ ] Email/phone format real-time
- [ ] Disabled save button — talablar to'liq bo'lguncha

---

## 5. Keyboard avoidance

### 5.1 Pattern

- Input fokus → keyboard ochiladi
- Sahifa avto-scroll qiladi: input keyboard ustida, 16dp gap
- Sticky CTA (masalan "Saqlash") keyboard'dan yuqoriga ko'tariladi
- `Scaffold(resizeToAvoidBottomInset: true)` Material default

### 5.2 Implementation

```dart
Scaffold(
  resizeToAvoidBottomInset: true,
  body: SingleChildScrollView(
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
    ),
    child: Column(...),
  ),
)
```

### 5.3 Sticky CTA pattern

```dart
Stack(
  children: [
    /* Form scrollable content */,
    Positioned(
      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      left: 16, right: 16,
      child: AlochiButton.primary(label: 'Saqlash', onPressed: submit),
    ),
  ],
)
```

### 5.4 Acceptance

- [ ] Input fokusda — keyboard ustida ko'rinadi (clipping yo'q)
- [ ] Sticky CTA keyboard ochilganda yuqoriga sliding (animatsiya bilan)
- [ ] Scroll-down → keyboard yopiladi (`onDrag`)
- [ ] iOS + Android'da bir xil ishlaydi

---

## 6. Permission request screens

### 6.1 Pattern — Native popup'dan oldin custom kontekst

iOS native permission popup ko'rinishi yomon (kontekstsiz). To'g'ri pattern:

1. **Custom kontekst ekran** — nima uchun ruxsat kerak ekanligini tushuntirish
2. **"Davom etish" tugmasi** → native popup chiqadi
3. Foydalanuvchi tasdiqlasa → davom etish
4. Rad etsa → "Sozlamalardan yoqing" CTA

### 6.2 3 ta permission

**A. Camera (QR skan uchun — Telegram parents screen)**

```
┌─ Empty space ─┐
│   📷 icon      │  (Lucide camera-icon, 64px brand teal)
│               │
│   Kamerani    │  (titleM)
│   yoqing      │
│               │
│   QR kodlarni │  (body, gray)
│   skanerlash  │
│   uchun kamera│
│   ruxsati     │
│   kerak.      │
│               │
│  [Davom ✦]    │  (primary CTA)
│  Hozircha emas │  (text button)
└───────────────┘
```

**B. Notifications (xabarlar uchun)**

Push notification ruxsati — Login'dan keyin, Dashboard'ga kirgandan 2-3s keyin (intrusive bo'lmasin).

**C. Photo gallery (Profil avatar)**

Faqat avatar upload tugmasi bosilganda.

### 6.3 Implementation

```dart
// permission_handler paket bilan
final status = await Permission.camera.status;
if (status.isDenied) {
  // Custom kontekst ekran
  final granted = await CameraPermissionScreen.show(context);
  if (!granted) return;
}
// QR skan davom etadi
```

### 6.4 Acceptance

- [ ] Native popup'dan oldin custom kontekst
- [ ] Rad etilsa "Sozlamalardan yoqing" link → app sozlamalari ochiladi
- [ ] Notification ruxsati intrusive emas (Dashboard'dan 2-3s keyin)
- [ ] Avatar upload faqat tugma bosilganda so'raydi

---

## 7. State pattern'lari (Loading / Empty / Error)

### 7.1 Loading skeleton

Har content screen'da 3 ta variant:

**List skeleton:**
```
[avatar circle] [text bar]   [chevron]
[avatar circle] [text bar]   [chevron]
[avatar circle] [text bar]   [chevron]
```

**Card skeleton:**
```
[wide card placeholder, height 168]
[wide card placeholder, height 168]
```

**Detail skeleton:**
```
[avatar 84]
[text bar 60%]
[text bar 40%]
─────
[wide card 1]
[wide card 2]
```

### 7.2 Empty state

6 ta variant:

| Screen | Title | Subtitle | CTA | Illustration |
|---|---|---|---|---|
| Bugungi darslar yo'q | "Bugun darsingiz yo'q" | "Eski guruhlarni ko'rish" | "Guruhlar" | Calendar leaf |
| Vazifalar yo'q | "Hali vazifa yaratmagansiz" | "Birinchi vazifani yarating" | "+ Vazifa berish" | Document leaf |
| Xabarlar yo'q | "Xabarlar yo'q" | "Yangi xabar kelganda bu yerda ko'rasiz" | None | Chat leaf |
| Davomat yo'q | "Davomat tarixi bo'sh" | "Birinchi darsdan keyin ko'rinadi" | None | Calendar empty |
| Qidiruv natija yo'q | "Hech narsa topilmadi" | "Boshqa so'z bilan urining" | "Tozalash" | Search leaf |
| Offline | "Internet yo'q" | "Aloqa tiklanganda ko'rinadi" | "Qaytadan" | Wi-fi leaf |

**Illustration style:** Tree/leaf metaphor — daraxt bargi bilan, brand teal palette. Hozircha [unDraw](https://undraw.co) brand-colorlangan SVG'lar OK (free, recolorable).

### 7.3 Error state

3 ta variant:

**A. Top banner (offline):**
- Amber bg `#FAEEDA`, 36dp height
- "Internet aloqasi yo'q · Yangilangan: 2 soat oldin"
- Aloqa tiklanganda — yashil 3s "Internet ulandi" → fade out

**B. Bottom toast (action error):**
- Red toast 5s
- "Saqlab bo'lmadi · Qaytadan" action

**C. Full-screen error (load failure):**
- Center
- Lucide `wifi-off` 64px gray
- "Yuklab bo'lmadi"
- "Qaytadan urinib ko'ring" body
- "Qaytadan" primary CTA

### 7.4 Acceptance

- [ ] Har list screen'da skeleton → content transition smooth
- [ ] Empty state CTA aniq, tegishli sahifaga olib boradi
- [ ] Offline banner ekran o'zgarganda saqlanadi (global)
- [ ] Error retry → loading state → success/retry

---

## 8. Accessibility

### 8.1 Color contrast

WCAG AA (4.5:1) mezoni:

| Combination | Ratio | Status |
|---|---|---|
| `#1F6F65` brand teal on white | 7.2:1 | ✓ |
| `#111827` ink on white | 16:1 | ✓ |
| `#6B7280` gray on white | 4.6:1 | ✓ |
| `#9CA3AF` gray2 on white | 3.0:1 | **AA Large only** |
| White on `#1F6F65` brand | 7.2:1 | ✓ |
| White on `#0F9A6E` success | 4.7:1 | ✓ |
| White on `#DC2626` danger | 5.1:1 | ✓ |
| White on `#D97706` warning | 3.6:1 | **18px+ only** |

**Qoida:** `#9CA3AF` faqat 14px+ secondary text uchun. `#D97706` warning fonida oq matn 18px+ bo'lishi kerak.

### 8.2 Tap target sizes

- **Minimum:** 44×44pt (iOS HIG) / 48×48dp (Android)
- **Comfortable:** 48×48
- Davomat 3-toggle button: 52×52 (frequent action)
- Bottom nav: 64dp height
- Primary CTA: 48dp height min

### 8.3 Screen reader (VoiceOver / TalkBack)

```dart
Semantics(
  label: 'Davomat saqlash, 28 ta o\'quvchi belgilangan',
  button: true,
  enabled: true,
  child: AlochiButton.primary(...),
)
```

Har ikon-only tugma `tooltip` yoki `Semantics(label:)` bilan.

### 8.4 Dynamic type (font scaling)

- iOS Dynamic Type qo'llanishi — `MediaQuery.textScaleFactor` 0.85 ↔ 1.5 oralig'ida UI buzilmaslik
- Test: Sozlamalar → Display → Text Size'ni eng kattaga qo'yib har screen tekshirish

### 8.5 Motion preferences

```dart
// Sozlamalardan "Reduce Motion" yoqilgan bo'lsa
final reducedMotion = MediaQuery.of(context).disableAnimations;
final duration = reducedMotion ? Duration.zero : Duration(milliseconds: 300);
```

### 8.6 Acceptance

- [ ] Color contrast WCAG AA — barcha matn ≥ 4.5:1
- [ ] Tap target ≥ 44×44pt
- [ ] Screen reader: har interactive element label
- [ ] Dynamic type 1.5x da scroll/clip yo'q
- [ ] Reduced motion — animatsiyalar minimal

---

## 9. Date / Time / Number formatting

### 9.1 Date formatlari

```dart
// lib/shared/formatters/date_format.dart
class DateFormatUz {
  // "Bugun 09:00", "Erta 09:00", "30-aprel 09:00"
  static String relative(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now).inDays;
    if (DateUtils.isSameDay(dt, now)) return 'Bugun ${_time(dt)}';
    if (diff == 1) return 'Erta ${_time(dt)}';
    if (diff == -1) return 'Kecha ${_time(dt)}';
    if (diff > 1 && diff < 7) return '${_weekday(dt)} ${_time(dt)}';
    return '${dt.day}-${_month(dt)} ${_time(dt)}';
  }
  
  static String _time(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  
  static const _months = ['yanvar','fevral','mart','aprel','may','iyun',
                          'iyul','avgust','sentabr','oktabr','noyabr','dekabr'];
  static String _month(DateTime dt) => _months[dt.month - 1];
  
  static const _weekdays = ['Du','Se','Cho','Pa','Ju','Sha','Ya'];
  static String _weekday(DateTime dt) => _weekdays[dt.weekday - 1];
}
```

### 9.2 Duration

```dart
// "2 soat oldin", "5 daqiqa oldin", "Hozir"
static String ago(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 30) return 'Hozir';
  if (diff.inMinutes < 1) return '${diff.inSeconds} soniya oldin';
  if (diff.inHours < 1) return '${diff.inMinutes} daqiqa oldin';
  if (diff.inDays < 1) return '${diff.inHours} soat oldin';
  if (diff.inDays < 7) return '${diff.inDays} kun oldin';
  return DateFormatUz.relative(dt);
}
```

### 9.3 Number formatting

```dart
// 1234 → "1 234", percent 0.93 → "93%"
String formatCount(int n) => NumberFormat('#,###', 'uz').format(n).replaceAll(',', ' ');
String formatPercent(double v) => '${(v * 100).round()}%';
```

### 9.4 Pluralization (O'zbek)

O'zbekchada plural form sodda — soni bir xil, raqam ko'rsatiladi:

```dart
// "1 o'quvchi", "5 o'quvchi", "32 o'quvchi" (hammasi bir xil)
String pluralStudent(int n) => '$n o\'quvchi';
String pluralLesson(int n) => '$n dars';
String pluralTask(int n) => '$n vazifa';
```

### 9.5 Acceptance

- [ ] Date helper barcha screen'da ishlatiladi (ad-hoc string yo'q)
- [ ] Vaqt zonasi: Asia/Tashkent (UTC+5)
- [ ] Sana formati native O'zbek

---

## 10. Implementation cheklist (Day 1-2)

Day 1 da qo'shiladigan:
- [ ] `lib/shared/services/toast_service.dart`
- [ ] `lib/shared/dialogs/confirm_dialog.dart`
- [ ] `lib/shared/sheets/action_sheet.dart`
- [ ] `lib/shared/validators.dart`
- [ ] `lib/shared/formatters/date_format.dart`

Day 2 da qo'shiladigan:
- [ ] `lib/shared/sheets/bottom_sheet_picker.dart`
- [ ] `lib/shared/widgets/permission_request_screen.dart`
- [ ] `lib/shared/widgets/keyboard_aware_form.dart`

Day 7 (Patterns) da yakunlanadigan:
- [ ] `lib/shared/widgets/alochi_skeleton.dart`
- [ ] `lib/shared/widgets/alochi_empty_state.dart` (6 variant)
- [ ] `lib/shared/widgets/alochi_error_view.dart`
- [ ] Accessibility audit — barcha screen'da

---

**Reference:** teacher-tz.md (screen specs), sprint-plan.md (kunlik vazifalar), assets/README.md (brand assetlar)
