part of 'admin_product_cubit.dart';

enum AdminProductStatusView { initial, loading, success, empty, failure }

enum AdminProductActionStatus { idle, saving, deleting, success, failure }

class AdminProductState extends Equatable {
  final AdminProductStatusView status;
  final List<AdminProduct> products;
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

  List<AdminProductCategory> get categories {
    final byId = <String, AdminProductCategory>{};
    for (final product in products) {
      final category = product.category;
      if (category != null && category.id.isNotEmpty) {
        byId[category.id] = category;
      }
    }
    return byId.values.toList();
  }

  AdminProductState copyWith({
    AdminProductStatusView? status,
    List<AdminProduct>? products,
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
    query,
    selectedStatus,
    selectedFeatured,
    actionStatus,
    editingProductId,
    deletingProductId,
    errorMessage,
  ];
}
