import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/app/di/service_locator.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/admin_products/domain/admin_product.dart';
import 'package:marinelink/features/admin_products/domain/admin_product_repository.dart';
import 'package:marinelink/features/admin_products/presentation/cubit/admin_product_cubit.dart';
import 'package:marinelink/features/admin_products/presentation/screens/admin_product_management_screen.dart';

class _FakeRepo implements AdminProductRepository {
  final Future<ApiResponse<List<AdminProduct>>> Function() listResponder;
  final Future<ApiResponse<AdminProduct>> Function(String id) detailResponder;
  final Future<ApiResponse<AdminProduct>> Function(AdminProductDraft draft)
  createResponder;
  final Future<ApiResponse<AdminProduct>> Function(
    String id,
    AdminProductDraft draft,
  )
  updateResponder;
  final Future<ApiResponse<void>> Function(String id) deleteResponder;

  _FakeRepo({
    required this.listResponder,
    Future<ApiResponse<AdminProduct>> Function(String id)? detailResponder,
    Future<ApiResponse<AdminProduct>> Function(AdminProductDraft draft)?
    createResponder,
    Future<ApiResponse<AdminProduct>> Function(
      String id,
      AdminProductDraft draft,
    )?
    updateResponder,
    Future<ApiResponse<void>> Function(String id)? deleteResponder,
  }) : detailResponder =
           detailResponder ??
           ((id) async => ApiResponse(
             success: true,
             message: 'OK',
             data: _detailProduct.copyWith(id: id),
           )),
       createResponder =
           createResponder ??
           ((draft) async => ApiResponse(
             success: true,
             message: 'OK',
             data: _productFromDraft('created-001', draft),
           )),
       updateResponder =
           updateResponder ??
           ((id, draft) async => ApiResponse(
             success: true,
             message: 'OK',
             data: _productFromDraft(id, draft),
           )),
       deleteResponder =
           deleteResponder ??
           ((_) async => const ApiResponse(success: true, message: 'OK'));

  @override
  Future<ApiResponse<List<AdminProduct>>> getProducts({
    String? query,
    AdminProductStatus? status,
    bool? featured,
    int? page,
    int? size,
  }) => page == null || page == 0
      ? listResponder()
      : Future.value(
          const ApiResponse(success: true, message: 'OK', data: []),
        );

  @override
  Future<ApiResponse<AdminProduct>> getProductDetail(String id) =>
      detailResponder(id);

  @override
  Future<ApiResponse<List<AdminProductCategory>>> getCategories() async =>
      const ApiResponse(success: true, message: 'OK', data: [_category]);

  @override
  Future<String> uploadProductImage({
    required List<int> bytes,
    required String fileName,
  }) async => 'https://cdn.test/$fileName';

  @override
  Future<ApiResponse<AdminProduct>> createProduct(AdminProductDraft draft) =>
      createResponder(draft);

  @override
  Future<ApiResponse<AdminProduct>> updateProduct(
    String id,
    AdminProductDraft draft,
  ) => updateResponder(id, draft);

  @override
  Future<ApiResponse<void>> deleteProduct(String id) => deleteResponder(id);
}

void _registerRepo(AdminProductRepository repo) {
  sl.registerFactory<AdminProductCubit>(
    () => AdminProductCubit(repository: repo),
  );
}

Future<void> _pumpScreen(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 1600);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    const MaterialApp(home: AdminProductManagementScreen()),
  );
}

void main() {
  setUp(() async => sl.reset());
  tearDown(() async => sl.reset());

  testWidgets('shows loading indicator while fetching products', (
    tester,
  ) async {
    final completer = Completer<ApiResponse<List<AdminProduct>>>();
    _registerRepo(_FakeRepo(listResponder: () => completer.future));

    await _pumpScreen(tester);
    await tester.pump();

    expect(find.byKey(const Key('adminProductsLoading')), findsOneWidget);
    expect(find.byKey(const Key('adminProductsList')), findsNothing);

    completer.complete(
      const ApiResponse(success: true, message: 'OK', data: [_activeProduct]),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('adminProductsLoading')), findsNothing);
  });

  testWidgets('renders products and filters by status', (tester) async {
    _registerRepo(
      _FakeRepo(
        listResponder: () async => const ApiResponse(
          success: true,
          message: 'OK',
          data: [_activeProduct, _disabledProduct],
        ),
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminProductsSummaryCard')), findsOneWidget);
    expect(
      find.byKey(const Key('adminProductCard_product-001')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('adminProductCard_product-002')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('adminProductStatusFilterDisabled')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminProductCard_product-001')), findsNothing);
    expect(
      find.byKey(const Key('adminProductCard_product-002')),
      findsOneWidget,
    );
  });

  testWidgets('creates, edits, and deletes a product from the list', (
    tester,
  ) async {
    _registerRepo(
      _FakeRepo(
        listResponder: () async => const ApiResponse(
          success: true,
          message: 'OK',
          data: [_activeProduct],
        ),
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('adminProductAddButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('adminProductNameField')),
      'Tôm khô mới',
    );
    await tester.enterText(
      find.byKey(const Key('adminProductSlugField')),
      'tom-kho-moi',
    );
    await tester.enterText(
      find.byKey(const Key('adminProductBasePriceField')),
      '680000',
    );
    await tester.enterText(
      find.byKey(const Key('adminProductStockField')),
      '40',
    );
    await tester.tap(find.byKey(const Key('adminProductSaveButton')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('adminProductCard_created-001')),
      findsOneWidget,
    );
    expect(find.text('Tôm khô mới'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('adminProductEditButton_created-001')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('adminProductNameField')),
      'Tôm khô cập nhật',
    );
    await tester.tap(find.byKey(const Key('adminProductSaveButton')));
    await tester.pumpAndSettle();

    expect(find.text('Tôm khô cập nhật'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('adminProductDeleteButton_created-001')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('adminProductDeleteConfirmButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminProductCard_created-001')), findsNothing);
  });

  testWidgets(
    'editing fetches the full detail so description and all tiers survive save',
    (tester) async {
      AdminProductDraft? capturedDraft;
      _registerRepo(
        _FakeRepo(
          listResponder: () async => const ApiResponse(
            success: true,
            message: 'OK',
            // Item danh sách: không có description, không có priceTiers.
            data: [_activeProduct],
          ),
          updateResponder: (id, draft) async {
            capturedDraft = draft;
            return ApiResponse(
              success: true,
              message: 'OK',
              data: _productFromDraft(id, draft),
            );
          },
        ),
      );

      await _pumpScreen(tester);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('adminProductEditButton_product-001')),
      );
      await tester.pumpAndSettle();

      // Form được dựng từ CHI TIẾT: mô tả và cả 2 mức giá sỉ đã prefill.
      expect(
        tester
            .widget<TextFormField>(
              find.descendant(
                of: find.byKey(const Key('adminProductDescriptionField')),
                matching: find.byType(TextFormField),
              ),
            )
            .controller
            ?.text,
        'Mực khô phục vụ đơn sỉ.',
      );
      expect(find.byKey(const Key('adminProductTierRow_0')), findsOneWidget);
      expect(find.byKey(const Key('adminProductTierRow_1')), findsOneWidget);

      await tester.tap(find.byKey(const Key('adminProductSaveButton')));
      await tester.pumpAndSettle();

      expect(capturedDraft, isNotNull);
      expect(capturedDraft!.description, 'Mực khô phục vụ đơn sỉ.');
      expect(capturedDraft!.priceTiers, hasLength(2));
      // Id của mức giá cũ được gửi lại -> backend cập nhật tại chỗ, không xoá dòng.
      expect(
        capturedDraft!.priceTiers.map((tier) => tier.id),
        ['tier-001', 'tier-002'],
      );
      expect(capturedDraft!.priceTiers.last.minQuantity, 10);
    },
  );

  testWidgets('adds and removes price tier rows', (tester) async {
    AdminProductDraft? capturedDraft;
    _registerRepo(
      _FakeRepo(
        listResponder: () async =>
            const ApiResponse(success: true, message: 'OK', data: []),
        createResponder: (draft) async {
          capturedDraft = draft;
          return ApiResponse(
            success: true,
            message: 'OK',
            data: _productFromDraft('created-003', draft),
          );
        },
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('adminProductAddButton')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('adminProductNameField')),
      'Mực khô mới',
    );
    await tester.enterText(
      find.byKey(const Key('adminProductSlugField')),
      'muc-kho-moi',
    );
    await tester.enterText(
      find.byKey(const Key('adminProductBasePriceField')),
      '450000',
    );
    await tester.enterText(
      find.byKey(const Key('adminProductStockField')),
      '20',
    );

    // Mức giá 1.
    await tester.enterText(
      find.byKey(const Key('adminProductTierMinField_0')),
      '2',
    );
    await tester.enterText(
      find.byKey(const Key('adminProductTierMaxField_0')),
      '9',
    );
    await tester.enterText(
      find.byKey(const Key('adminProductTierPriceField_0')),
      '450000',
    );

    // Thêm 2 mức nữa rồi xoá mức cuối -> còn 2 mức được gửi đi.
    await tester.tap(find.byKey(const Key('adminProductAddTierButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('adminProductAddTierButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('adminProductTierRow_2')), findsOneWidget);

    await tester.tap(find.byKey(const Key('adminProductRemoveTierButton_2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('adminProductTierRow_2')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('adminProductTierMinField_1')),
      '10',
    );
    await tester.enterText(
      find.byKey(const Key('adminProductTierPriceField_1')),
      '420000',
    );

    await tester.tap(find.byKey(const Key('adminProductSaveButton')));
    await tester.pumpAndSettle();

    expect(capturedDraft, isNotNull);
    expect(capturedDraft!.priceTiers, hasLength(2));
    expect(capturedDraft!.priceTiers.first.minQuantity, 2);
    expect(capturedDraft!.priceTiers.first.maxQuantity, 9);
    expect(capturedDraft!.priceTiers.last.minQuantity, 10);
    expect(capturedDraft!.priceTiers.last.maxQuantity, isNull);
    // Mức giá mới chưa có id -> backend sẽ tạo mới.
    expect(capturedDraft!.priceTiers.last.id, '');
  });

  testWidgets('updates successfully when optional fields are left blank', (
    tester,
  ) async {
    AdminProductDraft? capturedDraft;
    _registerRepo(
      _FakeRepo(
        listResponder: () async =>
            const ApiResponse(success: true, message: 'OK', data: [_activeProduct]),
        updateResponder: (id, draft) async {
          capturedDraft = draft;
          return ApiResponse(
            success: true,
            message: 'OK',
            data: _productFromDraft(id, draft),
          );
        },
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('adminProductEditButton_product-001')),
    );
    await tester.pumpAndSettle();

    for (final key in const [
      'adminProductShortDescriptionField',
      'adminProductDescriptionField',
      'adminProductOriginField',
      'adminProductImageUrlField',
    ]) {
      await tester.enterText(find.byKey(Key(key)), '   ');
    }
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('adminProductSaveButton')));
    await tester.pumpAndSettle();

    // Trường tuỳ chọn để trống -> gửi null, không chặn cập nhật.
    expect(capturedDraft, isNotNull);
    expect(capturedDraft!.shortDescription, isNull);
    expect(capturedDraft!.description, isNull);
    expect(capturedDraft!.origin, isNull);
    expect(capturedDraft!.imageUrl, isNull);
    expect(find.byKey(const Key('adminProductFormSheet')), findsNothing);
    expect(find.byKey(const Key('adminProductSuccessSnackBar')), findsOneWidget);
  });

  testWidgets('disables the save button and shows a spinner while submitting', (
    tester,
  ) async {
    final completer = Completer<ApiResponse<AdminProduct>>();
    _registerRepo(
      _FakeRepo(
        listResponder: () async =>
            const ApiResponse(success: true, message: 'OK', data: []),
        createResponder: (_) => completer.future,
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('adminProductAddButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('adminProductNameField')),
      'Tôm khô mới',
    );
    await tester.enterText(
      find.byKey(const Key('adminProductSlugField')),
      'tom-kho-moi',
    );
    await tester.enterText(
      find.byKey(const Key('adminProductBasePriceField')),
      '680000',
    );

    await tester.tap(find.byKey(const Key('adminProductSaveButton')));
    await tester.pump();

    final saveButton = tester.widget<FilledButton>(
      find.ancestor(
        of: find.byKey(const Key('adminProductSaveProgress')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(saveButton.onPressed, isNull, reason: 'không cho bấm lưu 2 lần');
    expect(find.byKey(const Key('adminProductSaveProgress')), findsOneWidget);

    completer.complete(
      const ApiResponse(success: true, message: 'OK', data: _activeProduct),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('adminProductFormSheet')), findsNothing);
  });

  testWidgets('shows an error snack bar when saving fails', (tester) async {
    _registerRepo(
      _FakeRepo(
        listResponder: () async =>
            const ApiResponse(success: true, message: 'OK', data: []),
        createResponder: (_) async =>
            const ApiResponse(success: false, message: 'Slug sản phẩm đã tồn tại.'),
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('adminProductAddButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('adminProductNameField')),
      'Tôm khô mới',
    );
    await tester.enterText(
      find.byKey(const Key('adminProductSlugField')),
      'tom-kho-moi',
    );
    await tester.enterText(
      find.byKey(const Key('adminProductBasePriceField')),
      '680000',
    );

    await tester.tap(find.byKey(const Key('adminProductSaveButton')));
    await tester.pumpAndSettle();

    // Form vẫn mở và người dùng thấy lý do thất bại.
    expect(find.byKey(const Key('adminProductFormSheet')), findsOneWidget);
    expect(find.byKey(const Key('adminProductErrorSnackBar')), findsOneWidget);
    expect(find.text('Slug sản phẩm đã tồn tại.'), findsOneWidget);
  });

  testWidgets('asks for confirmation before deleting', (tester) async {
    var deleteCalls = 0;
    _registerRepo(
      _FakeRepo(
        listResponder: () async =>
            const ApiResponse(success: true, message: 'OK', data: [_activeProduct]),
        deleteResponder: (_) async {
          deleteCalls++;
          return const ApiResponse(success: true, message: 'OK');
        },
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    // Huỷ xác nhận -> không xoá.
    await tester.tap(
      find.byKey(const Key('adminProductDeleteButton_product-001')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('adminProductDeleteConfirmDialog')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('adminProductDeleteCancelButton')));
    await tester.pumpAndSettle();

    expect(deleteCalls, 0);
    expect(
      find.byKey(const Key('adminProductCard_product-001')),
      findsOneWidget,
    );

    // Xác nhận -> xoá và báo thành công.
    await tester.tap(
      find.byKey(const Key('adminProductDeleteButton_product-001')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('adminProductDeleteConfirmButton')));
    await tester.pumpAndSettle();

    expect(deleteCalls, 1);
    expect(find.byKey(const Key('adminProductCard_product-001')), findsNothing);
    expect(find.byKey(const Key('adminProductSuccessSnackBar')), findsOneWidget);
  });

  testWidgets('shows an error snack bar when deleting fails', (tester) async {
    _registerRepo(
      _FakeRepo(
        listResponder: () async =>
            const ApiResponse(success: true, message: 'OK', data: [_activeProduct]),
        deleteResponder: (_) async =>
            const ApiResponse(success: false, message: 'Không xoá được sản phẩm.'),
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('adminProductDeleteButton_product-001')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('adminProductDeleteConfirmButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminProductErrorSnackBar')), findsOneWidget);
    expect(
      find.byKey(const Key('adminProductCard_product-001')),
      findsOneWidget,
    );
  });

  testWidgets('shows an error snack bar when the detail fetch fails', (
    tester,
  ) async {
    _registerRepo(
      _FakeRepo(
        listResponder: () async =>
            const ApiResponse(success: true, message: 'OK', data: [_activeProduct]),
        detailResponder: (_) async =>
            const ApiResponse(success: false, message: 'Không tìm thấy sản phẩm'),
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('adminProductEditButton_product-001')),
    );
    await tester.pumpAndSettle();

    // Không mở form với dữ liệu thiếu -> tránh lưu đè mất mô tả và giá sỉ.
    expect(find.byKey(const Key('adminProductFormSheet')), findsNothing);
    expect(find.byKey(const Key('adminProductErrorSnackBar')), findsOneWidget);
  });

  testWidgets('submits the selected category from the dropdown', (
    tester,
  ) async {
    AdminProductDraft? capturedDraft;
    _registerRepo(
      _FakeRepo(
        listResponder: () async =>
            const ApiResponse(success: true, message: 'OK', data: []),
        createResponder: (draft) async {
          capturedDraft = draft;
          return ApiResponse(
            success: true,
            message: 'OK',
            data: _productFromDraft('created-002', draft),
          );
        },
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('adminProductAddButton')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('adminProductCategoryDropdown')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('adminProductNameField')),
      'Mực khô mới',
    );
    await tester.enterText(
      find.byKey(const Key('adminProductSlugField')),
      'muc-kho-moi',
    );
    await tester.enterText(
      find.byKey(const Key('adminProductBasePriceField')),
      '450000',
    );
    await tester.enterText(
      find.byKey(const Key('adminProductStockField')),
      '20',
    );

    // Select the category from the dropdown.
    await tester.tap(find.byKey(const Key('adminProductCategoryDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mực khô').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('adminProductSaveButton')));
    await tester.pumpAndSettle();

    expect(capturedDraft, isNotNull);
    expect(capturedDraft!.categoryId, 'category-001');
  });

  testWidgets('shows image url field and preview when a url is entered', (
    tester,
  ) async {
    _registerRepo(
      _FakeRepo(
        listResponder: () async =>
            const ApiResponse(success: true, message: 'OK', data: []),
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('adminProductAddButton')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('adminProductPickImageButton')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('adminProductImagePreview')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('adminProductImageUrlField')),
      'https://cdn.test/muc.png',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminProductImagePreview')), findsOneWidget);
  });

  testWidgets('shows empty state when there are no products', (tester) async {
    _registerRepo(
      _FakeRepo(
        listResponder: () async =>
            const ApiResponse(success: true, message: 'OK', data: []),
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminProductsEmpty')), findsOneWidget);
    expect(find.textContaining('Chưa có sản phẩm'), findsOneWidget);
  });

  testWidgets('shows filtered empty state', (tester) async {
    _registerRepo(
      _FakeRepo(
        listResponder: () async => const ApiResponse(
          success: true,
          message: 'OK',
          data: [_activeProduct],
        ),
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('adminProductStatusFilterDisabled')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminProductsFilteredEmpty')), findsOneWidget);
  });

  testWidgets('shows error with retry, then recovers', (tester) async {
    var calls = 0;
    _registerRepo(
      _FakeRepo(
        listResponder: () async {
          calls++;
          if (calls == 1) {
            return const ApiResponse(success: false, message: 'Mất kết nối');
          }
          return const ApiResponse(
            success: true,
            message: 'OK',
            data: [_activeProduct],
          );
        },
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminProductsError')), findsOneWidget);
    expect(find.text('Mất kết nối'), findsOneWidget);

    await tester.tap(find.byKey(const Key('adminProductsRetryButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminProductsError')), findsNothing);
    expect(find.byKey(const Key('adminProductsList')), findsOneWidget);
  });

  testWidgets('admin mode shows the admin bottom nav', (tester) async {
    _registerRepo(
      _FakeRepo(
        listResponder: () async =>
            const ApiResponse(success: true, message: 'OK', data: [_activeProduct]),
      ),
    );
    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminBottomNavProducts')), findsOneWidget);
    expect(find.byKey(const Key('staffBottomNavWork')), findsNothing);
  });

  testWidgets('staff mode shows the staff bottom nav, not the admin one', (
    tester,
  ) async {
    _registerRepo(
      _FakeRepo(
        listResponder: () async =>
            const ApiResponse(success: true, message: 'OK', data: [_activeProduct]),
      ),
    );
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1600);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      const MaterialApp(home: AdminProductManagementScreen(staffMode: true)),
    );
    await tester.pumpAndSettle();

    // Staff must not be handed the admin-only navigation (which would bounce
    // them into the admin-guarded area on back/tab).
    expect(find.byKey(const Key('staffBottomNavWork')), findsOneWidget);
    expect(find.byKey(const Key('adminBottomNavProducts')), findsNothing);
  });
}

const _category = AdminProductCategory(id: 'category-001', name: 'Mực khô');

/// Item danh sách như backend trả về: KHÔNG có description, KHÔNG có priceTiers.
const _activeProduct = AdminProduct(
  id: 'product-001',
  name: 'Mực khô loại 1',
  slug: 'muc-kho-loai-1',
  basePrice: 450000,
  unit: 'kg',
  minOrderQuantity: 2,
  stockQuantity: 120,
  status: AdminProductStatus.active,
  isFeatured: true,
  category: _category,
);

/// Chi tiết đầy đủ trả về từ GET /api/admin/products/{id}.
const _detailProduct = AdminProduct(
  id: 'product-001',
  name: 'Mực khô loại 1',
  slug: 'muc-kho-loai-1',
  shortDescription: 'Mực size lớn',
  description: 'Mực khô phục vụ đơn sỉ.',
  origin: 'Cà Mau',
  basePrice: 450000,
  unit: 'kg',
  minOrderQuantity: 2,
  stockQuantity: 120,
  status: AdminProductStatus.active,
  isFeatured: true,
  category: _category,
  priceTiers: [
    AdminPriceTier(
      id: 'tier-001',
      minQuantity: 2,
      maxQuantity: 9,
      unitPrice: 450000,
    ),
    AdminPriceTier(id: 'tier-002', minQuantity: 10, unitPrice: 420000),
  ],
);

const _disabledProduct = AdminProduct(
  id: 'product-002',
  name: 'Cá chỉ vàng',
  slug: 'ca-chi-vang',
  basePrice: 240000,
  unit: 'kg',
  minOrderQuantity: 3,
  stockQuantity: 0,
  status: AdminProductStatus.disabled,
  isFeatured: false,
  category: _category,
);

AdminProduct _productFromDraft(String id, AdminProductDraft draft) {
  return AdminProduct(
    id: id,
    name: draft.name,
    slug: draft.slug,
    shortDescription: draft.shortDescription,
    description: draft.description,
    origin: draft.origin,
    basePrice: draft.basePrice,
    unit: draft.unit,
    minOrderQuantity: draft.minOrderQuantity,
    stockQuantity: draft.stockQuantity,
    status: draft.status,
    isFeatured: draft.isFeatured,
    category: _category,
    priceTiers: draft.priceTiers,
  );
}
