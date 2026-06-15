import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marinelink/features/cart/domain/cart.dart';
import 'package:marinelink/features/cart/domain/cart_repository.dart';
import 'package:marinelink/features/products/domain/product.dart';

/// CartCubit manages the local cart state.
class CartCubit extends Cubit<CartState> {
  final CartRepository? cartRepository;
  bool _remoteLoadAttempted = false;
  int _syncRevision = 0;

  CartCubit({this.cartRepository}) : super(const CartState(cart: Cart()));

  Future<void> loadCart({bool force = false}) async {
    final repository = cartRepository;
    if (repository == null) return;
    if (!force && (_remoteLoadAttempted || state.cart.isNotEmpty)) return;

    _remoteLoadAttempted = true;
    try {
      final remoteCart = await repository.loadCart();
      if (isClosed) return;
      emit(CartState(cart: remoteCart));
    } catch (_) {
      _remoteLoadAttempted = false;
      // Leave the current cart visible; checkout will surface server errors.
    }
  }

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

    _emitAndSync(state.cart.upsertItem(item));
  }

  void updateQuantity(String productId, int quantity) {
    final index = state.cart.items.indexWhere((i) => i.productId == productId);
    if (index < 0) return;

    final item = state.cart.items[index];
    _emitAndSync(state.cart.upsertItem(item.withQuantity(quantity)));
  }

  void toggleSelected(String productId) {
    final index = state.cart.items.indexWhere((i) => i.productId == productId);
    if (index < 0) return;

    final item = state.cart.items[index];
    _emitAndSync(
      state.cart.upsertItem(item.copyWith(selected: !item.selected)),
    );
  }

  void removeItem(String productId) {
    _emitAndSync(state.cart.removeItem(productId));
  }

  void clearCart() {
    _emitAndSync(const Cart());
  }

  void _emitAndSync(Cart cart) {
    emit(CartState(cart: cart));
    final revision = ++_syncRevision;
    unawaited(_syncRemote(cart, revision));
  }

  Future<void> _syncRemote(Cart cart, int revision) async {
    final repository = cartRepository;
    if (repository == null) return;
    try {
      final remoteCart = await repository.syncCart(cart);
      if (isClosed) return;
      if (revision != _syncRevision) return;
      emit(CartState(cart: remoteCart));
    } catch (_) {
      // Keep the optimistic local cart if the background sync fails.
    }
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
