import 'warehouse_user_location.dart';

enum WarehouseLocationPermission {
  denied,
  deniedForever,
  whileInUse,
  always,
  unableToDetermine,
}

abstract class WarehouseLocationService {
  Future<bool> isLocationServiceEnabled();

  Future<WarehouseLocationPermission> checkPermission();

  Future<WarehouseLocationPermission> requestPermission();

  Future<WarehouseUserLocation> getCurrentLocation();

  Future<bool> openAppSettings();

  Future<bool> openLocationSettings();
}
