import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../core/errors/user_facing_error.dart';
import '../../domain/admin_product.dart';
import '../../domain/admin_product_repository.dart';

part 'admin_product_state.dart';

class AdminProductCubit extends Cubit<AdminProductState> {
  final AdminProductRepository repository;

  /// The admin screen searches/filters client-side, so it must hold the whole
  /// catalogue: the backend list defaults to 20 per page and caps `size` at 100,
  /// which would leave products #21+ unreachable for edit/delete. We therefore
  /// request the biggest allowed page and keep paging until the catalogue is in.
  static const int productPageSize = 100;

  /// Safety net so a misbehaving backend cannot make [load] page forever.
  static const int maxProductPages = 20;

  AdminProductCubit({required this.repository})
    : super(const AdminProductState());

  Future<void> load() async {
    emit(state.copyWith(status: AdminProductStatusView.loading));
    try {
      final products = <AdminProduct>[];
      for (var page = 0; page < maxProductPages; page++) {
        final response = await repository.getProducts(
          page: page,
          size: productPageSize,
        );
        if (!response.success || response.data == null) {
          emit(
            state.copyWith(
              status: AdminProductStatusView.failure,
              errorMessage: userFacingResponseMessage(
                response.message,
                fallback: AppStrings.adminProductsLoadFailed,
              ),
            ),
          );
          return;
        }
        final pageProducts = response.data!;
        products.addAll(pageProducts);
        // A short page means we reached the end of the catalogue.
        if (pageProducts.length < productPageSize) break;
      }

      final categories = await _loadCategories();
      emit(
        state.copyWith(
          status: products.isEmpty
              ? AdminProductStatusView.empty
              : AdminProductStatusView.success,
          products: products,
          categories: categories,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AdminProductStatusView.failure,
          errorMessage: userFacingErrorMessage(
            error,
            fallback: AppStrings.adminProductsLoadUnexpected,
          ),
        ),
      );
    }
  }

  /// Fetch the FULL product detail before opening the edit form.
  ///
  /// The list item the screen holds has no `description` and no `priceTiers`
  /// (the backend list DTO omits them), so building the form from it and saving
  /// would wipe both. Returns null when the detail could not be loaded, leaving
  /// [AdminProductState.errorMessage] set for the caller to surface.
  Future<AdminProduct?> loadProductDetail(String id) async {
    emit(
      state.copyWith(
        actionStatus: AdminProductActionStatus.loadingDetail,
        editingProductId: id,
      ),
    );
    try {
      final response = await repository.getProductDetail(id);
      if (response.success && response.data != null) {
        emit(
          state.copyWith(
            actionStatus: AdminProductActionStatus.idle,
            clearEditingProductId: true,
          ),
        );
        return response.data;
      }
      emit(
        state.copyWith(
          actionStatus: AdminProductActionStatus.failure,
          errorMessage: userFacingResponseMessage(
            response.message,
            fallback: AppStrings.adminProductDetailLoadFailed,
          ),
          clearEditingProductId: true,
        ),
      );
      return null;
    } catch (error) {
      emit(
        state.copyWith(
          actionStatus: AdminProductActionStatus.failure,
          errorMessage: userFacingErrorMessage(
            error,
            fallback: AppStrings.adminProductDetailLoadUnexpected,
          ),
          clearEditingProductId: true,
        ),
      );
      return null;
    }
  }

  /// Load selectable categories for the product form. Categories are secondary
  /// data: a failure here must not fail the whole product list load, so we keep
  /// whatever was previously loaded.
  Future<List<AdminProductCategory>> _loadCategories() async {
    try {
      final response = await repository.getCategories();
      if (response.success && response.data != null) {
        return response.data!;
      }
    } catch (_) {
      // ignore — keep existing categories
    }
    return state.categories;
  }

  /// Upload an image picked from the device and return its public URL, or null
  /// if the upload failed. The form uses the returned URL as the product image.
  Future<String?> uploadProductImage(List<int> bytes, String fileName) async {
    try {
      return await repository.uploadProductImage(
        bytes: bytes,
        fileName: fileName,
      );
    } catch (_) {
      return null;
    }
  }

  void setQuery(String query) {
    emit(state.copyWith(query: query));
  }

  void setStatusFilter(AdminProductStatus? status) {
    emit(
      state.copyWith(
        selectedStatus: status,
        clearSelectedStatus: status == null,
      ),
    );
  }

  void setFeaturedFilter(bool? featured) {
    emit(
      state.copyWith(
        selectedFeatured: featured,
        clearSelectedFeatured: featured == null,
      ),
    );
  }

  Future<void> createProduct(AdminProductDraft draft) async {
    emit(state.copyWith(actionStatus: AdminProductActionStatus.saving));
    try {
      final response = await repository.createProduct(draft);
      if (response.success && response.data != null) {
        final products = [response.data!, ...state.products];
        emit(
          state.copyWith(
            status: products.isEmpty
                ? AdminProductStatusView.empty
                : AdminProductStatusView.success,
            products: products,
            actionStatus: AdminProductActionStatus.success,
          ),
        );
      } else {
        emit(
          state.copyWith(
            actionStatus: AdminProductActionStatus.failure,
            errorMessage: userFacingResponseMessage(
              response.message,
              fallback: AppStrings.adminProductCreateFailed,
            ),
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          actionStatus: AdminProductActionStatus.failure,
          errorMessage: userFacingErrorMessage(
            error,
            fallback: AppStrings.adminProductCreateUnexpected,
          ),
        ),
      );
    }
  }

  Future<void> updateProduct(String id, AdminProductDraft draft) async {
    emit(
      state.copyWith(
        actionStatus: AdminProductActionStatus.saving,
        editingProductId: id,
      ),
    );
    try {
      final response = await repository.updateProduct(id, draft);
      if (response.success && response.data != null) {
        final updated = response.data!;
        final products = [
          for (final product in state.products)
            if (product.id == id) updated else product,
        ];
        emit(
          state.copyWith(
            status: products.isEmpty
                ? AdminProductStatusView.empty
                : AdminProductStatusView.success,
            products: products,
            actionStatus: AdminProductActionStatus.success,
            clearEditingProductId: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            actionStatus: AdminProductActionStatus.failure,
            errorMessage: userFacingResponseMessage(
              response.message,
              fallback: AppStrings.adminProductUpdateFailed,
            ),
            clearEditingProductId: true,
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          actionStatus: AdminProductActionStatus.failure,
          errorMessage: userFacingErrorMessage(
            error,
            fallback: AppStrings.adminProductUpdateUnexpected,
          ),
          clearEditingProductId: true,
        ),
      );
    }
  }

  Future<void> deleteProduct(String id) async {
    emit(
      state.copyWith(
        actionStatus: AdminProductActionStatus.deleting,
        deletingProductId: id,
      ),
    );
    try {
      final response = await repository.deleteProduct(id);
      if (response.success) {
        final products = state.products
            .where((product) => product.id != id)
            .toList();
        emit(
          state.copyWith(
            status: products.isEmpty
                ? AdminProductStatusView.empty
                : AdminProductStatusView.success,
            products: products,
            actionStatus: AdminProductActionStatus.success,
            clearDeletingProductId: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            actionStatus: AdminProductActionStatus.failure,
            errorMessage: userFacingResponseMessage(
              response.message,
              fallback: AppStrings.adminProductDeleteFailed,
            ),
            clearDeletingProductId: true,
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          actionStatus: AdminProductActionStatus.failure,
          errorMessage: userFacingErrorMessage(
            error,
            fallback: AppStrings.adminProductDeleteUnexpected,
          ),
          clearDeletingProductId: true,
        ),
      );
    }
  }
}
