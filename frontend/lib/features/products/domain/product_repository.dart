import '../domain/product.dart';
import '../../../core/api/api_response.dart';

/// Abstract product repository interface.
/// Mock implementation: ProductMockRepository (data/)
/// Remote implementation: ProductRemoteRepository (data/) — Sprint 5
abstract class ProductRepository {
  /// Fetch paginated product list.
  /// [query] for search, [categoryId] to filter, [featured] for home screen.
  Future<ApiResponse<List<Product>>> getProducts({
    int page = 0,
    int size = 20,
    String? query,
    String? categoryId,
    bool? featured,
    String? status,
    String? sort,
  });

  /// Fetch full product detail including images and price tiers.
  Future<ApiResponse<ProductDetail>> getProductDetail(String productId);
}
