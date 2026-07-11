import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/admin_products/domain/admin_product.dart';
import 'package:marinelink/features/admin_products/domain/admin_product_repository.dart';
import 'package:marinelink/features/admin_products/presentation/cubit/admin_product_cubit.dart';

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
  final Future<String> Function(List<int> bytes, String fileName)
  uploadResponder;

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
    Future<String> Function(List<int> bytes, String fileName)? uploadResponder,
  }) : uploadResponder =
           uploadResponder ??
           ((_, fileName) async => 'https://cdn.test/$fileName'),
       createResponder =
           createResponder ??
           ((_) async =>
               const ApiResponse(success: false, message: 'Không tạo được')),
       updateResponder =
           updateResponder ??
           ((_, _) async => const ApiResponse(
             success: false,
             message: 'Không cập nhật được',
           )),
       deleteResponder =
           deleteResponder ??
           ((_) async =>
               const ApiResponse(success: false, message: 'Không xoá được'));

  @override
  Future<ApiResponse<List<AdminProduct>>> getProducts({
    String? query,
    AdminProductStatus? status,
    bool? featured,
  }) => listResponder();

  @override
  Future<ApiResponse<List<AdminProductCategory>>> getCategories() async =>
      const ApiResponse(success: true, message: 'OK', data: [_category]);

  @override
  Future<String> uploadProductImage({
    required List<int> bytes,
    required String fileName,
  }) => uploadResponder(bytes, fileName);

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

void main() {
  blocTest<AdminProductCubit, AdminProductState>(
    'emits [loading, success] when repository returns products',
    build: () => AdminProductCubit(
      repository: _FakeRepo(
        listResponder: () async =>
            const ApiResponse(success: true, message: 'OK', data: [_product]),
      ),
    ),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<AdminProductState>().having(
        (state) => state.status,
        'status',
        AdminProductStatusView.loading,
      ),
      isA<AdminProductState>()
          .having(
            (state) => state.status,
            'status',
            AdminProductStatusView.success,
          )
          .having((state) => state.products, 'products', const [_product]),
    ],
  );

  blocTest<AdminProductCubit, AdminProductState>(
    'emits [loading, empty] when repository returns empty list',
    build: () => AdminProductCubit(
      repository: _FakeRepo(
        listResponder: () async =>
            const ApiResponse(success: true, message: 'OK', data: []),
      ),
    ),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<AdminProductState>().having(
        (state) => state.status,
        'status',
        AdminProductStatusView.loading,
      ),
      isA<AdminProductState>().having(
        (state) => state.status,
        'status',
        AdminProductStatusView.empty,
      ),
    ],
  );

  blocTest<AdminProductCubit, AdminProductState>(
    'emits [loading, failure] when repository reports failure',
    build: () => AdminProductCubit(
      repository: _FakeRepo(
        listResponder: () async =>
            const ApiResponse(success: false, message: 'Server lỗi'),
      ),
    ),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<AdminProductState>().having(
        (state) => state.status,
        'status',
        AdminProductStatusView.loading,
      ),
      isA<AdminProductState>()
          .having(
            (state) => state.status,
            'status',
            AdminProductStatusView.failure,
          )
          .having((state) => state.errorMessage, 'errorMessage', 'Server lỗi'),
    ],
  );

  blocTest<AdminProductCubit, AdminProductState>(
    'emits [loading, failure] when repository throws',
    build: () => AdminProductCubit(
      repository: _FakeRepo(listResponder: () async => throw Exception('boom')),
    ),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<AdminProductState>().having(
        (state) => state.status,
        'status',
        AdminProductStatusView.loading,
      ),
      isA<AdminProductState>().having(
        (state) => state.status,
        'status',
        AdminProductStatusView.failure,
      ),
    ],
  );

  blocTest<AdminProductCubit, AdminProductState>(
    'createProduct prepends created product',
    seed: () => const AdminProductState(
      status: AdminProductStatusView.success,
      products: [_product],
    ),
    build: () => AdminProductCubit(
      repository: _FakeRepo(
        listResponder: () async =>
            const ApiResponse(success: true, message: 'OK', data: [_product]),
        createResponder: (_) async =>
            const ApiResponse(success: true, message: 'OK', data: _created),
      ),
    ),
    act: (cubit) => cubit.createProduct(_draft),
    expect: () => [
      isA<AdminProductState>().having(
        (state) => state.actionStatus,
        'actionStatus',
        AdminProductActionStatus.saving,
      ),
      isA<AdminProductState>()
          .having(
            (state) => state.actionStatus,
            'actionStatus',
            AdminProductActionStatus.success,
          )
          .having((state) => state.products.first, 'first', _created),
    ],
  );

  blocTest<AdminProductCubit, AdminProductState>(
    'updateProduct replaces product',
    seed: () => const AdminProductState(
      status: AdminProductStatusView.success,
      products: [_product],
    ),
    build: () => AdminProductCubit(
      repository: _FakeRepo(
        listResponder: () async =>
            const ApiResponse(success: true, message: 'OK', data: [_product]),
        updateResponder: (_, _) async =>
            const ApiResponse(success: true, message: 'OK', data: _updated),
      ),
    ),
    act: (cubit) => cubit.updateProduct(_product.id, _draft),
    expect: () => [
      isA<AdminProductState>().having(
        (state) => state.editingProductId,
        'editingProductId',
        _product.id,
      ),
      isA<AdminProductState>()
          .having(
            (state) => state.actionStatus,
            'actionStatus',
            AdminProductActionStatus.success,
          )
          .having((state) => state.products.single.name, 'name', _updated.name)
          .having(
            (state) => state.editingProductId,
            'editingProductId',
            isNull,
          ),
    ],
  );

  blocTest<AdminProductCubit, AdminProductState>(
    'deleteProduct removes product',
    seed: () => const AdminProductState(
      status: AdminProductStatusView.success,
      products: [_product],
    ),
    build: () => AdminProductCubit(
      repository: _FakeRepo(
        listResponder: () async =>
            const ApiResponse(success: true, message: 'OK', data: [_product]),
        deleteResponder: (_) async =>
            const ApiResponse(success: true, message: 'OK'),
      ),
    ),
    act: (cubit) => cubit.deleteProduct(_product.id),
    expect: () => [
      isA<AdminProductState>().having(
        (state) => state.deletingProductId,
        'deletingProductId',
        _product.id,
      ),
      isA<AdminProductState>()
          .having(
            (state) => state.status,
            'status',
            AdminProductStatusView.empty,
          )
          .having((state) => state.products, 'products', isEmpty)
          .having(
            (state) => state.deletingProductId,
            'deletingProductId',
            isNull,
          ),
    ],
  );

  test('load populates categories from repository', () async {
    final cubit = AdminProductCubit(
      repository: _FakeRepo(
        listResponder: () async =>
            const ApiResponse(success: true, message: 'OK', data: [_product]),
      ),
    );

    await cubit.load();

    expect(cubit.state.categories, const [_category]);
  });

  test('uploadProductImage returns url from repository', () async {
    final cubit = AdminProductCubit(
      repository: _FakeRepo(
        listResponder: () async =>
            const ApiResponse(success: true, message: 'OK', data: [_product]),
      ),
    );

    final url = await cubit.uploadProductImage(const [1, 2, 3], 'muc.png');

    expect(url, 'https://cdn.test/muc.png');
  });

  test('uploadProductImage returns null when repository throws', () async {
    final cubit = AdminProductCubit(
      repository: _FakeRepo(
        listResponder: () async =>
            const ApiResponse(success: true, message: 'OK', data: [_product]),
        uploadResponder: (_, _) async => throw Exception('boom'),
      ),
    );

    final url = await cubit.uploadProductImage(const [1, 2, 3], 'muc.png');

    expect(url, isNull);
  });
}

const _category = AdminProductCategory(id: 'category-001', name: 'Mực khô');

const _product = AdminProduct(
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

const _created = AdminProduct(
  id: 'product-002',
  name: 'Tôm khô mới',
  slug: 'tom-kho-moi',
  basePrice: 680000,
  unit: 'kg',
  minOrderQuantity: 1,
  stockQuantity: 40,
  status: AdminProductStatus.active,
  category: _category,
);

const _updated = AdminProduct(
  id: 'product-001',
  name: 'Mực khô cập nhật',
  slug: 'muc-kho-cap-nhat',
  basePrice: 450000,
  unit: 'kg',
  minOrderQuantity: 2,
  stockQuantity: 80,
  status: AdminProductStatus.active,
  category: _category,
);

const _draft = AdminProductDraft(
  categoryId: 'category-001',
  name: 'Mực khô cập nhật',
  slug: 'muc-kho-cap-nhat',
  basePrice: 450000,
  unit: 'kg',
  minOrderQuantity: 2,
  stockQuantity: 80,
  status: AdminProductStatus.active,
  isFeatured: false,
);
