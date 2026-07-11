import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../domain/admin_product.dart';
import '../cubit/admin_product_cubit.dart';

/// Bộ lọc sản phẩm theo trạng thái và mức độ nổi bật.
class AdminProductFilters extends StatelessWidget {
  final AdminProductState state;

  const AdminProductFilters({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('adminProductsFilters'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterRow(
          children: [
            StatusFilterChip(
              key: const Key('adminProductStatusFilterAll'),
              label: AppStrings.all,
              selected: state.selectedStatus == null,
              status: null,
            ),
            StatusFilterChip(
              key: const Key('adminProductStatusFilterActive'),
              label: AppStrings.productActive,
              selected: state.selectedStatus == AdminProductStatus.active,
              status: AdminProductStatus.active,
            ),
            StatusFilterChip(
              key: const Key('adminProductStatusFilterOutOfStock'),
              label: AppStrings.outOfStock,
              selected: state.selectedStatus == AdminProductStatus.outOfStock,
              status: AdminProductStatus.outOfStock,
            ),
            StatusFilterChip(
              key: const Key('adminProductStatusFilterDisabled'),
              label: AppStrings.productDisabled,
              selected: state.selectedStatus == AdminProductStatus.disabled,
              status: AdminProductStatus.disabled,
            ),
          ],
        ),
        const SizedBox(height: 10),
        FilterRow(
          children: [
            FeaturedFilterChip(
              key: const Key('adminProductFeaturedFilterAll'),
              label: AppStrings.allFeatured,
              selected: state.selectedFeatured == null,
              featured: null,
            ),
            FeaturedFilterChip(
              key: const Key('adminProductFeaturedFilterYes'),
              label: AppStrings.featured,
              selected: state.selectedFeatured == true,
              featured: true,
            ),
            FeaturedFilterChip(
              key: const Key('adminProductFeaturedFilterNo'),
              label: AppStrings.notFeatured,
              selected: state.selectedFeatured == false,
              featured: false,
            ),
          ],
        ),
      ],
    );
  }
}

/// Hàng cuộn ngang chứa các chip lọc, tự chèn khoảng cách giữa các chip.
class FilterRow extends StatelessWidget {
  final List<Widget> children;

  const FilterRow({super.key, required this.children});

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

/// Chip chọn lọc theo trạng thái sản phẩm.
class StatusFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final AdminProductStatus? status;

  const StatusFilterChip({
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

/// Chip chọn lọc theo mức độ nổi bật của sản phẩm.
class FeaturedFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool? featured;

  const FeaturedFilterChip({
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
