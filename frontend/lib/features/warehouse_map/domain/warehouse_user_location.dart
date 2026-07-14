import 'package:equatable/equatable.dart';

class WarehouseUserLocation extends Equatable {
  final double latitude;
  final double longitude;

  const WarehouseUserLocation({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}
