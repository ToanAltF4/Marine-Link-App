import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/role_back_to_dashboard_scope.dart';
import '../../../../shared/widgets/role_bottom_nav.dart';
import '../../domain/admin_product.dart';
import '../cubit/admin_product_cubit.dart';
import '../widgets/admin_product_card.dart';
import '../widgets/admin_product_filters.dart';
import '../widgets/admin_product_search.dart';
import '../widgets/admin_products_header.dart';
import '../widgets/admin_products_states.dart';

class AdminProductManagementScreen extends StatelessWidget {
  /// When opened from the staff dashboard, use staff chrome (staff bottom nav,
  /// back to the staff dashboard) instead of the admin-only navigation, which
  /// would otherwise bounce a staff user into the admin-guarded area.
  final bool staffMode;

  const AdminProductManagementScreen({super.key, this.staffMode = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminProductCubit>(
      create: (_) => sl<AdminProductCubit>()..load(),
      child: _AdminProductView(staffMode: staffMode),
    );
  }
}

class _AdminProductView extends StatelessWidget {
  final bool staffMode;

  const _AdminProductView({required this.staffMode});

  @override
  Widget build(BuildContext context) {
    return RoleBackToDashboardScope(
      dashboardLocation: staffMode ? AppRoutes.staffDashboard : AppRoutes.adminDashboard,
      child: Scaffold(
        key: const Key('adminProductsScreen'),
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Quản lý sản phẩm'),
          actions: [
            IconButton(
              key: const Key('adminProductAddButton'),
              tooltip: 'Thêm sản phẩm',
              icon: const Icon(Icons.add_box_outlined),
              onPressed: () => _showProductForm(context),
            ),
          ],
        ),
        bottomNavigationBar: staffMode
            ? const StaffBottomNav(currentTab: StaffBottomNavTab.work)
            : const AdminBottomNav(currentTab: AdminBottomNavTab.products),
        body: BlocBuilder<AdminProductCubit, AdminProductState>(
          builder: (context, state) {
            switch (state.status) {
              case AdminProductStatusView.initial:
              case AdminProductStatusView.loading:
                return const Center(
                  key: Key('adminProductsLoading'),
                  child: CircularProgressIndicator(),
                );
              case AdminProductStatusView.failure:
                return AdminProductsError(
                  message:
                      state.errorMessage ??
                      'Không tải được danh sách sản phẩm.',
                  onRetry: () => context.read<AdminProductCubit>().load(),
                );
              case AdminProductStatusView.empty:
                return const AdminProductsEmpty();
              case AdminProductStatusView.success:
                return _AdminProductsContent(state: state);
            }
          },
        ),
      ),
    );
  }
}

class _AdminProductsContent extends StatelessWidget {
  final AdminProductState state;

  const _AdminProductsContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final visibleProducts = state.visibleProducts;
    return ListView(
      key: const Key('adminProductsList'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        AdminProductsHeader(products: state.products),
        const SizedBox(height: 14),
        AdminProductSearch(initialQuery: state.query),
        const SizedBox(height: 12),
        AdminProductFilters(state: state),
        const SizedBox(height: 14),
        if (visibleProducts.isEmpty)
          const FilteredEmptyState()
        else
          ...visibleProducts.map(
            (product) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AdminProductCard(
                product: product,
                editing: state.editingProductId == product.id,
                deleting: state.deletingProductId == product.id,
                onEdit: () => _showProductForm(context, product: product),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProductFormSheet extends StatefulWidget {
  final AdminProduct? product;
  final List<AdminProductCategory> categories;

  const _ProductFormSheet({this.product, required this.categories});

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _categoryIdController;
  late final TextEditingController _nameController;
  late final TextEditingController _slugController;
  late final TextEditingController _shortDescriptionController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _originController;
  late final TextEditingController _basePriceController;
  late final TextEditingController _unitController;
  late final TextEditingController _minOrderController;
  late final TextEditingController _stockController;
  late final TextEditingController _tierMinController;
  late final TextEditingController _tierMaxController;
  late final TextEditingController _tierPriceController;
  late AdminProductStatus _status;
  late bool _featured;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    final firstTier = product?.priceTiers.isNotEmpty == true
        ? product!.priceTiers.first
        : null;
    _categoryIdController = TextEditingController(
      text:
          product?.categoryId ??
          (widget.categories.isNotEmpty ? widget.categories.first.id : ''),
    );
    _nameController = TextEditingController(text: product?.name ?? '');
    _slugController = TextEditingController(text: product?.slug ?? '');
    _shortDescriptionController = TextEditingController(
      text: product?.shortDescription ?? '',
    );
    _descriptionController = TextEditingController(
      text: product?.description ?? '',
    );
    _originController = TextEditingController(text: product?.origin ?? '');
    _basePriceController = TextEditingController(
      text: product == null ? '' : product.basePrice.toStringAsFixed(0),
    );
    _unitController = TextEditingController(text: product?.unit ?? 'kg');
    _minOrderController = TextEditingController(
      text: product?.minOrderQuantity.toString() ?? '1',
    );
    _stockController = TextEditingController(
      text: product?.stockQuantity.toString() ?? '0',
    );
    _tierMinController = TextEditingController(
      text: firstTier?.minQuantity.toString() ?? '',
    );
    _tierMaxController = TextEditingController(
      text: firstTier?.maxQuantity?.toString() ?? '',
    );
    _tierPriceController = TextEditingController(
      text: firstTier == null ? '' : firstTier.unitPrice.toStringAsFixed(0),
    );
    _status = product?.status ?? AdminProductStatus.active;
    _featured = product?.isFeatured ?? false;
  }

  @override
  void dispose() {
    _categoryIdController.dispose();
    _nameController.dispose();
    _slugController.dispose();
    _shortDescriptionController.dispose();
    _descriptionController.dispose();
    _originController.dispose();
    _basePriceController.dispose();
    _unitController.dispose();
    _minOrderController.dispose();
    _stockController.dispose();
    _tierMinController.dispose();
    _tierMaxController.dispose();
    _tierPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.product == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm';
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            key: const Key('adminProductFormSheet'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                _TextField(
                  key: const Key('adminProductNameField'),
                  controller: _nameController,
                  label: 'Tên sản phẩm',
                  validator: _required,
                ),
                _TextField(
                  key: const Key('adminProductSlugField'),
                  controller: _slugController,
                  label: 'Slug',
                  validator: _required,
                ),
                _TextField(
                  key: const Key('adminProductCategoryIdField'),
                  controller: _categoryIdController,
                  label: 'Category ID',
                  validator: _required,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _TextField(
                        key: const Key('adminProductBasePriceField'),
                        controller: _basePriceController,
                        label: 'Giá gốc',
                        keyboardType: TextInputType.number,
                        validator: _positiveNumber,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TextField(
                        key: const Key('adminProductUnitField'),
                        controller: _unitController,
                        label: 'Đơn vị',
                        validator: _required,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _TextField(
                        key: const Key('adminProductMinOrderField'),
                        controller: _minOrderController,
                        label: 'Tối thiểu',
                        keyboardType: TextInputType.number,
                        validator: _positiveInt,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TextField(
                        key: const Key('adminProductStockField'),
                        controller: _stockController,
                        label: 'Tồn kho',
                        keyboardType: TextInputType.number,
                        validator: _nonNegativeInt,
                      ),
                    ),
                  ],
                ),
                _TextField(
                  key: const Key('adminProductOriginField'),
                  controller: _originController,
                  label: 'Xuất xứ',
                ),
                _TextField(
                  key: const Key('adminProductShortDescriptionField'),
                  controller: _shortDescriptionController,
                  label: 'Mô tả tóm tắt',
                  maxLines: 2,
                ),
                _TextField(
                  key: const Key('adminProductDescriptionField'),
                  controller: _descriptionController,
                  label: 'Mô tả',
                  maxLines: 2,
                ),
                DropdownButtonFormField<AdminProductStatus>(
                  key: const Key('adminProductStatusField'),
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Trạng thái'),
                  items: AdminProductStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(_statusLabel(status)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  key: const Key('adminProductFeaturedField'),
                  value: _featured,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sản phẩm nổi bật'),
                  onChanged: (value) => setState(() => _featured = value),
                ),
                const SizedBox(height: 8),
                Text(
                  'Giá sỉ đầu tiên',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _TextField(
                        key: const Key('adminProductTierMinField'),
                        controller: _tierMinController,
                        label: 'Từ',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TextField(
                        key: const Key('adminProductTierMaxField'),
                        controller: _tierMaxController,
                        label: 'Đến',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TextField(
                        key: const Key('adminProductTierPriceField'),
                        controller: _tierPriceController,
                        label: 'Đơn giá',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('adminProductSaveButton'),
                    onPressed: _submit,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Lưu sản phẩm'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final draft = AdminProductDraft(
      categoryId: _categoryIdController.text.trim(),
      name: _nameController.text.trim(),
      slug: _slugController.text.trim(),
      shortDescription: _trimToNull(_shortDescriptionController.text),
      description: _trimToNull(_descriptionController.text),
      origin: _trimToNull(_originController.text),
      basePrice: _toDouble(_basePriceController.text),
      unit: _unitController.text.trim(),
      minOrderQuantity: _toInt(_minOrderController.text, fallback: 1),
      stockQuantity: _toInt(_stockController.text),
      status: _status,
      isFeatured: _featured,
      priceTiers: _tierFromInput(),
    );
    final cubit = context.read<AdminProductCubit>();
    final product = widget.product;
    if (product == null) {
      await cubit.createProduct(draft);
    } else {
      await cubit.updateProduct(product.id, draft);
    }
    if (!mounted) return;
    final actionStatus = cubit.state.actionStatus;
    if (actionStatus == AdminProductActionStatus.success) {
      Navigator.of(context).pop();
    }
  }

  List<AdminPriceTier> _tierFromInput() {
    if (_tierMinController.text.trim().isEmpty ||
        _tierPriceController.text.trim().isEmpty) {
      return const [];
    }
    return [
      AdminPriceTier(
        id: _firstTierId(widget.product),
        minQuantity: _toInt(_tierMinController.text, fallback: 1),
        maxQuantity: _tierMaxController.text.trim().isEmpty
            ? null
            : _toInt(_tierMaxController.text),
        unitPrice: _toDouble(_tierPriceController.text),
      ),
    ];
  }
}

String _firstTierId(AdminProduct? product) {
  final tiers = product?.priceTiers ?? const <AdminPriceTier>[];
  return tiers.isEmpty ? '' : tiers.first.id;
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final int maxLines;

  const _TextField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

void _showProductForm(BuildContext context, {AdminProduct? product}) {
  final cubit = context.read<AdminProductCubit>();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _ProductFormSheet(
        product: product,
        categories: cubit.state.categories,
      ),
    ),
  );
}

String? _required(String? value) {
  if (value == null || value.trim().isEmpty) return 'Không được để trống';
  return null;
}

String? _positiveNumber(String? value) {
  final parsed = _toDouble(value ?? '');
  if (parsed <= 0) return 'Phải lớn hơn 0';
  return null;
}

String? _positiveInt(String? value) {
  final parsed = _toInt(value ?? '');
  if (parsed <= 0) return 'Phải lớn hơn 0';
  return null;
}

String? _nonNegativeInt(String? value) {
  final parsed = _toInt(value ?? '');
  if (parsed < 0) return 'Không được âm';
  return null;
}

String? _trimToNull(String value) {
  final text = value.trim();
  return text.isEmpty ? null : text;
}

double _toDouble(String value) {
  return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
}

int _toInt(String value, {int fallback = 0}) {
  return int.tryParse(value.trim()) ?? fallback;
}

String _statusLabel(AdminProductStatus status) {
  return switch (status) {
    AdminProductStatus.active => 'Đang bán',
    AdminProductStatus.outOfStock => 'Hết hàng',
    AdminProductStatus.disabled => 'Tạm ẩn',
  };
}
