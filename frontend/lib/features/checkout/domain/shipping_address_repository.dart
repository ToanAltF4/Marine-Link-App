import '../../../core/api/api_response.dart';
import 'shipping_address.dart';

abstract class ShippingAddressRepository {
  Future<ApiResponse<List<ShippingAddress>>> listAddresses();

  Future<ApiResponse<ShippingAddress>> createAddress(
    ShippingAddressInput input,
  );

  Future<ApiResponse<ShippingAddress>> updateAddress({
    required String id,
    required ShippingAddressInput input,
  });

  Future<ApiResponse<void>> deleteAddress(String id);
}
