part of 'admin_product_cubit.dart';

enum AdminProductStatusView { initial, loading, success, empty, failure }

enum AdminProductActionStatus { idle, saving, deleting, success, failure }

class AdminProductState extends Equatable {
  final AdminProductStatusView status;
  final List<AdminProduct> products;
  final List<AdminProductCategory> categories;
  final String query;
  final AdminProductStatus? selectedStatus;
  final bool? selectedFeatured;
  final AdminProductActionStatus actionStatus;
  final String? editingProductId;
  final String? deletingProductId;
  final String? errorMessage;

  const AdminProductState({
    this.status = AdminProductStatusView.initial,
    this.products = const [],
    this.categories = const [],
    this.query = '',
    this.selectedStatus,
    this.selectedFeatured,
    this.actionStatus = AdminProductActionStatus.idle,
    this.editingProductId,
    this.deletingProductId,
    this.errorMessage,
  });

  List<AdminProduct> get visibleProducts {
    final normalizedQuery = query.trim().toLowerCase();
    return products.where((product) {
      final queryMatches =
          normalizedQuery.isEmpty ||
          product.name.toLowerCase().contains(normalizedQuery) ||
          product.slug.toLowerCase().contains(normalizedQuery) ||
          (product.origin ?? '').toLowerCase().contains(normalizedQuery);
      final statusMatches =
          selectedStatus == null || product.status == selectedStatus;
      final featuredMatches =
          selectedFeatured == null || product.isFeatured == selectedFeatured;
      return queryMatches && statusMatches && featuredMatches;
    }).toList();
  }

  AdminProductState copyWith({
    AdminProductStatusView? status,
    List<AdminProduct>? products,
    List<AdminProductCategory>? categories,
    String? query,
    AdminProductStatus? selectedStatus,
    bool clearSelectedStatus = false,
    bool? selectedFeatured,
    bool clearSelectedFeatured = false,
    AdminProductActionStatus? actionStatus,
    String? editingProductId,
    bool clearEditingProductId = false,
    String? deletingProductId,
    bool clearDeletingProductId = false,
    String? errorMessage,
  }) {
    return AdminProductState(
      status: status ?? this.status,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      query: query ?? this.query,
      selectedStatus: clearSelectedStatus
          ? null
          : selectedStatus ?? this.selectedStatus,
      selectedFeatured: clearSelectedFeatured
          ? null
          : selectedFeatured ?? this.selectedFeatured,
      actionStatus: actionStatus ?? this.actionStatus,
      editingProductId: clearEditingProductId
          ? null
          : editingProductId ?? this.editingProductId,
      deletingProductId: clearDeletingProductId
          ? null
          : deletingProductId ?? this.deletingProductId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    products,
    categories,
    query,
    selectedStatus,
    selectedFeatured,
    actionStatus,
    editingProductId,
    deletingProductId,
    errorMessage,
  ];
}
