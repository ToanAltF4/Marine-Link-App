part of 'product_bloc.dart';

sealed class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {
  const ProductInitial();
}

class ProductListLoading extends ProductState {
  const ProductListLoading();
}

class ProductListLoaded extends ProductState {
  final List<Product> products;
  final int currentPage;
  final int totalPages;
  final bool hasMore;

  const ProductListLoaded({
    required this.products,
    required this.currentPage,
    required this.totalPages,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [products, currentPage, totalPages];
}

class ProductListEmpty extends ProductState {
  const ProductListEmpty();
}

class ProductListError extends ProductState {
  final String message;

  const ProductListError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProductDetailLoading extends ProductState {
  const ProductDetailLoading();
}

class ProductDetailLoaded extends ProductState {
  final ProductDetail product;

  const ProductDetailLoaded(this.product);

  @override
  List<Object?> get props => [product];
}

class ProductDetailError extends ProductState {
  final String message;

  const ProductDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
