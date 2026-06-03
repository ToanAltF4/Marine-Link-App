import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_response.dart';
import '../domain/product.dart';
import '../domain/product_repository.dart';
import 'product_dto.dart';

class ProductRemoteRepository implements ProductRepository {
  final ApiClient apiClient;

  const ProductRemoteRepository({required this.apiClient});

  @override
  Future<ApiResponse<List<Product>>> getProducts({
    int page = 0,
    int size = 20,
    String? query,
    String? categoryId,
    bool? featured,
    String? status,
    String? sort,
  }) {
    return apiClient.get<List<Product>>(
      ApiEndpoints.products,
      queryParameters: {
        'page': page,
        'size': size,
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (categoryId != null && categoryId.isNotEmpty)
          'categoryId': categoryId,
        'featured': ?featured,
        if (status != null && status.isNotEmpty) 'status': status,
        if (sort != null && sort.isNotEmpty) 'sort': sort,
      },
      fromJson: productListFromJson,
    );
  }

  @override
  Future<ApiResponse<ProductDetail>> getProductDetail(String productId) {
    return apiClient.get<ProductDetail>(
      ApiEndpoints.productDetail(productId),
      fromJson: productDetailFromJson,
    );
  }
}
