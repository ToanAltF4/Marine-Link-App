part of 'product_bloc.dart';

sealed class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch a paginated/filtered product list.
class ProductListRequested extends ProductEvent {
  final int page;
  final int size;
  final String? query;
  final String? categoryId;
  final bool? featured;
  final String? status;
  final String? sort;

  const ProductListRequested({
    this.page = 0,
    this.size = 20,
    this.query,
    this.categoryId,
    this.featured,
    this.status,
    this.sort,
  });

  @override
  List<Object?> get props => [
    page,
    size,
    query,
    categoryId,
    featured,
    status,
    sort,
  ];
}

/// Fetch full product detail.
class ProductDetailRequested extends ProductEvent {
  final String productId;

  const ProductDetailRequested(this.productId);

  @override
  List<Object?> get props => [productId];
}

/// Clear current detail (e.g. when navigating away).
class ProductDetailCleared extends ProductEvent {
  const ProductDetailCleared();
}
