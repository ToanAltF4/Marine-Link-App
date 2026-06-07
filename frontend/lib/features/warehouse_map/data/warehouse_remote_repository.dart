import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_response.dart';
import '../domain/warehouse.dart';
import '../domain/warehouse_repository.dart';
import 'warehouse_dto.dart';

class WarehouseRemoteRepository implements WarehouseRepository {
  final ApiClient apiClient;

  WarehouseRemoteRepository({required this.apiClient});

  @override
  Future<ApiResponse<List<Warehouse>>> getWarehouses() {
    return apiClient.get<List<Warehouse>>(
      ApiEndpoints.warehouses,
      fromJson: warehousesFromJson,
    );
  }
}
