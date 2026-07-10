// Client-side validation utilities used before calling repository/BLoC.
// Backend always re-validates; these are convenience checks for UX.
import '../constants/app_strings.dart';

abstract class Validators {
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.emailRequired;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return AppStrings.emailInvalid;
    }

    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.phoneRequired;
    }

    final phoneRegex = RegExp(r'^(0|\+84)[0-9]{9,10}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return AppStrings.phoneInvalid;
    }

    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.passwordRequired;
    }
    if (value.length < 8) {
      return AppStrings.passwordMin8;
    }

    return null;
  }

  static String? confirmPassword(String? value, String? original) {
    if (value == null || value.isEmpty) {
      return AppStrings.confirmPasswordRequired;
    }
    if (value != original) {
      return AppStrings.passwordMismatch;
    }

    return null;
  }

  static String? required(String? value, {String fieldName = 'Trường này'}) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.requiredField(fieldName);
    }

    return null;
  }

  static String? taxCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final taxRegex = RegExp(r'^\d{10}(-\d{3})?$');
    if (!taxRegex.hasMatch(value.trim())) {
      return AppStrings.taxCodeInvalid;
    }

    return null;
  }

  static String? quantity(String? value, {int minQuantity = 1}) {
    if (value == null || value.isEmpty) {
      return AppStrings.quantityRequired;
    }

    final qty = int.tryParse(value);
    if (qty == null) {
      return AppStrings.quantityInteger;
    }
    if (qty < minQuantity) {
      return AppStrings.minimumQuantity(minQuantity);
    }

    return null;
  }

  static String? address(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.addressRequired;
    }
    if (value.trim().length < 10) {
      return AppStrings.addressTooShort;
    }

    return null;
  }
}
