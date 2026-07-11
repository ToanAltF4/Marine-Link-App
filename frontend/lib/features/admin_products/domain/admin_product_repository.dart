import '../../../core/api/api_response.dart';
import 'admin_product.dart';

abstract class AdminProductRepository {
  Future<ApiResponse<List<AdminProduct>>> getProducts({
    String? query,
    AdminProductStatus? status,
    bool? featured,
  });

  /// Fetch the selectable product categories for the admin form dropdown.
  Future<ApiResponse<List<AdminProductCategory>>> getCategories();

  /// Upload an image picked from the device and return its public URL.
  Future<String> uploadProductImage({
    required List<int> bytes,
    required String fileName,
  });

  Future<ApiResponse<AdminProduct>> createProduct(AdminProductDraft draft);

  Future<ApiResponse<AdminProduct>> updateProduct(
    String id,
    AdminProductDraft draft,
  );

  Future<ApiResponse<void>> deleteProduct(String id);
}
