import '../../../core/api/api_response.dart';
import 'admin_product.dart';

abstract class AdminProductRepository {
  Future<ApiResponse<List<AdminProduct>>> getProducts({
    String? query,
    AdminProductStatus? status,
    bool? featured,
  });

  Future<ApiResponse<AdminProduct>> createProduct(AdminProductDraft draft);

  Future<ApiResponse<AdminProduct>> updateProduct(
    String id,
    AdminProductDraft draft,
  );

  Future<ApiResponse<void>> deleteProduct(String id);
}
