class FormValidators {
  static String? validateComplaintType(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a complaint type.';
    }
    return null;
  }

  static String? validateMobileNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your mobile number';
    } else if (!RegExp(r'^(98|97)\d{8}$').hasMatch(value)) {
      return 'Please enter a valid Nepali mobile number';
    }
    return null;
  }

  static String? validateComplaintDetails(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field cannot be empty';
    }
    final wordCount = value.trim().split(RegExp(r'\s+')).length;
    if (wordCount < 5) {
      return 'Please enter at least 5 words';
    }
    return null;
  }
}