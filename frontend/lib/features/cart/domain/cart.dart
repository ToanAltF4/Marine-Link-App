import 'package:equatable/equatable.dart';

/// Domain entity: CartItem.
/// Represents a single item in the local cart.
class CartItem extends Equatable {
  final String productId;
  final String productName;
  final String productImageUrl;
  final String unit;
  final int quantity;
  final double unitPrice; // effective price (from price tier)
  final String? selectedPriceTierId;
  final bool selected;
  final int minOrderQuantity;
  final int stockQuantity;

  const CartItem({
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    this.selectedPriceTierId,
    this.selected = true,
    this.minOrderQuantity = 1,
    this.stockQuantity = 0,
  });

  double get lineTotal => unitPrice * quantity;

  bool get isValid =>
      quantity >= minOrderQuantity && quantity <= stockQuantity;

  CartItem copyWith({
    int? quantity,
    double? unitPrice,
    String? selectedPriceTierId,
    bool? selected,
  }) {
    return CartItem(
      productId: productId,
      productName: productName,
      productImageUrl: productImageUrl,
      unit: unit,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      selectedPriceTierId: selectedPriceTierId ?? this.selectedPriceTierId,
      selected: selected ?? this.selected,
      minOrderQuantity: minOrderQuantity,
      stockQuantity: stockQuantity,
    );
  }

  @override
  List<Object?> get props => [productId, quantity, selected];
}

/// Domain entity: Cart.
/// Holds the local cart state. Synced to backend before checkout via /api/cart/sync.
class Cart extends Equatable {
  final String? cartId; // server-assigned after sync
  final List<CartItem> items;

  const Cart({this.cartId, this.items = const []});

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  List<CartItem> get selectedItems =>
      items.where((i) => i.selected).toList();

  double get subtotalAmount =>
      selectedItems.fold(0, (sum, item) => sum + item.lineTotal);

  int get totalSelectedItemCount =>
      selectedItems.fold(0, (sum, item) => sum + item.quantity);

  /// Returns a new Cart with the item updated, or added if not present.
  Cart upsertItem(CartItem item) {
    final index = items.indexWhere((i) => i.productId == item.productId);
    final updated = List<CartItem>.from(items);
    if (index >= 0) {
      updated[index] = item;
    } else {
      updated.add(item);
    }
    return Cart(cartId: cartId, items: updated);
  }

  /// Returns a new Cart with the item removed.
  Cart removeItem(String productId) {
    return Cart(
      cartId: cartId,
      items: items.where((i) => i.productId != productId).toList(),
    );
  }

  /// Returns a new Cart with all items cleared.
  Cart clear() => const Cart();

  @override
  List<Object?> get props => [cartId, items];
}
