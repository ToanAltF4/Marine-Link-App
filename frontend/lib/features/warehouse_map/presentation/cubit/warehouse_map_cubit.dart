import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/errors/user_facing_error.dart';
import '../../domain/warehouse.dart';
import '../../domain/warehouse_repository.dart';

part 'warehouse_map_state.dart';

class WarehouseMapCubit extends Cubit<WarehouseMapState> {
  final WarehouseRepository repository;

  WarehouseMapCubit({required this.repository})
    : super(const WarehouseMapState());

  Future<void> load() async {
    emit(state.copyWith(status: WarehouseMapStatus.loading));
    try {
      final response = await repository.getWarehouses();
      if (!response.success) {
        emit(
          state.copyWith(
            status: WarehouseMapStatus.failure,
            errorMessage: userFacingResponseMessage(
              response.message,
              fallback: AppStrings.warehouseLoadFailed,
            ),
          ),
        );
        return;
      }

      final warehouses = response.data ?? const <Warehouse>[];
      emit(
        state.copyWith(
          status: warehouses.isEmpty
              ? WarehouseMapStatus.empty
              : WarehouseMapStatus.success,
          warehouses: warehouses,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: WarehouseMapStatus.failure,
          errorMessage: userFacingErrorMessage(
            e,
            fallback: AppStrings.warehouseLoadFailed,
          ),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: WarehouseMapStatus.failure,
          errorMessage: AppStrings.warehouseLoadFailed,
        ),
      );
    }
  }
}
