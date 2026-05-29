/// Client-side validation utilities.
///
/// Used in form widgets before calling repository/BLoC.
/// Backend always re-validates; these are convenience checks for UX.
abstract class Validators {
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email không được để trống';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email không hợp lệ';
    }

    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Số điện thoại không được để trống';
    }

    final phoneRegex = RegExp(r'^(0|\+84)[0-9]{9,10}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Số điện thoại không hợp lệ';
    }

    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mật khẩu không được để trống';
    }
    if (value.length < 8) {
      return 'Mật khẩu phải có ít nhất 8 ký tự';
    }

    return null;
  }

  static String? confirmPassword(String? value, String? original) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập lại mật khẩu';
    }
    if (value != original) {
      return 'Mật khẩu không khớp';
    }

    return null;
  }

  static String? required(String? value, {String fieldName = 'Trường này'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName không được để trống';
    }

    return null;
  }

  static String? taxCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final taxRegex = RegExp(r'^\d{10}(-\d{3})?$');
    if (!taxRegex.hasMatch(value.trim())) {
      return 'Mã số thuế không hợp lệ';
    }

    return null;
  }

  static String? quantity(String? value, {int minQuantity = 1}) {
    if (value == null || value.isEmpty) {
      return 'Số lượng không được để trống';
    }

    final qty = int.tryParse(value);
    if (qty == null) {
      return 'Số lượng phải là số nguyên';
    }
    if (qty < minQuantity) {
      return 'Số lượng tối thiểu là $minQuantity';
    }

    return null;
  }

  static String? address(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Địa chỉ không được để trống';
    }
    if (value.trim().length < 10) {
      return 'Địa chỉ phải đủ chi tiết (tối thiểu 10 ký tự)';
    }

    return null;
  }
}
