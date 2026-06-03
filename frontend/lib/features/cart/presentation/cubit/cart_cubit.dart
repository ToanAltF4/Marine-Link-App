import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marinelink/features/cart/domain/cart.dart';
import 'package:marinelink/features/products/domain/product.dart';

/// CartCubit manages the local cart state.
class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState(cart: Cart()));

  void addItem({required ProductDetail product, int quantity = 1}) {
    final existingIndex = state.cart.items.indexWhere(
      (i) => i.productId == product.id,
    );

    final int newQuantity = existingIndex >= 0
        ? state.cart.items[existingIndex].quantity + quantity
        : quantity;

    final clamped = newQuantity.clamp(
      product.minOrderQuantity,
      product.stockQuantity,
    );

    final tier = product.tierFor(clamped);
    final unitPrice = tier?.unitPrice ?? product.basePrice;

    final item = CartItem(
      productId: product.id,
      productName: product.name,
      productImageUrl: product.imageUrl ?? '',
      unit: product.unit,
      quantity: clamped,
      baseUnitPrice: product.basePrice,
      unitPrice: unitPrice,
      selectedPriceTierId: tier?.id,
      priceTiers: product.priceTiers,
      minOrderQuantity: product.minOrderQuantity,
      stockQuantity: product.stockQuantity,
    );

    emit(CartState(cart: state.cart.upsertItem(item)));
  }

  void updateQuantity(String productId, int quantity) {
    final index = state.cart.items.indexWhere((i) => i.productId == productId);
    if (index < 0) return;

    final item = state.cart.items[index];
    emit(CartState(cart: state.cart.upsertItem(item.withQuantity(quantity))));
  }

  void toggleSelected(String productId) {
    final index = state.cart.items.indexWhere((i) => i.productId == productId);
    if (index < 0) return;

    final item = state.cart.items[index];
    emit(
      CartState(
        cart: state.cart.upsertItem(item.copyWith(selected: !item.selected)),
      ),
    );
  }

  void removeItem(String productId) {
    emit(CartState(cart: state.cart.removeItem(productId)));
  }

  void clearCart() {
    emit(const CartState(cart: Cart()));
  }
}

/// CartState wraps the [Cart] for Cubit.
class CartState extends Equatable {
  final Cart cart;

  const CartState({required this.cart});

  bool get canCheckout => cart.selectedItems.isNotEmpty;

  double get subtotalAmount => cart.subtotalAmount;

  int get totalSelectedItemCount => cart.totalSelectedItemCount;

  @override
  List<Object?> get props => [cart];
}
