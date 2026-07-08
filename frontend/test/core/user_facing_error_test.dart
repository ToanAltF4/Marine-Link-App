import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/core/api/api_client.dart';
import 'package:marinelink/core/errors/user_facing_error.dart';

void main() {
  group('userFacingErrorMessage', () {
    test('hides ApiException metadata from UI text', () {
      const error = ApiException(
        message: 'Email/số điện thoại hoặc mật khẩu không đúng',
        type: ApiExceptionType.unauthorized,
        statusCode: 401,
      );

      expect(error.toString(), 'Email/số điện thoại hoặc mật khẩu không đúng');
      expect(
        userFacingErrorMessage(error, fallback: 'Đăng nhập thất bại.'),
        'Email/số điện thoại hoặc mật khẩu không đúng',
      );
    });

    test(
      'maps backend codes and generic backend text to friendly Vietnamese',
      () {
        expect(
          userFacingResponseMessage(
            'ApiException(ApiExceptionType.unauthorized, 401): INVALID_CREDENTIALS',
            fallback: 'Đăng nhập thất bại.',
          ),
          'Email/số điện thoại hoặc mật khẩu không đúng.',
        );
        expect(
          userFacingResponseMessage(
            'Validation failed',
            fallback: 'Thông tin chưa hợp lệ.',
          ),
          'Thông tin chưa hợp lệ. Vui lòng kiểm tra lại.',
        );
        expect(
          userFacingResponseMessage(
            'Internal server error',
            fallback: 'Không thể tải dữ liệu.',
          ),
          'Hệ thống đang gặp lỗi. Vui lòng thử lại sau.',
        );
      },
    );
  });
}
