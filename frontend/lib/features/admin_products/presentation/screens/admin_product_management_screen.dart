import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/widgets/app_back_exit_scope.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/role_bottom_nav.dart';
import '../../domain/admin_product.dart';
import '../cubit/admin_product_cubit.dart';

class AdminProductManagementScreen extends StatelessWidget {
  const AdminProductManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminProductCubit>(
      create: (_) => sl<AdminProductCubit>()..load(),
      child: const _AdminProductView(),
    );
  }
}

class _AdminProductView extends StatelessWidget {
  const _AdminProductView();

  @override
  Widget build(BuildContext context) {
    return AppBackExitScope(
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
        bottomNavigationBar: const AdminBottomNav(
          currentTab: AdminBottomNavTab.products,
        ),
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
                return _AdminProductsError(
                  message:
                      state.errorMessage ??
                      'Không tải được danh sách sản phẩm.',
                  onRetry: () => context.read<AdminProductCubit>().load(),
                );
              case AdminProductStatusView.empty:
                return const _AdminProductsEmpty();
              case AdminProductStatusView.success:
                return _AdminProductsContent(state: state);
            }
          },
        ),
      ),
    );
  }
}

class _AdminProductsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _AdminProductsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('adminProductsError'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: AppColors.error,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('adminProductsRetryButton'),
              onPressed: onRetry,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminProductsEmpty extends StatelessWidget {
  const _AdminProductsEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: Key('adminProductsEmpty'),
      child: AppEmptyState(
        icon: Icons.inventory_2_outlined,
        message: 'Chưa có sản phẩm. Sản phẩm mới sẽ hiển thị sau khi được tạo.',
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
        _AdminProductsHeader(products: state.products),
        const SizedBox(height: 14),
        _AdminProductSearch(initialQuery: state.query),
        const SizedBox(height: 12),
        _AdminProductFilters(state: state),
        const SizedBox(height: 14),
        if (visibleProducts.isEmpty)
          const _FilteredEmptyState()
        else
          ...visibleProducts.map(
            (product) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AdminProductCard(
                product: product,
                editing: state.editingProductId == product.id,
                deleting: state.deletingProductId == product.id,
              ),
            ),
          ),
      ],
    );
  }
}

class _AdminProductsHeader extends StatelessWidget {
  final List<AdminProduct> products;

  const _AdminProductsHeader({required this.products});

  @override
  Widget build(BuildContext context) {
    final activeCount = products
        .where((product) => product.status == AdminProductStatus.active)
        .length;
    final lowStockCount = products
        .where((product) => product.stockQuantity <= product.minOrderQuantity)
        .length;
    return DecoratedBox(
      key: const Key('adminProductsSummaryCard'),
      decoration: _cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const _IconTile(
              icon: Icons.inventory_2_outlined,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceSky,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kho sản phẩm',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${products.length} sản phẩm - $activeCount đang bán - $lowStockCount cần kiểm kho',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminProductSearch extends StatefulWidget {
  final String initialQuery;

  const _AdminProductSearch({required this.initialQuery});

  @override
  State<_AdminProductSearch> createState() => _AdminProductSearchState();
}

class _AdminProductSearchState extends State<_AdminProductSearch> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('adminProductSearchField'),
      controller: _controller,
      textInputAction: TextInputAction.search,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        hintText: 'Tìm theo tên, slug, xuất xứ',
      ),
      onChanged: context.read<AdminProductCubit>().setQuery,
    );
  }
}

class _AdminProductFilters extends StatelessWidget {
  final AdminProductState state;

  const _AdminProductFilters({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('adminProductsFilters'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterRow(
          children: [
            _StatusFilterChip(
              key: const Key('adminProductStatusFilterAll'),
              label: 'Tất cả',
              selected: state.selectedStatus == null,
              status: null,
            ),
            _StatusFilterChip(
              key: const Key('adminProductStatusFilterActive'),
              label: 'Đang bán',
              selected: state.selectedStatus == AdminProductStatus.active,
              status: AdminProductStatus.active,
            ),
            _StatusFilterChip(
              key: const Key('adminProductStatusFilterOutOfStock'),
              label: 'Hết hàng',
              selected: state.selectedStatus == AdminProductStatus.outOfStock,
              status: AdminProductStatus.outOfStock,
            ),
            _StatusFilterChip(
              key: const Key('adminProductStatusFilterDisabled'),
              label: 'Tạm ẩn',
              selected: state.selectedStatus == AdminProductStatus.disabled,
              status: AdminProductStatus.disabled,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _FilterRow(
          children: [
            _FeaturedFilterChip(
              key: const Key('adminProductFeaturedFilterAll'),
              label: 'Tất cả nổi bật',
              selected: state.selectedFeatured == null,
              featured: null,
            ),
            _FeaturedFilterChip(
              key: const Key('adminProductFeaturedFilterYes'),
              label: 'Nổi bật',
              selected: state.selectedFeatured == true,
              featured: true,
            ),
            _FeaturedFilterChip(
              key: const Key('adminProductFeaturedFilterNo'),
              label: 'Không nổi bật',
              selected: state.selectedFeatured == false,
              featured: false,
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  final List<Widget> children;

  const _FilterRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final child in children)
            Padding(padding: const EdgeInsets.only(right: 8), child: child),
        ],
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final AdminProductStatus? status;

  const _StatusFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) =>
          context.read<AdminProductCubit>().setStatusFilter(status),
    );
  }
}

class _FeaturedFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool? featured;

  const _FeaturedFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.featured,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) =>
          context.read<AdminProductCubit>().setFeaturedFilter(featured),
    );
  }
}

class _FilteredEmptyState extends StatelessWidget {
  const _FilteredEmptyState();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('adminProductsFilteredEmpty'),
      decoration: _cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          'Không có sản phẩm phù hợp với bộ lọc.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _AdminProductCard extends StatelessWidget {
  final AdminProduct product;
  final bool editing;
  final bool deleting;

  const _AdminProductCard({
    required this.product,
    required this.editing,
    required this.deleting,
  });

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyle(product.status);
    return DecoratedBox(
      key: Key('adminProductCard_${product.id}'),
      decoration: _cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProductThumb(product: product),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.category?.name ?? product.slug,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                _StatusPill(
                  label: statusStyle.label,
                  textColor: statusStyle.textColor,
                  backgroundColor: statusStyle.backgroundColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetaLine(
                    icon: Icons.sell_outlined,
                    text:
                        '${MoneyFormatter.format(product.basePrice)}/${product.unit}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetaLine(
                    icon: Icons.inventory_outlined,
                    text:
                        '${product.stockQuantity} ${product.unit} - tối thiểu ${product.minOrderQuantity}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (product.isFeatured)
                  const _SmallBadge(
                    key: Key('adminProductFeaturedBadge'),
                    label: 'Nổi bật',
                    icon: Icons.star_outline,
                  ),
                const Spacer(),
                IconButton(
                  key: Key('adminProductEditButton_${product.id}'),
                  tooltip: 'Sửa sản phẩm',
                  onPressed: editing
                      ? null
                      : () => _showProductForm(context, product: product),
                  icon: editing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  key: Key('adminProductDeleteButton_${product.id}'),
                  tooltip: 'Xoá sản phẩm',
                  color: AppColors.error,
                  onPressed: deleting
                      ? null
                      : () => context.read<AdminProductCubit>().deleteProduct(
                          product.id,
                        ),
                  icon: deleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  final AdminProduct product;

  const _ProductThumb({required this.product});

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 58,
        height: 58,
        child: imageUrl == null || imageUrl.isEmpty
            ? const ColoredBox(
                color: AppColors.surfaceSky,
                child: Icon(Icons.image_outlined, color: AppColors.primary),
              )
            : imageUrl.startsWith('http')
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: AppColors.surfaceSky,
                  child: Icon(Icons.image_outlined, color: AppColors.primary),
                ),
              )
            : Image.asset(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: AppColors.surfaceSky,
                  child: Icon(Icons.image_outlined, color: AppColors.primary),
                ),
              ),
      ),
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

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SmallBadge({super.key, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceSky,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _IconTile({
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color backgroundColor;

  const _StatusPill({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w900,
          ),
        ),
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

({String label, Color textColor, Color backgroundColor}) _statusStyle(
  AdminProductStatus status,
) {
  return switch (status) {
    AdminProductStatus.active => (
      label: 'Đang bán',
      textColor: AppColors.success,
      backgroundColor: const Color(0xFFE8F8EF),
    ),
    AdminProductStatus.outOfStock => (
      label: 'Hết hàng',
      textColor: AppColors.warning,
      backgroundColor: const Color(0xFFFFF7E6),
    ),
    AdminProductStatus.disabled => (
      label: 'Tạm ẩn',
      textColor: AppColors.error,
      backgroundColor: const Color(0xFFFFEFEF),
    ),
  };
}

final _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(8),
  border: Border.all(color: AppColors.border),
  boxShadow: const [
    BoxShadow(color: Color(0x110B3760), blurRadius: 12, offset: Offset(0, 4)),
  ],
);
