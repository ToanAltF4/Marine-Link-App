import 'package:equatable/equatable.dart';

class Warehouse extends Equatable {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? openingHours;
  final double latitude;
  final double longitude;
  final bool isActive;

  const Warehouse({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.openingHours,
    required this.latitude,
    required this.longitude,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    address,
    phone,
    openingHours,
    latitude,
    longitude,
    isActive,
  ];
}
