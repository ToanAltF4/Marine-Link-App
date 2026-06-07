import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/warehouse_location_service.dart';
import '../../domain/warehouse_user_location.dart';

part 'warehouse_location_state.dart';

class WarehouseLocationCubit extends Cubit<WarehouseLocationState> {
  final WarehouseLocationService service;

  WarehouseLocationCubit({required this.service})
    : super(const WarehouseLocationState());

  Future<void> loadStatus() async {
    emit(state.copyWith(status: WarehouseLocationStatus.checking));
    try {
      final serviceEnabled = await service.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(state.copyWith(status: WarehouseLocationStatus.serviceDisabled));
        return;
      }

      final permission = await service.checkPermission();
      await _handlePermission(permission);
    } catch (_) {
      emit(
        state.copyWith(
          status: WarehouseLocationStatus.failure,
          errorMessage: 'Không kiểm tra được quyền vị trí.',
        ),
      );
    }
  }

  Future<void> requestCurrentLocation() async {
    emit(state.copyWith(status: WarehouseLocationStatus.checking));
    try {
      final serviceEnabled = await service.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(state.copyWith(status: WarehouseLocationStatus.serviceDisabled));
        return;
      }

      var permission = await service.checkPermission();
      if (permission == WarehouseLocationPermission.denied ||
          permission == WarehouseLocationPermission.unableToDetermine) {
        permission = await service.requestPermission();
      }
      await _handlePermission(permission);
    } catch (_) {
      emit(
        state.copyWith(
          status: WarehouseLocationStatus.failure,
          errorMessage: 'Không lấy được vị trí hiện tại.',
        ),
      );
    }
  }

  Future<bool> openAppSettings() {
    return service.openAppSettings();
  }

  Future<bool> openLocationSettings() {
    return service.openLocationSettings();
  }

  Future<void> _handlePermission(WarehouseLocationPermission permission) async {
    switch (permission) {
      case WarehouseLocationPermission.always:
      case WarehouseLocationPermission.whileInUse:
        final location = await service.getCurrentLocation();
        emit(
          state.copyWith(
            status: WarehouseLocationStatus.granted,
            location: location,
          ),
        );
        return;
      case WarehouseLocationPermission.denied:
      case WarehouseLocationPermission.unableToDetermine:
        emit(state.copyWith(status: WarehouseLocationStatus.denied));
        return;
      case WarehouseLocationPermission.deniedForever:
        emit(state.copyWith(status: WarehouseLocationStatus.deniedForever));
        return;
    }
  }
}
