import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../core/errors/user_facing_error.dart';
import '../../domain/admin_product.dart';
import '../../domain/admin_product_repository.dart';

part 'admin_product_state.dart';

class AdminProductCubit extends Cubit<AdminProductState> {
  final AdminProductRepository repository;

  AdminProductCubit({required this.repository})
    : super(const AdminProductState());

  Future<void> load() async {
    emit(state.copyWith(status: AdminProductStatusView.loading));
    try {
      final response = await repository.getProducts();
      if (response.success && response.data != null) {
        final products = response.data!;
        emit(
          state.copyWith(
            status: products.isEmpty
                ? AdminProductStatusView.empty
                : AdminProductStatusView.success,
            products: products,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: AdminProductStatusView.failure,
            errorMessage: userFacingResponseMessage(
              response.message,
              fallback: AppStrings.adminProductsLoadFailed,
            ),
          ),
        );
      }
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
