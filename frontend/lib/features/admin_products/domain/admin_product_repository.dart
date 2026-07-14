import '../../../core/api/api_response.dart';
import 'admin_product.dart';

abstract class AdminProductRepository {
  /// Fetch a page of products for the admin list. [size] must be large enough to
  /// cover the whole catalogue, otherwise products beyond the first page cannot
  /// be found (and therefore cannot be edited/deleted) from the admin screen.
  Future<ApiResponse<List<AdminProduct>>> getProducts({
    String? query,
    AdminProductStatus? status,
    bool? featured,
    int? page,
    int? size,
  });

  /// Fetch the FULL product detail (`GET /api/admin/products/{id}`).
  ///
  /// The list endpoint returns a trimmed item without `description` and without
  /// `priceTiers`, so the edit form must be built from this detail — otherwise a
  /// save would send them back empty and wipe them.
  Future<ApiResponse<AdminProduct>> getProductDetail(String id);

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
