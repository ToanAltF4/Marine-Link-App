/// Dart representation of the unified API response envelope.
///
/// Matches the JSON structure from MarineLink_API_Documentation.md:
/// ```json
/// { "success": true, "data": {}, "message": "OK", "pagination": {...} }
/// ```
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final List<ApiFieldError>? errors;
  final ApiPagination? pagination;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
    this.pagination,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJson,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] != null ? fromJson(json['data']) : null,
      errors: (json['errors'] as List<dynamic>?)
          ?.map((e) => ApiFieldError.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: json['pagination'] != null
          ? ApiPagination.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ApiFieldError {
  final String? field;
  final String? message;

  const ApiFieldError({this.field, this.message});

  factory ApiFieldError.fromJson(Map<String, dynamic> json) {
    return ApiFieldError(
      field: json['field'] as String?,
      message: json['message'] as String?,
    );
  }
}

class ApiPagination {
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  const ApiPagination({
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  factory ApiPagination.fromJson(Map<String, dynamic> json) {
    return ApiPagination(
      page: json['page'] as int? ?? 0,
      size: json['size'] as int? ?? 20,
      totalElements: json['totalElements'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }
}
