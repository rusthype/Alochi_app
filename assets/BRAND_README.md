# A'lochi Brand Assets — Teacher App

Bu papka A'lochi mobile teacher app'i uchun barcha brand asset'larni o'z ichiga oladi.

---

## 1. Brand identity

**Iconmark:** Daraxt (ildiz + tana + barglar) — bilim, o'sish, mustahkam poydevor metaforasi
**Wordmark:** "A'lochi" (serif) + "TA'LIM LOYIHA" (tagline, muted teal)
**Primary brand color:** Deep Teal `#1F6F65`
**Accent color:** Warm Coral `#E8954E` (faqat AI, Pride, achievements)

**Brand palette (logodan extracted):**

| Token | Hex | Qachon ishlatiladi |
|---|---|---|
| `brand` | `#1F6F65` | Primary CTA, aktiv darslar, badge'lar |
| `brand-500` | `#2D8A7E` | Hover, lighter accents |
| `brand-700` | `#155E59` | Pressed state |
| `brand-soft` | `#E8F2EF` | Pill backgrounds, soft tints |
| `brand-tint` | `#BCD9D1` | Disabled CTA, borders |
| `brand-on-dark` | `#A8D5CD` | Dark bg ustidagi text |
| `brand-muted` | `#5A8B87` | Tagline color, secondary |
| `hero-dark` | `#0E2E2A` | Aktiv lesson card, hero |
| **`accent`** | **`#E8954E`** | **Faqat: AI, Pride, milestones** |
| `accent-soft` | `#FCEFE3` | AI bg, Pride bg |

---

## 2. Files

```
assets/
├── branding/
│   ├── tree-silhouette.svg         # Single-color, scalable (16px → 1024px)
│   ├── app-icon-1024.svg           # iOS app icon master (1024×1024, teal bg + white tree)
│   ├── app-icon-foreground.svg     # Android adaptive icon foreground (432×432)
│   └── splash.svg                  # Splash screen (1080×1920) with multi-color leaves
└── avatars/
    ├── avatar-1.svg ... avatar-6.svg   # 6 default student avatars (geometric, teal palette)
```

---

## 3. ⚠️ MUHIM — Asl logo SVG kerak

Hozirgi tree silhouette **prototip** — alochi.org dagi haqiqiy multi-color daraxt logosi'ning soddalashtirilgan versiyasi.

**Sizdan kerak:** alochi.org dagi original SVG faylni quyidagi joylarga drop qiling:

- `branding/logo-fullcolor.svg` (login, profile, AI welcome — multi-color tree)
- `branding/logo-wordmark.svg` (horizontal layout: tree + "A'lochi" text)

Mavjud `tree-silhouette.svg` shu paytgacha placeholder bo'ladi.

---

## 4. Flutter integration

### 4.1 App icon generation

`flutter_launcher_icons` paketini ishlatamiz:

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: "ic_launcher"
  ios: true
  image_path: "assets/branding/app-icon-1024.png"   # SVG'dan PNG ga konversiya qilish kerak
  adaptive_icon_background: "#1F6F65"
  adaptive_icon_foreground: "assets/branding/app-icon-foreground.png"
  remove_alpha_ios: true  # iOS bg uchun shart
```

Generation:
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

### 4.2 SVG → PNG konversiya

`flutter_launcher_icons` PNG kutadi. Konversiya yo'llari:

**Variant A — Online (eng oddiy):**
- https://cloudconvert.com/svg-to-png — 1024×1024 retain qiling

**Variant B — macOS Inkscape:**
```bash
brew install --cask inkscape
inkscape app-icon-1024.svg --export-type=png --export-width=1024 --export-filename=app-icon-1024.png
inkscape app-icon-foreground.svg --export-type=png --export-width=432 --export-filename=app-icon-foreground.png
```

**Variant C — npm tool:**
```bash
npm install -g svg2png-cli
svg2png app-icon-1024.svg -w 1024 -h 1024
svg2png app-icon-foreground.svg -w 432 -h 432
```

### 4.3 Splash screen generation

`flutter_native_splash` paketini ishlatamiz:

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_native_splash: ^2.3.10

flutter_native_splash:
  color: "#FAFAFA"                               # Light background
  image: assets/branding/splash-logo.png          # Tree + wordmark (centered)
  branding: assets/branding/splash-tagline.png    # Optional tagline below
  
  android_12:
    color: "#FAFAFA"
    image: assets/branding/splash-android12.png   # 1152×1152, centered
  
  ios_content_mode: center
```

Generation:
```bash
flutter pub run flutter_native_splash:create
```

### 4.4 In-app logo usage

App ichida logo'ni ko'rsatish (login, profile, AI):

```dart
// pubspec.yaml ga qo'shish:
flutter:
  assets:
    - assets/branding/
    - assets/avatars/

// Ishlatish (flutter_svg paketi orqali):
import 'package:flutter_svg/flutter_svg.dart';

SvgPicture.asset(
  'assets/branding/logo-fullcolor.svg',  // asl multi-color logo
  width: 64,
  height: 64,
)
```

---

## 5. Default avatar usage

Foydalanuvchi rasm yuklamasa, default avatar'lardan tasodifiy birini tanlash:

```dart
// lib/shared/widgets/alochi_avatar.dart
class AlochiAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;       // For initials fallback
  final int? userId;        // For deterministic default avatar selection
  final double size;
  
  const AlochiAvatar({
    this.imageUrl,
    this.name,
    this.userId,
    this.size = 40,
  });
  
  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(imageUrl!),
      );
    }
    
    // Deterministic default: userId % 6 + 1 → avatar-1 to avatar-6
    final avatarIndex = ((userId ?? name?.hashCode ?? 0).abs() % 6) + 1;
    return SvgPicture.asset(
      'assets/avatars/avatar-$avatarIndex.svg',
      width: size,
      height: size,
    );
  }
}
```

---

## 6. Inter font setup

TZ §2.2 bo'yicha SF Pro (iOS native) + Inter (Android) kerak.

**Variant A — `google_fonts` package (recommended):**
```yaml
dependencies:
  google_fonts: ^6.1.0
```

```dart
// lib/theme/typography.dart
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static TextStyle displayL = GoogleFonts.inter(
    fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: -0.5,
  );
  // ... boshqa style'lar
}
```

**O'zbek Cyrillic+Latin coverage:** Inter to'liq qo'llaydi (`uz-Latn`, `uz-Cyrl` glyph'lar bor).

**Variant B — Bundled `.ttf` (offline-first):**
1. https://fonts.google.com/specimen/Inter dan ZIP yuklab oling
2. `fonts/Inter-Regular.ttf`, `Inter-Medium.ttf`, `Inter-SemiBold.ttf`, `Inter-Bold.ttf` ni `assets/fonts/` ga ko'chiring
3. `pubspec.yaml`:
```yaml
flutter:
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
          weight: 400
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
```

---

## 7. Iconography decision — Lucide ✓

TZ qoidasi: emoji yo'q. Lucide tanlandi (1400+ outline icon, brand'ga mos):

```yaml
dependencies:
  lucide_icons: ^0.257.0   # Latest Lucide for Flutter
```

Yoki Material Symbols (Google standard):
```dart
import 'package:flutter/material.dart';
Icon(Icons.home_outlined)  // Material Symbols outlined
```

**Tavsiyam:** Lucide — brand bilan vizual mos, outline style serif wordmark bilan harmonik.

---

## 8. App Store assets (Day 7'da kerak bo'ladi)

**iOS App Store Connect:**
- App icon 1024×1024 (no transparency, no rounded corners — Apple auto-rounds)
- Screenshots: iPhone 6.7" (1290×2796), 6.5" (1242×2688), 5.5" (1242×2208)
- iPad Pro 12.9" (2048×2732) optional

**Google Play Console:**
- Hi-res icon 512×512 PNG (32-bit)
- Feature graphic 1024×500 PNG/JPG
- Phone screenshots 16:9 minimum 320px
- 7-inch tablet screenshots optional

**Pre-launch ish:**
- App description Uzbek
- Short description (80 chars)
- Privacy policy URL — `https://alochi.org/privacy` (mavjudligini tekshiring)
- Support email — `support@alochi.uz`

---

## 9. Setup checklist (Day 0)

Day 0'da Claude Code agent shularni bajaradi:

- [ ] `flutter pub add flutter_svg google_fonts lucide_icons`
- [ ] `flutter pub add --dev flutter_launcher_icons flutter_native_splash`
- [ ] `assets/branding/`, `assets/avatars/`, `assets/fonts/` ga ko'chirish
- [ ] `pubspec.yaml` ga `assets:` va `fonts:` qo'shish
- [ ] SVG → PNG konversiya (app icon master + foreground)
- [ ] `flutter pub run flutter_launcher_icons`
- [ ] `flutter pub run flutter_native_splash:create`
- [ ] Test: app launch'da splash chiqishini, app icon to'g'ri ko'rinishini
- [ ] Test: `Theme.of(context).colorScheme.primary` = `#1F6F65`

---

## 10. Brand compliance rules (har kun amal qilish)

- ❌ Tree silhouette **rangini ad-hoc o'zgartirmang** — faqat `AppColors.brand` yoki `AppColors.white`
- ❌ Wordmark "A'lochi" ni **horiziontal stretch qilmang** yoki **bold qilmang** — original serif holicha
- ❌ Tagline "TA'LIM LOYIHA" ni **letter-spacing**siz yozmang
- ❌ Coral accent **navigation, CTAs, kunlik UI'da ishlatmang** — faqat 4 ta o'rinda (AI, Pride, achievements, milestones)
- ✅ Logo har doim **24px ≤ size ≤ 240px** oralig'ida, 24px dan kichik bo'lsa silhouette ishlating
- ✅ Brand color contrast WCAG AA (4.5:1) ni ta'minlasin — `brand` (`#1F6F65`) oq matn ustida 7.2:1 ✓

---

Asl alochi.org SVG faylini olganingizda — `tree-silhouette.svg`, `app-icon-1024.svg`, `app-icon-foreground.svg`, `splash.svg` larni shu faylga moslab almashtiring (yoki menga yuklang, men qayta ishlayman).
