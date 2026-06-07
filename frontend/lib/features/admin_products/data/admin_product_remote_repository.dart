import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_response.dart';
import '../domain/admin_product.dart';
import '../domain/admin_product_repository.dart';
import 'admin_product_dto.dart';

class AdminProductRemoteRepository implements AdminProductRepository {
  final ApiClient apiClient;

  const AdminProductRemoteRepository({required this.apiClient});

  @override
  Future<ApiResponse<List<AdminProduct>>> getProducts({
    String? query,
    AdminProductStatus? status,
    bool? featured,
  }) {
    final normalizedQuery = query?.trim();
    return apiClient.get<List<AdminProduct>>(
      ApiEndpoints.adminProducts,
      queryParameters: {
        if (normalizedQuery case final keyword? when keyword.isNotEmpty)
          'q': keyword,
        ...?(status == null ? null : {'status': status.apiValue}),
        ...?(featured == null ? null : {'featured': featured}),
      },
      fromJson: adminProductsFromJson,
    );
  }

  @override
  Future<ApiResponse<AdminProduct>> createProduct(AdminProductDraft draft) {
    return apiClient.post<AdminProduct>(
      ApiEndpoints.adminProducts,
      data: adminProductDraftToJson(draft),
      fromJson: adminProductFromJson,
    );
  }

  @override
  Future<ApiResponse<AdminProduct>> updateProduct(
    String id,
    AdminProductDraft draft,
  ) {
    return apiClient.put<AdminProduct>(
      ApiEndpoints.adminProductDetail(id),
      data: adminProductDraftToJson(draft),
      fromJson: adminProductFromJson,
    );
  }

  @override
  Future<ApiResponse<void>> deleteProduct(String id) async {
    await apiClient.delete(ApiEndpoints.adminProductDetail(id));
    return const ApiResponse(success: true, message: 'OK');
  }
}
