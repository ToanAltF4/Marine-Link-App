import '../../../core/api/api_response.dart';
import '../domain/shipping_address.dart';
import '../domain/shipping_address_repository.dart';

class ShippingAddressMockRepository implements ShippingAddressRepository {
  final List<ShippingAddress> _addresses = [];
  int _nextId = 1;

  @override
  Future<ApiResponse<List<ShippingAddress>>> listAddresses() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return ApiResponse<List<ShippingAddress>>(
      success: true,
      message: 'OK',
      data: List<ShippingAddress>.unmodifiable(_addresses),
    );
  }

  @override
  Future<ApiResponse<ShippingAddress>> createAddress(
    ShippingAddressInput input,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final shouldBeDefault = _addresses.isEmpty || input.isDefault;
    if (shouldBeDefault) {
      _clearDefault();
    }
    final address = ShippingAddress(
      id: 'address-${_nextId.toString().padLeft(3, '0')}',
      label: _trimToNull(input.label),
      receiverName: input.receiverName,
      receiverPhone: input.receiverPhone,
      addressLine: input.addressLine,
      isDefault: shouldBeDefault,
    );
    _nextId += 1;
    _addresses.add(address);
    return ApiResponse<ShippingAddress>(
      success: true,
      message: 'Shipping address created',
      data: address,
    );
  }

  @override
  Future<ApiResponse<ShippingAddress>> updateAddress({
    required String id,
    required ShippingAddressInput input,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final index = _addresses.indexWhere((address) => address.id == id);
    if (index < 0) {
      return const ApiResponse<ShippingAddress>(
        success: false,
        message: 'Khong tim thay dia chi giao hang',
      );
    }
    if (input.isDefault) {
      _clearDefault();
    }
    final current = _addresses[index];
    final address = ShippingAddress(
      id: current.id,
      label: _trimToNull(input.label),
      receiverName: input.receiverName,
      receiverPhone: input.receiverPhone,
      addressLine: input.addressLine,
      isDefault: input.isDefault || _addresses.length == 1,
    );
    _addresses[index] = address;
    return ApiResponse<ShippingAddress>(
      success: true,
      message: 'Shipping address updated',
      data: address,
    );
  }

  @override
  Future<ApiResponse<void>> deleteAddress(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final index = _addresses.indexWhere((address) => address.id == id);
    if (index < 0) {
      return const ApiResponse<void>(
        success: false,
        message: 'Khong tim thay dia chi giao hang',
      );
    }
    final wasDefault = _addresses[index].isDefault;
    _addresses.removeAt(index);
    if (wasDefault && _addresses.isNotEmpty) {
      final first = _addresses.first;
      _addresses[0] = ShippingAddress(
        id: first.id,
        label: first.label,
        receiverName: first.receiverName,
        receiverPhone: first.receiverPhone,
        addressLine: first.addressLine,
        isDefault: true,
      );
    }
    return const ApiResponse<void>(
      success: true,
      message: 'Shipping address deleted',
    );
  }

  void _clearDefault() {
    for (var index = 0; index < _addresses.length; index++) {
      final address = _addresses[index];
      _addresses[index] = ShippingAddress(
        id: address.id,
        label: address.label,
        receiverName: address.receiverName,
        receiverPhone: address.receiverPhone,
        addressLine: address.addressLine,
        isDefault: false,
      );
    }
  }

  String? _trimToNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
