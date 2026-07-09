import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/product.dart';
import 'product_visuals.dart';

/// Bộ lọc theo tình trạng tồn kho của sản phẩm.
enum ProductStockFilter { all, available, low }

/// Bộ lọc theo khoảng giá của sản phẩm.
enum ProductPriceFilter { all, under300, from300To500, over500 }

/// Bảng lọc nâng cao (danh mục, tồn kho, giá, xuất xứ, sắp xếp) hiển thị dạng bottom sheet.
class ProductFilterSheet extends StatelessWidget {
  final ProductStockFilter stockFilter;
  final ProductPriceFilter priceFilter;
  final String? originFilter;
  final List<String> originOptions;
  final bool hasCustomSort;
  final bool sortAscending;
  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<ProductStockFilter> onStockFilterChanged;
  final ValueChanged<ProductPriceFilter> onPriceFilterChanged;
  final ValueChanged<String?> onOriginFilterChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<bool> onSortChanged;
  final VoidCallback onSortReset;
  final VoidCallback onReset;
  final VoidCallback onApply;

  const ProductFilterSheet({
    super.key,
    required this.stockFilter,
    required this.priceFilter,
    required this.originFilter,
    required this.originOptions,
    required this.hasCustomSort,
    required this.sortAscending,
    required this.categories,
    required this.selectedCategoryId,
    required this.onStockFilterChanged,
    required this.onPriceFilterChanged,
    required this.onOriginFilterChanged,
    required this.onCategoryChanged,
    required this.onSortChanged,
    required this.onSortReset,
    required this.onReset,
    required this.onApply,
  });

  /// Find the parent category for a given categoryId in the category tree.
  Category? _findParentCategory() {
    if (selectedCategoryId == null) return null;
    for (final cat in categories) {
      if (cat.id == selectedCategoryId) return cat;
      for (final child in cat.children) {
        if (child.id == selectedCategoryId) return cat;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedParent = _findParentCategory();
    final childCategories = selectedParent?.children ?? const <Category>[];

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          key: const Key('productFilterSheet'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8E3EA),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Lọc sản phẩm',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (categories.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Danh mục',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SheetChoiceButton(
                      key: const Key('productFilterCategoryAll'),
                      label: 'Tất cả',
                      selected: selectedCategoryId == null,
                      onTap: () => onCategoryChanged(null),
                    ),
                    for (final cat in categories)
                      SheetChoiceButton(
                        key: Key('productFilterCategory-${cat.id}'),
                        label: displayCategoryName(cat),
                        selected: selectedParent?.id == cat.id,
                        onTap: () => onCategoryChanged(cat.id),
                      ),
                  ],
                ),
                if (selectedParent != null && childCategories.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SheetChoiceButton(
                        key: Key('productFilterCategoryAllParent-${selectedParent.id}'),
                        label: 'Tất cả ${displayCategoryName(selectedParent).toLowerCase()}',
                        selected: selectedCategoryId == selectedParent.id,
                        onTap: () => onCategoryChanged(selectedParent.id),
                      ),
                      for (final child in childCategories)
                        SheetChoiceButton(
                          key: Key('productFilterCategoryChild-${child.id}'),
                          label: displayCategoryName(child),
                          selected: selectedCategoryId == child.id,
                          onTap: () => onCategoryChanged(child.id),
                        ),
                    ],
                  ),
                ],
              ],
              const SizedBox(height: 16),
              Text(
                'Tồn kho',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SheetChoiceButton(
                    key: const Key('productFilterStockAll'),
                    label: 'Tất cả',
                    selected: stockFilter == ProductStockFilter.all,
                    onTap: () => onStockFilterChanged(ProductStockFilter.all),
                  ),
                  SheetChoiceButton(
                    key: const Key('productFilterStockAvailable'),
                    label: 'Còn hàng',
                    selected: stockFilter == ProductStockFilter.available,
                    onTap: () =>
                        onStockFilterChanged(ProductStockFilter.available),
                  ),
                  SheetChoiceButton(
                    key: const Key('productFilterStockLow'),
                    label: 'Sắp hết',
                    selected: stockFilter == ProductStockFilter.low,
                    onTap: () => onStockFilterChanged(ProductStockFilter.low),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Giá',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SheetChoiceButton(
                    key: const Key('productFilterPriceAll'),
                    label: 'Tất cả',
                    selected: priceFilter == ProductPriceFilter.all,
                    onTap: () => onPriceFilterChanged(ProductPriceFilter.all),
                  ),
                  SheetChoiceButton(
                    key: const Key('productFilterPriceUnder300'),
                    label: 'Dưới 300k',
                    selected: priceFilter == ProductPriceFilter.under300,
                    onTap: () =>
                        onPriceFilterChanged(ProductPriceFilter.under300),
                  ),
                  SheetChoiceButton(
                    key: const Key('productFilterPrice300To500'),
                    label: '300k - 500k',
                    selected: priceFilter == ProductPriceFilter.from300To500,
                    onTap: () =>
                        onPriceFilterChanged(ProductPriceFilter.from300To500),
                  ),
                  SheetChoiceButton(
                    key: const Key('productFilterPriceOver500'),
                    label: 'Trên 500k',
                    selected: priceFilter == ProductPriceFilter.over500,
                    onTap: () =>
                        onPriceFilterChanged(ProductPriceFilter.over500),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Xuất xứ',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SheetChoiceButton(
                    key: const Key('productFilterOriginAll'),
                    label: 'Tất cả',
                    selected: originFilter == null,
                    onTap: () => onOriginFilterChanged(null),
                  ),
                  for (final origin in originOptions)
                    SheetChoiceButton(
                      key: Key('productFilterOrigin-$origin'),
                      label: displayOrigin(origin),
                      selected: originFilter == origin,
                      onTap: () => onOriginFilterChanged(origin),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Sắp xếp',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SheetChoiceButton(
                    key: const Key('productFilterSortDefault'),
                    label: 'Mặc định',
                    selected: !hasCustomSort,
                    onTap: onSortReset,
                  ),
                  SheetChoiceButton(
                    key: const Key('productFilterSortPriceAsc'),
                    label: 'Giá tăng dần',
                    selected: hasCustomSort && sortAscending,
                    onTap: () => onSortChanged(true),
                  ),
                  SheetChoiceButton(
                    key: const Key('productFilterSortPriceDesc'),
                    label: 'Giá giảm dần',
                    selected: hasCustomSort && !sortAscending,
                    onTap: () => onSortChanged(false),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('productFilterResetButton'),
                      onPressed: onReset,
                      child: const Text('Đặt lại'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      key: const Key('productFilterApplyButton'),
                      onPressed: onApply,
                      child: const Text('Áp dụng'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nút lựa chọn dạng chip dùng trong bảng lọc sản phẩm.
class SheetChoiceButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const SheetChoiceButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFF8FBFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFD9E4EF),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
