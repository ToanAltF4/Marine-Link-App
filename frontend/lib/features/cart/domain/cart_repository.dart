import 'cart.dart';

abstract class CartRepository {
  Future<Cart> loadCart();

  Future<Cart> syncCart(Cart cart);
}
