import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/core/api/api_client.dart';
import 'package:marinelink/core/api/api_endpoints.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/cart/data/cart_remote_repository.dart';
import 'package:marinelink/features/cart/domain/cart.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  const cart = Cart();

  test('addItem posts to cart items endpoint', () async {
    final apiClient = _MockApiClient();
    when(
      () => apiClient.post<Cart>(
        ApiEndpoints.cartItems,
        data: any(named: 'data'),
        fromJson: any(named: 'fromJson'),
      ),
    ).thenAnswer((_) async => const ApiResponse(success: true, data: cart));

    final repository = CartRemoteRepository(apiClient: apiClient);

    await repository.addItem(productId: 'prod-001', quantity: 2);

    final data =
        verify(
              () => apiClient.post<Cart>(
                ApiEndpoints.cartItems,
                data: captureAny(named: 'data'),
                fromJson: any(named: 'fromJson'),
              ),
            ).captured.single
            as Map<String, dynamic>;
    expect(data, {'productId': 'prod-001', 'quantity': 2, 'selected': true});
  });

  test('updateItem patches quantity and selected state', () async {
    final apiClient = _MockApiClient();
    when(
      () => apiClient.patch<Cart>(
        ApiEndpoints.cartItem('prod-001'),
        data: any(named: 'data'),
        fromJson: any(named: 'fromJson'),
      ),
    ).thenAnswer((_) async => const ApiResponse(success: true, data: cart));

    final repository = CartRemoteRepository(apiClient: apiClient);

    await repository.updateItem(
      productId: 'prod-001',
      quantity: 5,
      selected: false,
    );

    final data =
        verify(
              () => apiClient.patch<Cart>(
                ApiEndpoints.cartItem('prod-001'),
                data: captureAny(named: 'data'),
                fromJson: any(named: 'fromJson'),
              ),
            ).captured.single
            as Map<String, dynamic>;
    expect(data, {'quantity': 5, 'selected': false});
  });

  test('removeItem deletes one cart item and returns server cart', () async {
    final apiClient = _MockApiClient();
    when(
      () => apiClient.deleteFor<Cart>(
        ApiEndpoints.cartItem('prod-001'),
        fromJson: any(named: 'fromJson'),
      ),
    ).thenAnswer((_) async => const ApiResponse(success: true, data: cart));

    final repository = CartRemoteRepository(apiClient: apiClient);

    final result = await repository.removeItem('prod-001');

    expect(result, cart);
    verify(
      () => apiClient.deleteFor<Cart>(
        ApiEndpoints.cartItem('prod-001'),
        fromJson: any(named: 'fromJson'),
      ),
    ).called(1);
  });

  test('clear deletes all cart items and returns server cart', () async {
    final apiClient = _MockApiClient();
    when(
      () => apiClient.deleteFor<Cart>(
        ApiEndpoints.cartItems,
        fromJson: any(named: 'fromJson'),
      ),
    ).thenAnswer((_) async => const ApiResponse(success: true, data: cart));

    final repository = CartRemoteRepository(apiClient: apiClient);

    final result = await repository.clear();

    expect(result, cart);
    verify(
      () => apiClient.deleteFor<Cart>(
        ApiEndpoints.cartItems,
        fromJson: any(named: 'fromJson'),
      ),
    ).called(1);
  });
}
