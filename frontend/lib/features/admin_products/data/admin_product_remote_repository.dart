import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_response.dart';
import '../../../core/constants/app_strings.dart';
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
  Future<ApiResponse<List<AdminProductCategory>>> getCategories() {
    return apiClient.get<List<AdminProductCategory>>(
      ApiEndpoints.productCategories,
      fromJson: adminCategoriesFromJson,
    );
  }

  @override
  Future<String> uploadProductImage({
    required List<int> bytes,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final response = await apiClient.postMultipart<String>(
      ApiEndpoints.storageUpload,
      formData: formData,
      fromJson: uploadedImageUrlFromJson,
    );
    final url = response.data;
    if (!response.success || url == null || url.isEmpty) {
      throw const ApiException(
        message: AppStrings.imageUploadFailed,
        type: ApiExceptionType.server,
      );
    }
    return url;
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
