// ignore_for_file: prefer_initializing_formals

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/product.dart';
import '../../domain/product_repository.dart';

part 'product_event.dart';
part 'product_state.dart';

/// ProductBloc handles product list and product detail states.
///
/// Repository is injected — switch from ProductMockRepository to
/// ProductRemoteRepository in Sprint 5 via DI without changing this bloc.
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository _productRepository;

  ProductBloc({required ProductRepository productRepository})
    : _productRepository = productRepository,
      super(const ProductInitial()) {
    on<ProductListRequested>(_onListRequested);
    on<ProductDetailRequested>(_onDetailRequested);
    on<ProductDetailCleared>(_onDetailCleared);
  }

  Future<void> _onListRequested(
    ProductListRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductListLoading());
    try {
      final response = await _productRepository.getProducts(
        page: event.page,
        size: event.size,
        query: event.query,
        categoryId: event.categoryId,
        featured: event.featured,
        status: event.status,
        sort: event.sort,
      );

      if (!response.success || response.data == null) {
        emit(ProductListError(response.message ?? 'Lỗi tải danh sách sản phẩm'));
        return;
      }

      final products = response.data!;
      if (products.isEmpty) {
        emit(const ProductListEmpty());
      } else {
        final pagination = response.pagination;
        emit(
          ProductListLoaded(
            products: products,
            currentPage: pagination?.page ?? 0,
            totalPages: pagination?.totalPages ?? 1,
            hasMore: pagination != null &&
                pagination.page < pagination.totalPages - 1,
          ),
        );
      }
    } catch (e) {
      emit(ProductListError(e.toString()));
    }
  }

  Future<void> _onDetailRequested(
    ProductDetailRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductDetailLoading());
    try {
      final response =
          await _productRepository.getProductDetail(event.productId);

      if (!response.success || response.data == null) {
        emit(ProductDetailError(
          response.message ?? 'Không tìm thấy sản phẩm',
        ));
        return;
      }

      emit(ProductDetailLoaded(response.data!));
    } catch (e) {
      emit(ProductDetailError(e.toString()));
    }
  }

  void _onDetailCleared(
    ProductDetailCleared event,
    Emitter<ProductState> emit,
  ) {
    emit(const ProductInitial());
  }
}
