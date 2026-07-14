import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_response.dart';
import '../../cart/domain/cart.dart';

abstract class CartSyncRepository {
  Future<ApiResponse<void>> syncCart(Cart cart);
}

class CartSyncRemoteRepository implements CartSyncRepository {
  final ApiClient apiClient;

  const CartSyncRemoteRepository({required this.apiClient});

  @override
  Future<ApiResponse<void>> syncCart(Cart cart) {
    return apiClient.post<void>(
      ApiEndpoints.cartSync,
      data: {
        'items': cart.items
            .map(
              (item) => {
                'productId': item.productId,
                'quantity': item.quantity,
                'selected': item.selected,
              },
            )
            .toList(),
      },
      fromJson: (_) {},
    );
  }
}
