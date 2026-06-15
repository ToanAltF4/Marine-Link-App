import '../../products/domain/product.dart';
import '../domain/cart.dart';

class CartDto {
  final String? cartId;
  final List<CartItemDto> items;

  const CartDto({this.cartId, this.items = const []});

  factory CartDto.fromJson(Map<String, dynamic> json) {
    return CartDto(
      cartId: json['cartId'] as String?,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => CartItemDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Cart toDomain() {
    final uniqueItems = <String, CartItem>{};
    for (final item in items.map((e) => e.toDomain())) {
      final existing = uniqueItems[item.productId];
      uniqueItems[item.productId] = existing == null
          ? item
          : item.withQuantity(existing.quantity + item.quantity);
    }
    return Cart(cartId: cartId, items: uniqueItems.values.toList());
  }
}

class CartItemDto {
  final String productId;
  final String productName;
  final String productImageUrl;
  final String unit;
  final int quantity;
  final bool selected;
  final String? selectedPriceTierId;
  final double baseUnitPrice;
  final double unitPrice;
  final int minOrderQuantity;
  final int stockQuantity;
  final List<CartPriceTierDto> priceTiers;

  const CartItemDto({
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.unit,
    required this.quantity,
    required this.selected,
    this.selectedPriceTierId,
    required this.baseUnitPrice,
    required this.unitPrice,
    required this.minOrderQuantity,
    required this.stockQuantity,
    this.priceTiers = const [],
  });

  factory CartItemDto.fromJson(Map<String, dynamic> json) {
    final unitPrice = (json['unitPrice'] as num? ?? 0).toDouble();
    final quantity = json['quantity'] as int? ?? 1;
    return CartItemDto(
      productId: json['productId'] as String,
      productName: json['productName'] as String? ?? '',
      productImageUrl: json['productImageUrl'] as String? ?? '',
      unit: json['unit'] as String? ?? 'kg',
      quantity: quantity,
      selected: json['selected'] as bool? ?? true,
      selectedPriceTierId: json['selectedPriceTierId'] as String?,
      baseUnitPrice: (json['baseUnitPrice'] as num?)?.toDouble() ?? unitPrice,
      unitPrice: unitPrice,
      minOrderQuantity: json['minOrderQuantity'] as int? ?? 1,
      stockQuantity: json['stockQuantity'] as int? ?? quantity,
      priceTiers:
          (json['priceTiers'] as List<dynamic>?)
              ?.map((e) => CartPriceTierDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  CartItem toDomain() {
    return CartItem(
      productId: productId,
      productName: productName,
      productImageUrl: productImageUrl,
      unit: unit,
      quantity: quantity,
      baseUnitPrice: baseUnitPrice,
      unitPrice: unitPrice,
      selectedPriceTierId: selectedPriceTierId,
      priceTiers: priceTiers.map((e) => e.toDomain()).toList(),
      selected: selected,
      minOrderQuantity: minOrderQuantity,
      stockQuantity: stockQuantity,
    );
  }
}

class CartPriceTierDto {
  final String id;
  final int minQuantity;
  final int? maxQuantity;
  final double unitPrice;

  const CartPriceTierDto({
    required this.id,
    required this.minQuantity,
    this.maxQuantity,
    required this.unitPrice,
  });

  factory CartPriceTierDto.fromJson(Map<String, dynamic> json) {
    return CartPriceTierDto(
      id: json['id'] as String,
      minQuantity: json['minQuantity'] as int,
      maxQuantity: json['maxQuantity'] as int?,
      unitPrice: (json['unitPrice'] as num).toDouble(),
    );
  }

  PriceTier toDomain() => PriceTier(
    id: id,
    minQuantity: minQuantity,
    maxQuantity: maxQuantity,
    unitPrice: unitPrice,
  );
}

Cart cartFromJson(dynamic json) {
  return CartDto.fromJson(json as Map<String, dynamic>).toDomain();
}
