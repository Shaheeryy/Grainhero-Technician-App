class Validators {
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    final phoneRegex = RegExp(r'^[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Enter a valid phone number (10-15 digits)';
    }

    return null;
  }

  static String? validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }

    if (value.length < 4 || value.length > 6) {
      return 'OTP must be 4-6 digits';
    }

    final otpRegex = RegExp(r'^[0-9]+$');
    if (!otpRegex.hasMatch(value)) {
      return 'OTP must contain only digits';
    }

    return null;
  }

  static bool isNumeric(String value) {
    return RegExp(r'^[0-9]+$').hasMatch(value);
  }
}
