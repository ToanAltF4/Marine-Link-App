import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marinelink/features/cart/domain/cart.dart';
import 'package:marinelink/features/products/domain/product.dart';

/// CartCubit manages the local cart state (add/update/remove/clear).
/// Cart is kept in memory; synced to server before checkout via CartSyncCubit.
///
/// Uses Cubit (simpler than BLoC) since the logic is purely local state mutation.
class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState(cart: Cart()));

  // ── Add or increment an item ─────────────────────────────────────────────────

  void addItem({
    required ProductDetail product,
    int quantity = 1,
  }) {
    final existingIndex =
        state.cart.items.indexWhere((i) => i.productId == product.id);

    final int newQuantity = existingIndex >= 0
        ? state.cart.items[existingIndex].quantity + quantity
        : quantity;

    final clamped =
        newQuantity.clamp(product.minOrderQuantity, product.stockQuantity);

    final tier = product.tierFor(clamped);
    final unitPrice = tier?.unitPrice ?? product.basePrice;

    final item = CartItem(
      productId: product.id,
      productName: product.name,
      productImageUrl: product.imageUrl ?? '',
      unit: product.unit,
      quantity: clamped,
      unitPrice: unitPrice,
      selectedPriceTierId: tier?.id,
      minOrderQuantity: product.minOrderQuantity,
      stockQuantity: product.stockQuantity,
    );

    emit(CartState(cart: state.cart.upsertItem(item)));
  }

  // ── Update quantity of an existing item ─────────────────────────────────────

  void updateQuantity(String productId, int quantity) {
    final index =
        state.cart.items.indexWhere((i) => i.productId == productId);
    if (index < 0) return;

    final item = state.cart.items[index];
    final clamped = quantity.clamp(item.minOrderQuantity, item.stockQuantity);

    emit(CartState(cart: state.cart.upsertItem(item.copyWith(quantity: clamped))));
  }

  // ── Toggle selection ──────────────────────────────────────────────────────────

  void toggleSelected(String productId) {
    final index =
        state.cart.items.indexWhere((i) => i.productId == productId);
    if (index < 0) return;

    final item = state.cart.items[index];
    emit(
      CartState(
        cart: state.cart.upsertItem(item.copyWith(selected: !item.selected)),
      ),
    );
  }

  // ── Remove item ───────────────────────────────────────────────────────────────

  void removeItem(String productId) {
    emit(CartState(cart: state.cart.removeItem(productId)));
  }

  // ── Clear all items ───────────────────────────────────────────────────────────

  void clearCart() {
    emit(const CartState(cart: Cart()));
  }
}

/// CartState wraps the [Cart] for Cubit.
class CartState extends Equatable {
  final Cart cart;

  const CartState({required this.cart});

  @override
  List<Object?> get props => [cart];
}
