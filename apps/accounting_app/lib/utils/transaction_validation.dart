class TransactionValidation {
  static const int maxTitleLength = 150;
  static const int maxCategoryLength = 100;
  static const int maxPaymentMethodLength = 50;
  static const int maxDescriptionLength = 5000;
  static const double maxAmount = 9999999999.99;

  static String? validateTitle(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Title is required.';
    }
    if (text.length > maxTitleLength) {
      return 'Title must be $maxTitleLength characters or fewer.';
    }
    return null;
  }

  static String? validateCategory(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Category is required.';
    }
    if (text.length > maxCategoryLength) {
      return 'Category must be $maxCategoryLength characters or fewer.';
    }
    return null;
  }

  static String? validatePaymentMethod(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Payment method is required.';
    }
    if (text.length > maxPaymentMethodLength) {
      return 'Payment method must be $maxPaymentMethodLength characters or fewer.';
    }
    return null;
  }

  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required.';
    }

    final normalized = value.trim();
    if (!RegExp(r'^\d+(?:\.\d{1,2})?$').hasMatch(normalized)) {
      return 'Amount must be a positive number with at most two decimal places.';
    }

    final amount = double.tryParse(normalized);
    if (amount == null || amount <= 0 || amount > maxAmount) {
      return 'Amount must be greater than 0 and fit NUMERIC(12,2).';
    }

    return null;
  }

  static String? validateDescription(String? value) {
    final text = value ?? '';
    if (text.length > maxDescriptionLength) {
      return 'Description must be $maxDescriptionLength characters or fewer.';
    }
    return null;
  }

  static String? validateDateString(
    String? value, {
    String fieldName = 'Date',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }

    final normalized = value.trim();
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(normalized)) {
      return '$fieldName must be a valid date in YYYY-MM-DD format.';
    }

    final parts = normalized.split('-');
    final year = int.tryParse(parts[0]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 0;
    final day = int.tryParse(parts[2]) ?? 0;

    if (year < 1 || month < 1 || month > 12 || day < 1) {
      return '$fieldName must be a valid date in YYYY-MM-DD format.';
    }

    final daysInMonth = _daysInMonth(year, month);
    if (day > daysInMonth) {
      return '$fieldName must be a valid date in YYYY-MM-DD format.';
    }

    return null;
  }

  static String descriptionRemainingText(String value) {
    final remaining = maxDescriptionLength - value.length;
    return '$remaining characters left';
  }

  static int _daysInMonth(int year, int month) {
    switch (month) {
      case 1:
      case 3:
      case 5:
      case 7:
      case 8:
      case 10:
      case 12:
        return 31;
      case 4:
      case 6:
      case 9:
      case 11:
        return 30;
      case 2:
        final isLeapYear =
            (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
        return isLeapYear ? 29 : 28;
      default:
        return 0;
    }
  }
}
