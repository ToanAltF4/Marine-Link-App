import 'package:geolocator/geolocator.dart';

import '../domain/warehouse_location_service.dart';
import '../domain/warehouse_user_location.dart';

class GeolocatorWarehouseLocationService implements WarehouseLocationService {
  @override
  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<WarehouseLocationPermission> checkPermission() async {
    return _mapPermission(await Geolocator.checkPermission());
  }

  @override
  Future<WarehouseLocationPermission> requestPermission() async {
    return _mapPermission(await Geolocator.requestPermission());
  }

  @override
  Future<WarehouseUserLocation> getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );
    return WarehouseUserLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  @override
  Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  @override
  Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }
}

WarehouseLocationPermission _mapPermission(LocationPermission permission) {
  return switch (permission) {
    LocationPermission.denied => WarehouseLocationPermission.denied,
    LocationPermission.deniedForever =>
      WarehouseLocationPermission.deniedForever,
    LocationPermission.whileInUse => WarehouseLocationPermission.whileInUse,
    LocationPermission.always => WarehouseLocationPermission.always,
    LocationPermission.unableToDetermine =>
      WarehouseLocationPermission.unableToDetermine,
  };
}
