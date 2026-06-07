import '../../../core/api/api_response.dart';
import 'warehouse.dart';

abstract class WarehouseRepository {
  Future<ApiResponse<List<Warehouse>>> getWarehouses();
}
