class Validators {
  /// Bo'sh emasligini tekshirish
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null 
        ? '$fieldName majburiy'
        : "Bu maydonni to'ldiring";
    }
    return null;
  }
  
  /// Foydalanuvchi nomi
  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Foydalanuvchi nomini kiriting";
    }
    if (value.length < 3) {
      return "Foydalanuvchi nomi kamida 3 belgi";
    }
    if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(value)) {
      return "Faqat lotin harflari, raqamlar, . va _ ishlatilsin";
    }
    return null;
  }
  
  /// Parol
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return "Parolni kiriting";
    }
    if (value.length < 8) {
      return "Parol kamida 8 belgi bo'lishi kerak";
    }
    return null;
  }
  
  /// Parol takrorlash
  static String? passwordMatch(String? value, String original) {
    if (value == null || value.isEmpty) {
      return "Parolni takrorlang";
    }
    if (value != original) {
      return "Parollar mos kelmaydi";
    }
    return null;
  }
  
  /// Telefon raqami (+998XXXXXXXXX)
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Telefon raqamini kiriting";
    }
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 9) return null;
    if (cleaned.length == 12 && cleaned.startsWith('998')) return null;
    return "Telefon +998XXXXXXXXX yoki 9 xonali bo'lishi kerak";
  }
  
  /// Email
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Email manzilini kiriting";
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return "Email manzil noto'g'ri";
    }
    return null;
  }
  
  /// Min length
  static String? Function(String?) minLength(int min, {String? fieldName}) {
    return (value) {
      if (value == null || value.trim().length < min) {
        return fieldName != null 
          ? "$fieldName kamida $min belgi"
          : "Kamida $min belgi kiriting";
      }
      return null;
    };
  }
  
  /// Max length
  static String? Function(String?) maxLength(int max, {String? fieldName}) {
    return (value) {
      if (value != null && value.length > max) {
        return fieldName != null
          ? "$fieldName ko'pi bilan $max belgi"
          : "Ko'pi bilan $max belgi kiriting";
      }
      return null;
    };
  }
  
  /// Compose multiple validators
  static String? Function(String?) compose(List<String? Function(String?)> validators) {
    return (value) {
      for (final v in validators) {
        final error = v(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
