import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marinelink/features/cart/domain/cart.dart';
import 'package:marinelink/features/cart/domain/cart_repository.dart';
import 'package:marinelink/features/products/domain/product.dart';

/// CartCubit manages cart UI state and reconciles remote carts from the API.
class CartCubit extends Cubit<CartState> {
  final CartRepository? cartRepository;
  bool _remoteLoadAttempted = false;
  int _remoteRevision = 0;

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

    final nextCart = state.cart.upsertItem(item);
    final repository = cartRepository;
    if (repository == null) {
      emit(CartState(cart: nextCart));
      return;
    }

    _emitAndReconcile(
      nextCart,
      () => repository.addItem(
        productId: product.id,
        quantity: clamped,
        selected: item.selected,
      ),
    );
  }

  void updateQuantity(String productId, int quantity) {
    final index = state.cart.items.indexWhere((i) => i.productId == productId);
    if (index < 0) return;

    final item = state.cart.items[index];
    final updatedItem = item.withQuantity(quantity);
    final nextCart = state.cart.upsertItem(updatedItem);
    final repository = cartRepository;
    if (repository == null) {
      emit(CartState(cart: nextCart));
      return;
    }

    _emitAndReconcile(
      nextCart,
      () => repository.updateItem(
        productId: productId,
        quantity: updatedItem.quantity,
      ),
    );
  }

  void toggleSelected(String productId) {
    final index = state.cart.items.indexWhere((i) => i.productId == productId);
    if (index < 0) return;

    final item = state.cart.items[index];
    final updatedItem = item.copyWith(selected: !item.selected);
    final nextCart = state.cart.upsertItem(updatedItem);
    final repository = cartRepository;
    if (repository == null) {
      emit(CartState(cart: nextCart));
      return;
    }

    _emitAndReconcile(
      nextCart,
      () => repository.updateItem(
        productId: productId,
        selected: updatedItem.selected,
      ),
    );
  }

  void removeItem(String productId) {
    final nextCart = state.cart.removeItem(productId);
    final repository = cartRepository;
    if (repository == null) {
      emit(CartState(cart: nextCart));
      return;
    }

    _emitAndReconcile(nextCart, () => repository.removeItem(productId));
  }

  void clearCart() {
    final repository = cartRepository;
    if (repository == null) {
      emit(const CartState(cart: Cart()));
      return;
    }

    _emitAndReconcile(const Cart(), repository.clear);
  }

  void _emitAndReconcile(Cart optimisticCart, Future<Cart> Function() request) {
    final previousCart = state.cart;
    emit(CartState(cart: optimisticCart));
    final revision = ++_remoteRevision;
    unawaited(_reconcileRemote(request, previousCart, revision));
  }

  Future<void> _reconcileRemote(
    Future<Cart> Function() request,
    Cart previousCart,
    int revision,
  ) async {
    try {
      final remoteCart = await request();
      if (isClosed) return;
      if (revision != _remoteRevision) return;
      emit(CartState(cart: remoteCart));
    } catch (_) {
      if (isClosed) return;
      if (revision != _remoteRevision) return;
      emit(CartState(cart: previousCart));
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
