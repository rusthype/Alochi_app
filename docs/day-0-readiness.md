# Day 0 Readiness Checklist — A'lochi Teacher Mobile

**Vaqt:** 2026-05-04 (bugun) → Day 0 boshlash imkoniyati
**Maqsad:** Sprint blocker'larni hal qilish

---

## 1. Apple Developer enrollment ⚠️ ENG MUHIM

**Hozir boshlang** — tasdiqlash 24-48 soat (individual). Day 7 iOS release uchun kerak.

**URL:** https://developer.apple.com/programs/enroll/
**Cost:** $99/yil
**Type:** Individual (avval), keyin Organization'ga migrate (kerak bo'lsa)

**Qadamlar:**
- [ ] Apple ID yarating yoki mavjudni ishlating
- [ ] 2-Factor Authentication yoqing (talab)
- [ ] D-U-N-S kerak emas Individual uchun
- [ ] Visa/Mastercard bilan to'lov (O'zbekiston'dan ishlaydi)
- [ ] Tasdiqlovchi email kuting (24-48 soat)

**Bundle ID rezervatsiya** (tasdiqlanganidan keyin):
- `org.alochi.teacher` — App Store identifier

---

## 2. Google Play Console enrollment

**URL:** https://play.google.com/console/signup
**Cost:** $25 one-time
**Tasdiqlash:** Bir necha soat

**Qadamlar:**
- [ ] Google account bilan kirish
- [ ] $25 to'lov
- [ ] Developer profile to'ldirish
- [ ] Internal testing track yaratish
- [ ] Package name: `org.alochi.teacher`

**Yangi qoida (2024-dan beri):**
14 kun ichida real qurilmada test qilingan ekanligini ko'rsatish kerak. Bu cheklov internal testing track uchun ham. Day 7'da TestFlight + Play Internal upload qilamiz.

---

## 3. Backend API audit (bugun tekshirish)

Quyidagi `curl` buyruqlarni Max'ning login token'i bilan ishga tushiring:

### 3.1 Login va token olish

```bash
# .env yoki shell variable
ALOCHI_API="https://api.alochi.org"   # yoki staging URL
EMAIL="max@alochi.org"
PASS="<sizning parolingiz>"

# Login va token saqlash
TOKEN=$(curl -s -X POST $ALOCHI_API/auth/login/ \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASS\"}" \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['access'])")

echo "Token: ${TOKEN:0:20}..."
```

### 3.2 Asosiy endpoint'larni tekshirish

```bash
# Dashboard summary — TZ today_lessons[] qaytarishi kerak
echo "=== Dashboard summary ==="
curl -s -H "Authorization: Bearer $TOKEN" \
  $ALOCHI_API/teacher/dashboard/summary/ | python3 -m json.tool

# Guruhlar (Sinflar) ro'yxati
echo "=== Groups list ==="
curl -s -H "Authorization: Bearer $TOKEN" \
  $ALOCHI_API/teacher/classes/ | python3 -m json.tool

# Lesson detail (Dars boshqaruvi uchun)
echo "=== Lesson detail ==="
LESSON_ID=1   # birinchi mavjud lesson ID
curl -s -H "Authorization: Bearer $TOKEN" \
  $ALOCHI_API/teacher/lessons/$LESSON_ID/ | python3 -m json.tool

# Vazifalar ro'yxati
echo "=== Homework list ==="
curl -s -H "Authorization: Bearer $TOKEN" \
  $ALOCHI_API/teacher/homework/ | python3 -m json.tool

# Telegram groups status (yangi endpoint — mavjudmi?)
echo "=== Telegram groups status ==="
curl -s -H "Authorization: Bearer $TOKEN" \
  $ALOCHI_API/teacher/telegram/groups-status/ | python3 -m json.tool
```

### 3.3 Tekshirish jadvali

| Endpoint | Status code | Response shape | TZ §5.3 mos? |
|---|---|---|---|
| `/auth/login/` | 200/401 | `{access, refresh, user}` | |
| `/teacher/dashboard/summary/` | 200 | `{today_lessons[], pending_todos[], unread_notifications}` | |
| `/teacher/classes/` | 200 | `[{id, code, subject, ...}]` | |
| `/teacher/lessons/{id}/` | 200/404 | `{lesson, class, today_attendance_status, yesterday_homework}` | |
| `/teacher/homework/` | 200 | `[{id, title, due_date, status, ...}]` | |
| `/teacher/telegram/groups-status/` | 200/404 | `[{group_id, total_parents, linked_parents, invite_url}]` | |

**Agar 404 yoki shape noto'g'ri:**
- Backend team'ga gap ro'yxati yuboring
- Yoki TZ'ni mavjud shape'ga moslashtiring

### 3.4 Staging environment topish

```bash
# DNS tekshiruv
nslookup api-staging.alochi.org
nslookup api-dev.alochi.org

# Yoki backend repo'da .env yoki settings/production.py qarang
# rusthype/alochi yoki rusthype/Alochi_school
```

**Agar staging YO'Q:**
- Production'ga test data injection qilish — XATOLI
- Local backend'ni ko'taring: `docker-compose up` (alochi repo ichida)
- Sprint paytida lokal API ishlatamiz, Day 7'da production'ga ulanish

---

## 4. Privacy Policy va Terms — alochi.org tekshiruv

```bash
# Mavjudligini tekshirish
curl -I https://alochi.org/privacy
curl -I https://alochi.org/terms
curl -I https://alochi.org/privacy-policy
curl -I https://alochi.org/terms-of-service
```

**Agar 404:**
- Day 7'gacha alochi.org'ga qo'shilishi kerak
- Next.js loyihasida `app/privacy/page.tsx` va `app/terms/page.tsx` yaratish
- Standard template'lar (GDPR + COPPA — bola ma'lumotlari uchun):
  - https://www.termsfeed.com (free generator)
  - https://www.iubenda.com (paid, mukammalroq)
- O'zbek + ingliz tarjimasi
- Mobile app talablari:
  - Camera access reasoning
  - Notification permission reasoning
  - Storage access reasoning
  - User data deletion request flow

**Tezkor template (Privacy Policy):**

Sizga kerak:
1. Maktab ma'lumotlari (sinflar, davomat, baholar) qanday saqlanadi
2. Telegram bot orqali ota-onaga yuborilgan ma'lumotlar
3. AI yordamchi orqali Gemini'ga yuborilgan kontekst
4. User'ning ma'lumotlarini o'chirish huquqi (delete account)
5. Cookie/analytics policy
6. Children's privacy (COPPA — 13 yoshdan kichik foydalanuvchilar yo'q)

---

## 5. Bugungi reja (eng samarali tartib)

**Ertalab (1-2 soat):**
- [ ] Apple Developer enrollment boshlash (5 daq) → 24-48s kutish
- [ ] Google Play Console enrollment ($25) → bir necha soat → tayyor
- [ ] alochi.org privacy/terms tekshiruv

**Tushdan keyin (2-3 soat):**
- [ ] Backend API audit — yuqoridagi `curl` buyruqlar
- [ ] Natijani jadvalga to'ldirish
- [ ] TZ §5.3 bilan solishtirish
- [ ] Gap'lar list qilish (agar bor)

**Kechki (1 soat):**
- [ ] Apple Developer email tasdiqlash kelganmi tekshirish
- [ ] Play Console internal track sozlash
- [ ] Privacy policy draft tayyorlash (agar yo'q bo'lsa)

---

## 6. Block status

Bugungi resolutsiyalardan keyin Day 0 imkoniyati:

| Block | Status | Day 0 ga ta'siri |
|---|---|---|
| Apple Developer | 24-48s (Individual) | Day 7 iOS release uchun kritik |
| Play Console | bir necha soat | Day 7 Android release uchun kritik |
| Backend API audit | bugun | TZ moslashtirish kerak bo'lishi mumkin |
| Staging env | bugun aniqlanadi | Local backend bilan davom etish OK |
| Privacy/Terms URLs | Day 6'gacha | Day 7 App Store submission uchun kritik |

**Day 0 boshlash imkoniyati:** Backend audit tugaganidan keyin — ehtimol bugun kechqurun yoki ertaga ertalab.

---

## 7. Agar muammo bo'lsa

**Apple Developer rad etilsa:**
- Sabab odatda payment method (Humo karta ishlamaydi)
- Wise account orqali AQSh kartasi
- Yoki international partner orqali (Russia, Turkey, UAE LLC)

**Backend gap topilsa:**
- TZ'da yangi endpoint qo'shish o'rniga — mavjud endpoint shape'ini moslashtirish
- Frontend client agar `today_lessons` qaytmasa — `classes/` + `lessons/today/` ikki API call bilan compose qiladi

**Staging yo'q bo'lsa:**
- Local backend Docker bilan ko'tarish
- Test data factory script yozish (Django management command)
- Production'ga harakat qilmaslik V1.1 paytida

---

**Reference:** `teacher-tz.md` (§5.3 endpoint matrix), `sprint-plan.md` (Day 7 release), `ux-kit.md` (state patterns)
