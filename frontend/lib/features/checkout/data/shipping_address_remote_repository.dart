// ignore_for_file: prefer_initializing_formals

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_response.dart';
import '../domain/shipping_address.dart';
import '../domain/shipping_address_repository.dart';

class ShippingAddressRemoteRepository implements ShippingAddressRepository {
  final ApiClient _apiClient;

  const ShippingAddressRemoteRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  @override
  Future<ApiResponse<List<ShippingAddress>>> listAddresses() {
    return _apiClient.get<List<ShippingAddress>>(
      ApiEndpoints.shippingAddresses,
      fromJson: (json) => (json as List<dynamic>)
          .map((item) => ShippingAddress.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<ApiResponse<ShippingAddress>> createAddress(
    ShippingAddressInput input,
  ) {
    return _apiClient.post<ShippingAddress>(
      ApiEndpoints.shippingAddresses,
      data: input.toJson(),
      fromJson: (json) =>
          ShippingAddress.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<ShippingAddress>> updateAddress({
    required String id,
    required ShippingAddressInput input,
  }) {
    return _apiClient.put<ShippingAddress>(
      ApiEndpoints.shippingAddressDetail(id),
      data: input.toJson(),
      fromJson: (json) =>
          ShippingAddress.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<void>> deleteAddress(String id) async {
    await _apiClient.delete(ApiEndpoints.shippingAddressDetail(id));
    return const ApiResponse<void>(
      success: true,
      message: 'Shipping address deleted',
    );
  }
}
