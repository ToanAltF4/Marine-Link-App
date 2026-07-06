import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/navigation/buyer_navigation.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/widgets/buyer_back_to_home_scope.dart';
import '../../../../shared/widgets/buyer_bottom_nav.dart';
import '../../domain/product.dart';
import '../../domain/product_repository.dart';
import '../bloc/product_bloc.dart';
import '../widgets/product_visuals.dart';

enum _ProductStockFilter { all, available, low }

class ProductListScreen extends StatefulWidget {
  static const productListScrollKey = PageStorageKey<String>(
    'productListScrollView',
  );

  final ProductRepository? productRepository;
  final String? initialQuery;
  final String? initialCategoryId;
  final ValueChanged<String>? onOpenProductDetail;

  const ProductListScreen({
    super.key,
    this.productRepository,
    this.initialQuery,
    this.initialCategoryId,
    this.onOpenProductDetail,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  static const _allFilterValue = '__all__';

  late final TextEditingController _searchController;
  late final ProductRepository _productRepository;
  late final ProductBloc _productBloc;
  List<Category> _categories = const [];
  String? _selectedCategoryId;
  String _selectedVariant = _allFilterValue;
  _ProductStockFilter _stockFilter = _ProductStockFilter.all;
  bool _sortAscending = true;
  bool _hasCustomSort = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _productRepository = widget.productRepository ?? sl<ProductRepository>();
    _productBloc = ProductBloc(productRepository: _productRepository);
    _selectedCategoryId = widget.initialCategoryId;
    _loadCategories();
    _requestProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _productBloc.close();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProductListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final queryChanged = widget.initialQuery != oldWidget.initialQuery;
    final categoryChanged =
        widget.initialCategoryId != oldWidget.initialCategoryId;
    if (!queryChanged && !categoryChanged) {
      return;
    }

    _searchController.text = widget.initialQuery ?? '';
    setState(() {
      _selectedCategoryId = widget.initialCategoryId;
      _selectedVariant = _allFilterValue;
      _stockFilter = _ProductStockFilter.all;
      _sortAscending = true;
      _hasCustomSort = false;
    });
    _requestProducts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BuyerBackToHomeScope(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FBFF),
        bottomNavigationBar: const BuyerBottomNav(
          currentTab: BuyerBottomNavTab.products,
        ),
        body: BlocProvider.value(
          value: _productBloc,
          child: SafeArea(
            bottom: false,
            child: BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                final baseProducts = state is ProductListLoaded
                    ? state.products
                    : const <Product>[];
                final selectedCategory = _selectedCategory();
                final categoryOptions = _buildVisibleCategoryOptions(
                  selectedCategory,
                );
                final variantOptions =
                    _selectedCategoryId != null && categoryOptions.isEmpty
                    ? _buildVariantOptions(baseProducts)
                    : const <String>[];
                final visibleProducts = state is ProductListLoaded
                    ? _applyLocalFilters(baseProducts)
                    : const <Product>[];

                return Column(
                  children: [
                    Material(
                      color: const Color(0xFFF8FBFF),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  onPressed: _handleBack,
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 22,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    _screenTitle(),
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: AppColors.primaryDark,
                                      fontFamily: 'serif',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _openNotifications,
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(
                                    Icons.notifications_none_rounded,
                                    size: 24,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              key: const Key('productSearchField'),
                              controller: _searchController,
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (_) => _requestProducts(),
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: _selectedCategoryId == null
                                    ? 'T\u00ecm s\u1ea3n ph\u1ea9m, xu\u1ea5t x\u1ee9...'
                                    : 'T\u00ecm trong danh m\u1ee5c...',
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: AppColors.textSecondary,
                                ),
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_searchController.text
                                        .trim()
                                        .isNotEmpty)
                                      IconButton(
                                        key: const Key(
                                          'productSearchClearButton',
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {});
                                          _requestProducts();
                                        },
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    IconButton(
                                      key: const Key('productSearchButton'),
                                      onPressed: _requestProducts,
                                      icon: const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ],
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildTopFilters(categoryOptions, variantOptions),
                          ],
                        ),
                      ),
                    ),
                    _buildBody(theme, state, visibleProducts),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadCategories() async {
    final response = await _productRepository.getCategories();
    var categories = response.data ?? const <Category>[];

    if (categories.isEmpty) {
      categories = await _loadCategoriesFromProducts();
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _categories = categories;
    });
  }

  Future<List<Category>> _loadCategoriesFromProducts() async {
    final response = await _productRepository.getProducts(
      page: 0,
      size: 100,
      status: 'ACTIVE',
    );
    final uniqueCategories = <String, Category>{};
    for (final product in response.data ?? const <Product>[]) {
      final category = product.category;
      if (category != null) {
        uniqueCategories.putIfAbsent(category.id, () => category);
      }
    }
    return uniqueCategories.values.toList()
      ..sort(
        (a, b) => displayCategoryName(a).compareTo(displayCategoryName(b)),
      );
  }

  Widget _buildBody(
    ThemeData theme,
    ProductState state,
    List<Product> visibleProducts,
  ) {
    if (state is ProductInitial || state is ProductListLoading) {
      return const Expanded(
        child: _ScrollableState(
          child: AppLoadingIndicator(message: 'Đang tải danh sách sản phẩm'),
        ),
      );
    }

    if (state is ProductListError) {
      return Expanded(
        child: _ScrollableState(
          child: AppErrorState(
            message: state.message,
            onRetry: _requestProducts,
          ),
        ),
      );
    }

    if (visibleProducts.isEmpty) {
      return Expanded(
        child: _ScrollableState(
          child: AppEmptyState(
            key: const Key('productListEmptyState'),
            message: 'Không tìm thấy sản phẩm phù hợp',
            actionLabel: 'Xóa lọc',
            onAction: _resetProductFilters,
            icon: Icons.search_off_outlined,
          ),
        ),
      );
    }

    return Expanded(
      child: ClipRect(
        child: ListView.separated(
          key: ProductListScreen.productListScrollKey,
          clipBehavior: Clip.hardEdge,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
          itemCount: visibleProducts.length + 1,
          separatorBuilder: (_, index) => index == 0
              ? const SizedBox(height: 8)
              : const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WholesalePolicyCard(
                    categoryName: _selectedCategoryId == null
                        ? null
                        : _screenTitle(),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        Text(
                          '${visibleProducts.length} mặt hàng',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _sortLabel(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF006A7C),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            final product = visibleProducts[index - 1];
            return _ProductListCard(
              product: product,
              onTap: () => _openProductDetail(product.id),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopFilters(
    List<Category> categoryOptions,
    List<String> variantOptions,
  ) {
    final scrollingFilters = _buildScrollableTopFilters(
      categoryOptions,
      variantOptions,
    );

    return KeyedSubtree(
      key: const Key('productTopFilterBar'),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FilterChipButton(
              key: const Key('productFilterAllChip'),
              label: 'T\u1ea5t c\u1ea3',
              selected:
                  _selectedCategoryId == null &&
                  _selectedVariant == _allFilterValue &&
                  _stockFilter == _ProductStockFilter.all,
              onTap: _resetProductFilters,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _AdvancedFilterButton(
              activeCount: _activeFilterCount(),
              onTap: _openAdvancedFilters,
            ),
          ),
          Expanded(
            child: ClipRect(
              // The chips use Ink, which paints its background onto the NEAREST
              // Material ancestor — without a local Material that would be the
              // full-width header Material, so the ink bled OVER the fixed
              // "Tất cả"/"Lọc" buttons when scrolled (ClipRect only clips normal
              // widgets, not ink). A transparent Material INSIDE the ClipRect
              // makes the chip ink paint here and get clipped to this block.
              child: Material(
                type: MaterialType.transparency,
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(
                    context,
                  ).copyWith(overscroll: false, scrollbars: false),
                  child: SingleChildScrollView(
                    key: const Key('productScrollableFilters'),
                    clipBehavior: Clip.hardEdge,
                    physics: const ClampingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    child: Row(children: scrollingFilters),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildScrollableTopFilters(
    List<Category> categoryOptions,
    List<String> variantOptions,
  ) {
    final widgets = <Widget>[];

    if (categoryOptions.isNotEmpty) {
      for (final category in categoryOptions) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FilterChipButton(
              label: displayCategoryName(category),
              selected: _selectedCategoryId == category.id,
              onTap: () => _selectCategory(category.id),
            ),
          ),
        );
      }
    } else if (_selectedCategoryId != null) {
      for (final option in variantOptions) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FilterChipButton(
              label: option,
              selected: _selectedVariant == option,
              onTap: () {
                setState(() {
                  _selectedVariant = option;
                });
              },
            ),
          ),
        );
      }
    }

    widgets.addAll([
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: _FilterChipButton(
          label: 'Còn hàng',
          selected: _stockFilter == _ProductStockFilter.available,
          onTap: () => _selectStockFilter(_ProductStockFilter.available),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: _FilterChipButton(
          label: 'Sắp hết',
          selected: _stockFilter == _ProductStockFilter.low,
          onTap: () => _selectStockFilter(_ProductStockFilter.low),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 4),
        child: _SortChipButton(
          label: _sortLabel(),
          ascending: _sortAscending,
          active: _hasCustomSort,
          onTap: () {
            setState(() {
              _sortAscending = !_sortAscending;
              _hasCustomSort = true;
            });
            _requestProducts();
          },
        ),
      ),
    ]);

    return widgets;
  }

  List<String> _buildVariantOptions(List<Product> products) {
    final seen = <String>{};
    final ordered = <String>[];
    for (final product in products) {
      final label = _variantLabel(product);
      if (label != null && seen.add(label)) {
        ordered.add(label);
      }
    }
    return ordered;
  }

  List<Category> _buildVisibleCategoryOptions(Category? selectedCategory) {
    if (_selectedCategoryId == null) {
      return _categories;
    }

    if (selectedCategory == null) {
      return const [];
    }

    if (selectedCategory.children.isNotEmpty) {
      return [selectedCategory, ...selectedCategory.children];
    }

    final parent = _findCategoryById(selectedCategory.parentId);
    if (parent == null) {
      return const [];
    }
    return [parent, ...parent.children];
  }

  List<Product> _applyLocalFilters(List<Product> products) {
    final filtered = products.where((product) {
      if (_selectedVariant != _allFilterValue &&
          _variantLabel(product) != _selectedVariant) {
        return false;
      }
      return switch (_stockFilter) {
        _ProductStockFilter.all => true,
        _ProductStockFilter.available => product.isAvailable,
        _ProductStockFilter.low => _isLowStock(product),
      };
    }).toList();

    if (_hasCustomSort) {
      filtered.sort((left, right) {
        final result = left.basePrice.compareTo(right.basePrice);
        return _sortAscending ? result : -result;
      });
    }
    return filtered;
  }

  bool _isLowStock(Product product) {
    return product.isAvailable &&
        product.stockQuantity <= product.minOrderQuantity * 6;
  }

  String _sortLabel() {
    if (!_hasCustomSort) {
      return 'Mặc định';
    }
    return _sortAscending ? 'Giá tăng dần' : 'Giá giảm dần';
  }

  int _activeFilterCount() {
    var count = 0;
    if (_selectedCategoryId != null) {
      count++;
    }
    if (_selectedVariant != _allFilterValue) {
      count++;
    }
    if (_stockFilter != _ProductStockFilter.all) {
      count++;
    }
    if (_hasCustomSort) {
      count++;
    }
    return count;
  }

  String? _sortParam() {
    if (!_hasCustomSort) {
      return null;
    }
    return _sortAscending ? 'price' : '-price';
  }

  void _selectStockFilter(_ProductStockFilter filter) {
    setState(() {
      _stockFilter = _stockFilter == filter ? _ProductStockFilter.all : filter;
    });
  }

  void _openAdvancedFilters() {
    var draftStockFilter = _stockFilter;
    var draftSortAscending = _sortAscending;
    var draftHasCustomSort = _hasCustomSort;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setDraftState) {
            return _ProductFilterSheet(
              stockFilter: draftStockFilter,
              hasCustomSort: draftHasCustomSort,
              sortAscending: draftSortAscending,
              onStockFilterChanged: (filter) {
                setDraftState(() => draftStockFilter = filter);
              },
              onSortChanged: (ascending) {
                setDraftState(() {
                  draftHasCustomSort = true;
                  draftSortAscending = ascending;
                });
              },
              onReset: () {
                Navigator.of(sheetContext).pop();
                _resetProductFilters();
              },
              onApply: () {
                Navigator.of(sheetContext).pop();
                setState(() {
                  _stockFilter = draftStockFilter;
                  _hasCustomSort = draftHasCustomSort;
                  _sortAscending = draftSortAscending;
                });
                _requestProducts();
              },
            );
          },
        );
      },
    );
  }

  void _resetProductFilters() {
    _searchController.clear();
    setState(() {
      _selectedCategoryId = null;
      _selectedVariant = _allFilterValue;
      _stockFilter = _ProductStockFilter.all;
      _hasCustomSort = false;
      _sortAscending = true;
    });
    _requestProducts();
  }

  String? _variantLabel(Product product) {
    final lowerName = product.name.toLowerCase();
    if (lowerName.contains('loai 1')) {
      return 'Loại 1';
    }
    if (lowerName.contains('loai 2')) {
      return 'Loại 2';
    }
    if (lowerName.contains('xe soi')) {
      return 'Xé sợi';
    }
    if (lowerName.contains('dac biet')) {
      return 'Đặc biệt';
    }
    return null;
  }

  String _screenTitle() {
    if (_selectedCategoryId == null) {
      return 'Sản phẩm';
    }

    for (final category in _categories) {
      final matched = _findCategoryById(_selectedCategoryId, category);
      if (matched != null) return displayCategoryName(matched);
    }
    return 'Sản phẩm';
  }

  Category? _selectedCategory() {
    return _findCategoryById(_selectedCategoryId);
  }

  Category? _findCategoryById(String? categoryId, [Category? root]) {
    if (categoryId == null) {
      return null;
    }

    final candidates = root == null ? _categories : [root];
    for (final category in candidates) {
      final matched = _findCategoryInTree(categoryId, category);
      if (matched != null) return matched;
    }
    return null;
  }

  Category? _findCategoryInTree(String categoryId, Category category) {
    if (category.id == categoryId) {
      return category;
    }
    for (final child in category.children) {
      final matched = _findCategoryInTree(categoryId, child);
      if (matched != null) return matched;
    }
    return null;
  }

  void _selectCategory(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedVariant = _allFilterValue;
    });
    _requestProducts();
  }

  void _requestProducts() {
    _productBloc.add(
      ProductListRequested(
        query: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        categoryId: _selectedCategoryId,
        status: 'ACTIVE',
        sort: _sortParam(),
        size: 20,
      ),
    );
  }

  void _handleBack() {
    BuyerNavigation.popOrGo(context, AppRoutes.home);
  }

  void _openNotifications() {
    BuyerNavigation.push(context, AppRoutes.notifications);
  }

  void _openProductDetail(String productId) {
    if (widget.onOpenProductDetail != null) {
      widget.onOpenProductDetail!(productId);
      return;
    }
    BuyerNavigation.push(context, AppRoutes.productDetailPath(productId));
  }
}

class _ScrollableState extends StatelessWidget {
  final Widget child;

  const _ScrollableState({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        );
      },
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
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
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _SortChipButton extends StatelessWidget {
  final String label;
  final bool ascending;
  final bool active;
  final VoidCallback onTap;

  const _SortChipButton({
    required this.label,
    required this.ascending,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? const Color(0xFF006A7C) : const Color(0xFFD1E7F7),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ascending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 16,
              color: const Color(0xFF006A7C),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF006A7C),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvancedFilterButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;

  const _AdvancedFilterButton({required this.activeCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = activeCount > 0;
    return InkWell(
      key: const Key('productAdvancedFilterButton'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE8F5FF) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? const Color(0xFF006A7C) : const Color(0xFFD9E4EF),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF006A7C)),
            const SizedBox(width: 6),
            Text(
              isActive ? 'Lọc ($activeCount)' : 'Lọc',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isActive
                    ? const Color(0xFF006A7C)
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductFilterSheet extends StatelessWidget {
  final _ProductStockFilter stockFilter;
  final bool hasCustomSort;
  final bool sortAscending;
  final ValueChanged<_ProductStockFilter> onStockFilterChanged;
  final ValueChanged<bool> onSortChanged;
  final VoidCallback onReset;
  final VoidCallback onApply;

  const _ProductFilterSheet({
    required this.stockFilter,
    required this.hasCustomSort,
    required this.sortAscending,
    required this.onStockFilterChanged,
    required this.onSortChanged,
    required this.onReset,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
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
                _SheetChoiceButton(
                  key: const Key('productFilterStockAll'),
                  label: 'Tất cả',
                  selected: stockFilter == _ProductStockFilter.all,
                  onTap: () => onStockFilterChanged(_ProductStockFilter.all),
                ),
                _SheetChoiceButton(
                  key: const Key('productFilterStockAvailable'),
                  label: 'Còn hàng',
                  selected: stockFilter == _ProductStockFilter.available,
                  onTap: () =>
                      onStockFilterChanged(_ProductStockFilter.available),
                ),
                _SheetChoiceButton(
                  key: const Key('productFilterStockLow'),
                  label: 'Sắp hết',
                  selected: stockFilter == _ProductStockFilter.low,
                  onTap: () => onStockFilterChanged(_ProductStockFilter.low),
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
                _SheetChoiceButton(
                  key: const Key('productFilterSortPriceAsc'),
                  label: 'Giá tăng dần',
                  selected: hasCustomSort && sortAscending,
                  onTap: () => onSortChanged(true),
                ),
                _SheetChoiceButton(
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
    );
  }
}

class _SheetChoiceButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SheetChoiceButton({
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

class _WholesalePolicyCard extends StatelessWidget {
  final String? categoryName;

  const _WholesalePolicyCard({this.categoryName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFD8F0FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFB5DDF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFBFE9F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_offer_outlined,
                  color: Color(0xFF006A7C),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ch\u00ednh s\u00e1ch gi\u00e1 s\u1ec9',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      categoryName == null
                          ? '\u00c1p d\u1ee5ng cho to\u00e0n b\u1ed9 danh m\u1ee5c h\u1ea3i s\u1ea3n kh\u00f4'
                          : '\u00c1p d\u1ee5ng cho c\u00e1c m\u1eb7t h\u00e0ng $categoryName',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(
                child: _TierMiniCard(
                  lineOne: '10-49kg',
                  lineTwo: 'Gi\u00e1 g\u1ed1c',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _TierMiniCard(
                  lineOne: '50-99kg',
                  lineTwo: 'Gi\u1ea3m 5%',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _TierMiniCard(
                  lineOne: '100kg+',
                  lineTwo: 'Gi\u1ea3m 10%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TierMiniCard extends StatelessWidget {
  final String lineOne;
  final String lineTwo;

  const _TierMiniCard({required this.lineOne, required this.lineTwo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF95CBE5)),
      ),
      child: Column(
        children: [
          Text(
            lineOne,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lineTwo,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _ProductListCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductListCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageProvider = productImageProvider(product);
    final fallbackVisual = productVisualStyle(product);

    return InkWell(
      key: Key('productCard-${product.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12052449),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Container(
                height: 168,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      fallbackVisual.startColor.withValues(alpha: 0.92),
                      fallbackVisual.endColor.withValues(alpha: 0.88),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  image: imageProvider != null
                      ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                      : null,
                ),
                child: Stack(
                  children: [
                    if (imageProvider == null)
                      Align(
                        alignment: Alignment.center,
                        child: Icon(
                          fallbackVisual.icon,
                          color: Colors.white,
                          size: 54,
                        ),
                      ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: productStockBgColor(product),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          productStockQuantityLabel(product),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: productStockTextColor(product),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayProductName(product),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (product.shortDescription?.trim().isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        product.shortDescription!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          displayOrigin(product.origin),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Gi\u00e1 t\u1eeb (MOQ ${product.minOrderQuantity}${product.unit})',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            children: [
                              TextSpan(
                                text: MoneyFormatter.format(product.basePrice),
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(
                                text: ' \u0111/${product.unit}',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: onTap,
                        borderRadius: BorderRadius.circular(999),
                        child: Ink(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shopping_cart_checkout_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
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
