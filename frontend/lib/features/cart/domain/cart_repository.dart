import 'cart.dart';

abstract class CartRepository {
  Future<Cart> loadCart();

  Future<Cart> addItem({
    required String productId,
    required int quantity,
    bool selected = true,
  });

  Future<Cart> updateItem({
    required String productId,
    int? quantity,
    bool? selected,
  });

  Future<Cart> removeItem(String productId);

  Future<Cart> clear();

  Future<Cart> syncCart(Cart cart);
}
