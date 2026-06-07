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
    Future<ApiResponse<AdminProduct>> Function(AdminProductDraft draft)?
    createResponder,
    Future<ApiResponse<AdminProduct>> Function(
      String id,
      AdminProductDraft draft,
    )?
    updateResponder,
    Future<ApiResponse<void>> Function(String id)? deleteResponder,
  }) : createResponder =
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
  }) => listResponder();

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

    expect(find.byKey(const Key('adminProductCard_created-001')), findsNothing);
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
}

const _category = AdminProductCategory(id: 'category-001', name: 'Mực khô');

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
