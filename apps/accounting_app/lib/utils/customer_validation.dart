class CustomerValidation {
  static const int maxNameLength = 150;
  static const int maxPhoneLength = 30;
  static const int maxEmailLength = 150;
  static const int maxAddressLength = 500;
  static const int maxNotesLength = 5000;

  static String? validateName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Name is required.';
    }
    if (text.length > maxNameLength) {
      return 'Name must be $maxNameLength characters or fewer.';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    final text = value ?? '';
    if (text.trim().isEmpty) {
      return null;
    }
    if (text.trim().length > maxPhoneLength) {
      return 'Phone must be $maxPhoneLength characters or fewer.';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    final text = value ?? '';
    if (text.trim().isEmpty) {
      return null;
    }
    final trimmed = text.trim();
    if (trimmed.length > maxEmailLength) {
      return 'Email must be $maxEmailLength characters or fewer.';
    }
    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailPattern.hasMatch(trimmed)) {
      return 'Email must be a valid email address.';
    }
    return null;
  }

  static String? validateAddress(String? value) {
    final text = value ?? '';
    if (text.trim().isEmpty) {
      return null;
    }
    if (text.trim().length > maxAddressLength) {
      return 'Address must be $maxAddressLength characters or fewer.';
    }
    return null;
  }

  static String? validateNotes(String? value) {
    final text = value ?? '';
    if (text.trim().isEmpty) {
      return null;
    }
    if (text.length > maxNotesLength) {
      return 'Notes must be $maxNotesLength characters or fewer.';
    }
    return null;
  }

  static String notesRemainingText(String value) {
    final remaining = maxNotesLength - value.length;
    return '$remaining characters left';
  }
}
