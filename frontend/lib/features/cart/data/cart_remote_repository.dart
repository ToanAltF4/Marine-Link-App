import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../domain/cart.dart';
import '../domain/cart_repository.dart';
import 'cart_dto.dart';

class CartRemoteRepository implements CartRepository {
  final ApiClient apiClient;

  const CartRemoteRepository({required this.apiClient});

  @override
  Future<Cart> loadCart() async {
    final response = await apiClient.get<Cart>(
      ApiEndpoints.cart,
      fromJson: cartFromJson,
    );
    return response.data ?? const Cart();
  }

  @override
  Future<Cart> addItem({
    required String productId,
    required int quantity,
    bool selected = true,
  }) async {
    final response = await apiClient.post<Cart>(
      ApiEndpoints.cartItems,
      data: {
        'productId': productId,
        'quantity': quantity,
        'selected': selected,
      },
      fromJson: cartFromJson,
    );
    return response.data ?? const Cart();
  }

  @override
  Future<Cart> updateItem({
    required String productId,
    int? quantity,
    bool? selected,
  }) async {
    final data = <String, dynamic>{
      'quantity': ?quantity,
      'selected': ?selected,
    };
    final response = await apiClient.patch<Cart>(
      ApiEndpoints.cartItem(productId),
      data: data,
      fromJson: cartFromJson,
    );
    return response.data ?? const Cart();
  }

  @override
  Future<Cart> removeItem(String productId) async {
    final response = await apiClient.deleteFor<Cart>(
      ApiEndpoints.cartItem(productId),
      fromJson: cartFromJson,
    );
    return response.data ?? const Cart();
  }

  @override
  Future<Cart> clear() async {
    final response = await apiClient.deleteFor<Cart>(
      ApiEndpoints.cartItems,
      fromJson: cartFromJson,
    );
    return response.data ?? const Cart();
  }

  @override
  Future<Cart> syncCart(Cart cart) async {
    final response = await apiClient.post<Cart>(
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
      fromJson: cartFromJson,
    );
    return response.data ?? cart;
  }
}
