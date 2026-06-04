import 'package:equatable/equatable.dart';

class ShippingAddress extends Equatable {
  final String id;
  final String? label;
  final String receiverName;
  final String receiverPhone;
  final String addressLine;
  final bool isDefault;

  const ShippingAddress({
    required this.id,
    this.label,
    required this.receiverName,
    required this.receiverPhone,
    required this.addressLine,
    required this.isDefault,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      id: json['id'] as String? ?? '',
      label: json['label'] as String?,
      receiverName: json['receiverName'] as String? ?? '',
      receiverPhone: json['receiverPhone'] as String? ?? '',
      addressLine: json['addressLine'] as String? ?? '',
      isDefault: json['default'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    label,
    receiverName,
    receiverPhone,
    addressLine,
    isDefault,
  ];
}

class ShippingAddressInput extends Equatable {
  final String? label;
  final String receiverName;
  final String receiverPhone;
  final String addressLine;
  final bool isDefault;

  const ShippingAddressInput({
    this.label,
    required this.receiverName,
    required this.receiverPhone,
    required this.addressLine,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'addressLine': addressLine,
      'default': isDefault,
    };
  }

  @override
  List<Object?> get props => [
    label,
    receiverName,
    receiverPhone,
    addressLine,
    isDefault,
  ];
}
