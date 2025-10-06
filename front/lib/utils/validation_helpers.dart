class ValidationHelpers {
  /// Validates phone number with the following rules:
  /// - Must contain only digits, spaces, hyphens, parentheses, and plus sign
  /// - Must be between 10-15 digits (excluding formatting characters)
  /// - Can start with country code (+ followed by 1-3 digits)
  /// - Common formats supported:
  ///   - +1234567890, +12 345 678 9012
  ///   - (123) 456-7890
  ///   - 123-456-7890
  ///   - 123 456 7890
  ///   - 1234567890
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }

    // Remove all non-digit characters except plus sign for counting
    String digitsOnly = value.replaceAll(RegExp(r'[^\d+]'), '');

    // Check if it contains invalid characters
    if (!RegExp(r'^[\d\s\-\(\)\+]+$').hasMatch(value)) {
      return 'Phone number can only contain digits, spaces, hyphens, parentheses, and plus sign';
    }

    // If starts with +, validate country code format
    if (digitsOnly.startsWith('+')) {
      // Remove the plus sign for digit counting
      String withoutPlus = digitsOnly.substring(1);

      // Country code should be 1-3 digits, followed by 7-12 more digits
      if (withoutPlus.length < 8 || withoutPlus.length > 15) {
        return 'Phone number with country code should be 8-15 digits long';
      }

      // Check if country code format is valid (1-3 digits followed by local number)
      if (!RegExp(r'^\d{1,3}\d{7,12}$').hasMatch(withoutPlus)) {
        return 'Invalid phone number format with country code';
      }
    } else {
      // Local number without country code
      if (digitsOnly.length < 10 || digitsOnly.length > 12) {
        return 'Phone number should be 10-12 digits long';
      }
    }

    return null; // Valid phone number
  }

  /// Validates email address format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }

    // Basic email regex pattern
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validates password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }

    // Check for at least one letter and one number
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain at least one letter and one number';
    }

    return null;
  }

  /// Validates name field
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }

    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }

    // Allow letters, spaces, hyphens, and apostrophes
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value.trim())) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  /// Validates city name
  static String? validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your city';
    }

    if (value.trim().length < 2) {
      return 'City name must be at least 2 characters long';
    }

    // Allow letters, spaces, hyphens, and apostrophes
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value.trim())) {
      return 'City name can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  /// Formats phone number for display (optional)
  static String formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters except plus
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleaned.startsWith('+')) {
      // International format
      return cleaned;
    } else if (cleaned.length == 10) {
      // US format: (123) 456-7890
      return '(${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    } else if (cleaned.length == 11 && cleaned.startsWith('1')) {
      // US format with country code: +1 (123) 456-7890
      return '+1 (${cleaned.substring(1, 4)}) ${cleaned.substring(4, 7)}-${cleaned.substring(7)}';
    }

    return phoneNumber; // Return original if no formatting rule matches
  }
}
