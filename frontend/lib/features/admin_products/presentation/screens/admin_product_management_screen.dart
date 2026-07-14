import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marinelink/core/constants/app_strings.dart';

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
      dashboardLocation: staffMode
          ? AppRoutes.staffDashboard
          : AppRoutes.adminDashboard,
      child: Scaffold(
        key: const Key('adminProductsScreen'),
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(AppStrings.adminProductsTitle),
          actions: [
            IconButton(
              key: const Key('adminProductAddButton'),
              tooltip: AppStrings.addProduct,
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
                      state.errorMessage ?? AppStrings.adminProductsLoadFailed,
                  onRetry: () => context.read<AdminProductCubit>().load(),
                );
              case AdminProductStatusView.empty:
                return const AdminProductsEmpty();
              case AdminProductStatusView.success:
                return RefreshIndicator(
                  onRefresh: () => context.read<AdminProductCubit>().load(),
                  child: _AdminProductsContent(state: state),
                );
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
      physics: const AlwaysScrollableScrollPhysics(),
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

/// Ô nhập của một mức giá sỉ trong form (giữ lại id để backend cập nhật đúng dòng).
class _TierInput {
  /// Public id của mức giá đã tồn tại; rỗng nghĩa là mức giá mới.
  final String id;
  final TextEditingController minController;
  final TextEditingController maxController;
  final TextEditingController priceController;

  _TierInput({this.id = '', String? min, String? max, String? price})
    : minController = TextEditingController(text: min ?? ''),
      maxController = TextEditingController(text: max ?? ''),
      priceController = TextEditingController(text: price ?? '');

  factory _TierInput.fromTier(AdminPriceTier tier) {
    return _TierInput(
      id: tier.id,
      min: tier.minQuantity.toString(),
      max: tier.maxQuantity?.toString() ?? '',
      price: tier.unitPrice.toStringAsFixed(0),
    );
  }

  /// Dòng chưa nhập gì -> bỏ qua khi lưu (không coi là lỗi).
  bool get isBlank =>
      minController.text.trim().isEmpty &&
      maxController.text.trim().isEmpty &&
      priceController.text.trim().isEmpty;

  AdminPriceTier toTier() {
    return AdminPriceTier(
      id: id,
      minQuantity: _toInt(minController.text, fallback: 1),
      maxQuantity: maxController.text.trim().isEmpty
          ? null
          : _toInt(maxController.text),
      unitPrice: _toDouble(priceController.text),
    );
  }

  void dispose() {
    minController.dispose();
    maxController.dispose();
    priceController.dispose();
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
  final _imagePicker = ImagePicker();
  String? _selectedCategoryId;
  bool _uploadingImage = false;
  bool _submitting = false;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _nameController;
  late final TextEditingController _slugController;
  late final TextEditingController _shortDescriptionController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _originController;
  late final TextEditingController _basePriceController;
  late final TextEditingController _unitController;
  late final TextEditingController _minOrderController;
  late final TextEditingController _stockController;
  late final List<_TierInput> _tiers;
  late AdminProductStatus _status;
  late bool _featured;

  @override
  void initState() {
    super.initState();
    // `product` là CHI TIẾT đầy đủ (đã fetch trước khi mở form), nên mô tả và
    // toàn bộ các mức giá sỉ đều có sẵn để prefill.
    final product = widget.product;
    // Preselect the product's current category on edit; only if it exists in
    // the fetched list (otherwise the dropdown would assert). Null means "let
    // the backend choose a default / keep the existing category".
    final currentCategoryId = product?.categoryId;
    _selectedCategoryId =
        (currentCategoryId != null &&
            widget.categories.any((c) => c.id == currentCategoryId))
        ? currentCategoryId
        : null;
    _imageUrlController = TextEditingController(text: product?.imageUrl ?? '');
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
    final existingTiers = product?.priceTiers ?? const <AdminPriceTier>[];
    _tiers = existingTiers.isEmpty
        ? [_TierInput()]
        : existingTiers.map(_TierInput.fromTier).toList();
    _status = product?.status ?? AdminProductStatus.active;
    _featured = product?.isFeatured ?? false;
  }

  @override
  void dispose() {
    _imageUrlController.dispose();
    _nameController.dispose();
    _slugController.dispose();
    _shortDescriptionController.dispose();
    _descriptionController.dispose();
    _originController.dispose();
    _basePriceController.dispose();
    _unitController.dispose();
    _minOrderController.dispose();
    _stockController.dispose();
    for (final tier in _tiers) {
      tier.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.product == null
        ? AppStrings.addProduct
        : AppStrings.editProduct;
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
                  label: AppStrings.productNameLabel,
                  validator: _required,
                ),
                _TextField(
                  key: const Key('adminProductSlugField'),
                  controller: _slugController,
                  label: 'Slug',
                  validator: _required,
                ),
                DropdownButtonFormField<String?>(
                  key: const Key('adminProductCategoryDropdown'),
                  initialValue: _selectedCategoryId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: AppStrings.categoryLabel,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text(AppStrings.noCategoryOption),
                    ),
                    ...widget.categories.map(
                      (category) => DropdownMenuItem<String?>(
                        value: category.id,
                        child: Text(category.name),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedCategoryId = value),
                ),
                const SizedBox(height: 10),
                _ImagePickerField(
                  imageUrlController: _imageUrlController,
                  uploading: _uploadingImage,
                  onPickImage: _pickAndUploadImage,
                  onUrlChanged: () => setState(() {}),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _TextField(
                        key: const Key('adminProductBasePriceField'),
                        controller: _basePriceController,
                        label: AppStrings.basePriceLabel,
                        keyboardType: TextInputType.number,
                        validator: _positiveNumber,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TextField(
                        key: const Key('adminProductUnitField'),
                        controller: _unitController,
                        label: AppStrings.unitLabel,
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
                        label: AppStrings.minimumLabel,
                        keyboardType: TextInputType.number,
                        validator: _positiveInt,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TextField(
                        key: const Key('adminProductStockField'),
                        controller: _stockController,
                        label: AppStrings.stockLabel,
                        keyboardType: TextInputType.number,
                        validator: _nonNegativeInt,
                      ),
                    ),
                  ],
                ),
                _TextField(
                  key: const Key('adminProductOriginField'),
                  controller: _originController,
                  label: AppStrings.originLabel,
                ),
                _TextField(
                  key: const Key('adminProductShortDescriptionField'),
                  controller: _shortDescriptionController,
                  label: AppStrings.shortDescriptionLabel,
                  maxLines: 2,
                ),
                _TextField(
                  key: const Key('adminProductDescriptionField'),
                  controller: _descriptionController,
                  label: AppStrings.descriptionLabel,
                  maxLines: 2,
                ),
                DropdownButtonFormField<AdminProductStatus>(
                  key: const Key('adminProductStatusField'),
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: AppStrings.productStatusLabel,
                  ),
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
                  title: const Text(AppStrings.featuredProduct),
                  onChanged: (value) => setState(() => _featured = value),
                ),
                const SizedBox(height: 8),
                ..._buildTierSection(context),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('adminProductSaveButton'),
                    // Vô hiệu hoá khi đang gửi để tránh bấm lưu hai lần.
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            key: Key('adminProductSaveProgress'),
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text(AppStrings.saveProduct),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTierSection(BuildContext context) {
    return [
      Row(
        children: [
          Expanded(
            child: Text(
              AppStrings.wholesalePriceTiers,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          TextButton.icon(
            key: const Key('adminProductAddTierButton'),
            onPressed: _submitting ? null : _addTier,
            icon: const Icon(Icons.add),
            label: const Text(AppStrings.addWholesaleTier),
          ),
        ],
      ),
      if (_tiers.isEmpty)
        const Padding(
          key: Key('adminProductNoTiers'),
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(AppStrings.noWholesaleTier),
        ),
      for (var index = 0; index < _tiers.length; index++)
        _TierRow(
          key: Key('adminProductTierRow_$index'),
          index: index,
          tier: _tiers[index],
          onRemove: _submitting ? null : () => _removeTier(index),
          validateQuantity: (value) => _tierMinValidator(index, value),
          validatePrice: (value) => _tierPriceValidator(index, value),
        ),
    ];
  }

  void _addTier() {
    setState(() => _tiers.add(_TierInput()));
  }

  void _removeTier(int index) {
    setState(() {
      final removed = _tiers.removeAt(index);
      removed.dispose();
    });
  }

  /// Dòng bỏ trống hoàn toàn được bỏ qua; dòng nhập dở phải hợp lệ.
  String? _tierMinValidator(int index, String? value) {
    if (_tiers[index].isBlank) return null;
    return _positiveInt(value);
  }

  String? _tierPriceValidator(int index, String? value) {
    if (_tiers[index].isBlank) return null;
    return _positiveNumber(value);
  }

  Future<void> _pickAndUploadImage() async {
    final cubit = context.read<AdminProductCubit>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      setState(() => _uploadingImage = true);
      final bytes = await picked.readAsBytes();
      final url = await cubit.uploadProductImage(bytes, picked.name);
      if (!mounted) return;
      if (url == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text(AppStrings.imageUploadFailed)),
        );
        return;
      }
      setState(() => _imageUrlController.text = url);
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.imageUploadFailed)),
      );
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final messenger = ScaffoldMessenger.of(context);
    if (!_formKey.currentState!.validate()) {
      // Trước đây form im lặng khi validate hỏng -> người dùng tưởng nút hỏng.
      messenger.showSnackBar(
        const SnackBar(
          key: Key('adminProductErrorSnackBar'),
          content: Text(AppStrings.adminProductFormInvalid),
        ),
      );
      return;
    }

    final cubit = context.read<AdminProductCubit>();
    final navigator = Navigator.of(context);
    final product = widget.product;
    final draft = AdminProductDraft(
      categoryId: _selectedCategoryId ?? '',
      name: _nameController.text.trim(),
      slug: _slugController.text.trim(),
      // Trường tuỳ chọn để trống -> gửi null (không gửi chuỗi rỗng) để backend
      // lưu null thay vì chặn cập nhật.
      shortDescription: _trimToNull(_shortDescriptionController.text),
      description: _trimToNull(_descriptionController.text),
      origin: _trimToNull(_originController.text),
      imageUrl: _trimToNull(_imageUrlController.text),
      basePrice: _toDouble(_basePriceController.text),
      unit: _unitController.text.trim(),
      minOrderQuantity: _toInt(_minOrderController.text, fallback: 1),
      stockQuantity: _toInt(_stockController.text),
      status: _status,
      isFeatured: _featured,
      priceTiers: _tiersFromInput(),
    );

    setState(() => _submitting = true);
    if (product == null) {
      await cubit.createProduct(draft);
    } else {
      await cubit.updateProduct(product.id, draft);
    }
    if (!mounted) return;
    setState(() => _submitting = false);

    final actionStatus = cubit.state.actionStatus;
    if (actionStatus == AdminProductActionStatus.success) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          key: Key('adminProductSuccessSnackBar'),
          content: Text(AppStrings.adminProductSaveSuccess),
        ),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        key: const Key('adminProductErrorSnackBar'),
        content: Text(
          cubit.state.errorMessage ??
              (product == null
                  ? AppStrings.adminProductCreateFailed
                  : AppStrings.adminProductUpdateFailed),
        ),
      ),
    );
  }

  /// Gửi TẤT CẢ các mức giá sỉ đã nhập (kèm id của mức giá cũ), bỏ qua dòng trống.
  List<AdminPriceTier> _tiersFromInput() {
    return [
      for (final tier in _tiers)
        if (!tier.isBlank) tier.toTier(),
    ];
  }
}

/// Một dòng nhập mức giá sỉ: Từ - Đến - Đơn giá, kèm nút xoá dòng.
class _TierRow extends StatelessWidget {
  final int index;
  final _TierInput tier;
  final VoidCallback? onRemove;
  final FormFieldValidator<String> validateQuantity;
  final FormFieldValidator<String> validatePrice;

  const _TierRow({
    super.key,
    required this.index,
    required this.tier,
    required this.onRemove,
    required this.validateQuantity,
    required this.validatePrice,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.wholesaleTierTitle(index + 1),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _TextField(
                key: Key('adminProductTierMinField_$index'),
                controller: tier.minController,
                label: AppStrings.fromLabel,
                keyboardType: TextInputType.number,
                validator: validateQuantity,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TextField(
                key: Key('adminProductTierMaxField_$index'),
                controller: tier.maxController,
                label: AppStrings.toLabel,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TextField(
                key: Key('adminProductTierPriceField_$index'),
                controller: tier.priceController,
                label: AppStrings.unitPriceLabel,
                keyboardType: TextInputType.number,
                validator: validatePrice,
              ),
            ),
            IconButton(
              key: Key('adminProductRemoveTierButton_$index'),
              tooltip: AppStrings.removeWholesaleTier,
              color: AppColors.error,
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline),
            ),
          ],
        ),
      ],
    );
  }
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

class _ImagePickerField extends StatelessWidget {
  final TextEditingController imageUrlController;
  final bool uploading;
  final Future<void> Function() onPickImage;
  final VoidCallback onUrlChanged;

  const _ImagePickerField({
    required this.imageUrlController,
    required this.uploading,
    required this.onPickImage,
    required this.onUrlChanged,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = imageUrlController.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.productImageLabel,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              key: const Key('adminProductPickImageButton'),
              onPressed: uploading ? null : onPickImage,
              icon: const Icon(Icons.image_outlined),
              label: const Text(AppStrings.pickImageFromDevice),
            ),
            const SizedBox(width: 12),
            if (uploading)
              const SizedBox(
                key: Key('adminProductImageUploading'),
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          key: const Key('adminProductImageUrlField'),
          controller: imageUrlController,
          decoration: const InputDecoration(
            labelText: AppStrings.productImageUrlLabel,
          ),
          onChanged: (_) => onUrlChanged(),
        ),
        if (imageUrl.isNotEmpty) ...[
          const SizedBox(height: 10),
          ClipRRect(
            key: const Key('adminProductImagePreview'),
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 120,
                alignment: Alignment.center,
                color: AppColors.background,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Mở form thêm/sửa sản phẩm.
///
/// Khi sửa, PHẢI tải chi tiết đầy đủ trước: item trong danh sách không có
/// `description` và `priceTiers`, dựng form từ nó rồi lưu sẽ xoá sạch cả hai.
Future<void> _showProductForm(
  BuildContext context, {
  AdminProduct? product,
}) async {
  final cubit = context.read<AdminProductCubit>();
  final messenger = ScaffoldMessenger.of(context);

  AdminProduct? formProduct;
  if (product != null) {
    // Trạng thái loading hiển thị ngay trên nút Sửa của thẻ sản phẩm.
    formProduct = await cubit.loadProductDetail(product.id);
    if (formProduct == null) {
      messenger.showSnackBar(
        SnackBar(
          key: const Key('adminProductErrorSnackBar'),
          content: Text(
            cubit.state.errorMessage ?? AppStrings.adminProductDetailLoadFailed,
          ),
        ),
      );
      return;
    }
  }
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _ProductFormSheet(
        product: formProduct,
        categories: cubit.state.categories,
      ),
    ),
  );
}

String? _required(String? value) {
  if (value == null || value.trim().isEmpty) return AppStrings.notEmpty;
  return null;
}

String? _positiveNumber(String? value) {
  final parsed = _toDouble(value ?? '');
  if (parsed <= 0) return AppStrings.mustBeGreaterThanZero;
  return null;
}

String? _positiveInt(String? value) {
  final parsed = _toInt(value ?? '');
  if (parsed <= 0) return AppStrings.mustBeGreaterThanZero;
  return null;
}

String? _nonNegativeInt(String? value) {
  final parsed = _toInt(value ?? '');
  if (parsed < 0) return AppStrings.mustNotBeNegative;
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
    AdminProductStatus.active => AppStrings.productActive,
    AdminProductStatus.outOfStock => AppStrings.outOfStock,
    AdminProductStatus.disabled => AppStrings.productDisabled,
  };
}
