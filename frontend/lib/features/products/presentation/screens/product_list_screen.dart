import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/navigation/buyer_navigation.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/widgets/buyer_back_to_home_scope.dart';
import '../../../../shared/widgets/buyer_bottom_nav.dart';
import '../../domain/product.dart';
import '../../domain/product_repository.dart';
import '../bloc/product_bloc.dart';
import '../widgets/product_active_filter_bar.dart';
import '../widgets/product_filter_sheet.dart';
import '../widgets/product_list_card.dart';
import '../widgets/product_scrollable_state.dart';
import '../widgets/product_visuals.dart';

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
  late final TextEditingController _searchController;
  late final ProductRepository _productRepository;
  late final ProductBloc _productBloc;
  List<Category> _categories = const [];
  List<String> _allOriginOptions = const [];
  String? _selectedCategoryId;
  ProductStockFilter _stockFilter = ProductStockFilter.all;
  ProductPriceFilter _priceFilter = ProductPriceFilter.all;
  String? _originFilter;
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
    _loadAllOrigins();
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
      _stockFilter = ProductStockFilter.all;
      _priceFilter = ProductPriceFilter.all;
      _originFilter = null;
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
                                    ? AppStrings.productSearchHint
                                    : AppStrings.productCategorySearchHint,
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
                            const SizedBox(height: 8),
                            ActiveFilterBar(
                              labels: _activeFilterLabels(),
                              activeCount: _activeFilterCount(),
                              onFilterTap: () =>
                                  _openAdvancedFilters(_allOriginOptions),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _handleRefresh,
                        child: _buildBody(theme, state, visibleProducts),
                      ),
                    ),
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

  Future<void> _loadAllOrigins() async {
    final response = await _productRepository.getProducts(
      page: 0,
      size: 200,
      status: 'ACTIVE',
    );
    final origins = <String>{};
    for (final product in response.data ?? const <Product>[]) {
      final origin = product.origin?.trim();
      if (origin != null && origin.isNotEmpty) {
        origins.add(origin);
      }
    }
    final sorted = origins.toList()
      ..sort((a, b) => displayOrigin(a).compareTo(displayOrigin(b)));
    if (!mounted) return;
    setState(() {
      _allOriginOptions = sorted;
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
    return uniqueCategories.values.toList()..sort(
      (a, b) => displayCategoryName(a).compareTo(displayCategoryName(b)),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    ProductState state,
    List<Product> visibleProducts,
  ) {
    if (state is ProductInitial || state is ProductListLoading) {
      return const ProductScrollableState(
        child: AppLoadingIndicator(message: AppStrings.loadingProductList),
      );
    }

    if (state is ProductListError) {
      return ProductScrollableState(
        child: AppErrorState(message: state.message, onRetry: _requestProducts),
      );
    }

    if (visibleProducts.isEmpty) {
      return ProductScrollableState(
        child: AppEmptyState(
          key: const Key('productListEmptyState'),
          message: AppStrings.noMatchingProducts,
          actionLabel: AppStrings.clearFilters,
          onAction: _resetProductFilters,
          icon: Icons.search_off_outlined,
        ),
      );
    }

    return ClipRect(
      child: ListView.separated(
        key: ProductListScreen.productListScrollKey,
        clipBehavior: Clip.hardEdge,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
        itemCount: visibleProducts.length + 1,
        separatorBuilder: (_, index) =>
            index == 0 ? const SizedBox(height: 8) : const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Text(
                        AppStrings.productCount(visibleProducts.length),
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
          return ProductListCard(
            product: product,
            onTap: () => _openProductDetail(product.id),
          );
        },
      ),
    );
  }

  Future<void> _handleRefresh() async {
    _requestProducts();
    await _productBloc.stream.firstWhere(
      (state) => state is! ProductListLoading,
    );
  }

  List<Product> _applyLocalFilters(List<Product> products) {
    final filtered = products.where((product) {
      if (!_matchesStockFilter(product)) {
        return false;
      }
      if (!_matchesPriceFilter(product)) {
        return false;
      }
      if (_originFilter != null && product.origin != _originFilter) {
        return false;
      }
      return true;
    }).toList();

    if (_hasCustomSort) {
      filtered.sort((left, right) {
        final result = left.basePrice.compareTo(right.basePrice);
        return _sortAscending ? result : -result;
      });
    }
    return filtered;
  }

  bool _matchesStockFilter(Product product) {
    return switch (_stockFilter) {
      ProductStockFilter.all => true,
      ProductStockFilter.available => product.isAvailable,
      ProductStockFilter.low => _isLowStock(product),
    };
  }

  bool _matchesPriceFilter(Product product) {
    return switch (_priceFilter) {
      ProductPriceFilter.all => true,
      ProductPriceFilter.under300 => product.basePrice < 300000,
      ProductPriceFilter.from300To500 =>
        product.basePrice >= 300000 && product.basePrice <= 500000,
      ProductPriceFilter.over500 => product.basePrice > 500000,
    };
  }

  bool _isLowStock(Product product) {
    return product.isAvailable &&
        product.stockQuantity <= product.minOrderQuantity * 6;
  }

  String _sortLabel() {
    if (!_hasCustomSort) {
      return AppStrings.defaultLabel;
    }
    return _sortAscending
        ? AppStrings.sortPriceAscending
        : AppStrings.sortPriceDescending;
  }

  int _activeFilterCount() {
    var count = 0;
    if (_selectedCategoryId != null) {
      count++;
    }
    if (_stockFilter != ProductStockFilter.all) {
      count++;
    }
    if (_priceFilter != ProductPriceFilter.all) {
      count++;
    }
    if (_originFilter != null) {
      count++;
    }
    if (_hasCustomSort) {
      count++;
    }
    return count;
  }

  List<String> _activeFilterLabels() {
    final labels = <String>[];
    if (_selectedCategoryId != null) {
      final cat = _findCategoryById(_selectedCategoryId);
      if (cat != null) {
        labels.add(displayCategoryName(cat));
      }
    }
    if (_stockFilter != ProductStockFilter.all) {
      labels.add(switch (_stockFilter) {
        ProductStockFilter.all => '',
        ProductStockFilter.available => AppStrings.inStock,
        ProductStockFilter.low => AppStrings.lowStock,
      });
    }
    if (_priceFilter != ProductPriceFilter.all) {
      labels.add(switch (_priceFilter) {
        ProductPriceFilter.all => '',
        ProductPriceFilter.under300 => AppStrings.under300k,
        ProductPriceFilter.from300To500 => AppStrings.from300To500k,
        ProductPriceFilter.over500 => AppStrings.over500k,
      });
    }
    if (_originFilter != null) {
      labels.add(displayOrigin(_originFilter!));
    }
    if (_hasCustomSort) {
      labels.add(
        _sortAscending
            ? AppStrings.sortPriceAscending
            : AppStrings.sortPriceDescending,
      );
    }
    return labels;
  }

  String? _sortParam() {
    if (!_hasCustomSort) {
      return null;
    }
    return _sortAscending ? 'price_asc' : 'price_desc';
  }

  void _openAdvancedFilters(List<String> originOptions) {
    var draftStockFilter = _stockFilter;
    var draftPriceFilter = _priceFilter;
    var draftOriginFilter = _originFilter;
    var draftSortAscending = _sortAscending;
    var draftHasCustomSort = _hasCustomSort;
    var draftCategoryId = _selectedCategoryId;

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
            return ProductFilterSheet(
              stockFilter: draftStockFilter,
              priceFilter: draftPriceFilter,
              originFilter: draftOriginFilter,
              originOptions: originOptions,
              hasCustomSort: draftHasCustomSort,
              sortAscending: draftSortAscending,
              categories: _categories,
              selectedCategoryId: draftCategoryId,
              onStockFilterChanged: (filter) {
                setDraftState(() => draftStockFilter = filter);
              },
              onPriceFilterChanged: (filter) {
                setDraftState(() => draftPriceFilter = filter);
              },
              onOriginFilterChanged: (origin) {
                setDraftState(() => draftOriginFilter = origin);
              },
              onCategoryChanged: (categoryId) {
                setDraftState(() => draftCategoryId = categoryId);
              },
              onSortChanged: (ascending) {
                setDraftState(() {
                  draftHasCustomSort = true;
                  draftSortAscending = ascending;
                });
              },
              onSortReset: () {
                setDraftState(() {
                  draftHasCustomSort = false;
                  draftSortAscending = true;
                });
              },
              onReset: () {
                Navigator.of(sheetContext).pop();
                setState(() {
                  _stockFilter = ProductStockFilter.all;
                  _priceFilter = ProductPriceFilter.all;
                  _originFilter = null;
                  _hasCustomSort = false;
                  _sortAscending = true;
                  _selectedCategoryId = null;
                });
                _requestProducts();
              },
              onApply: () {
                Navigator.of(sheetContext).pop();
                setState(() {
                  _stockFilter = draftStockFilter;
                  _priceFilter = draftPriceFilter;
                  _originFilter = draftOriginFilter;
                  _hasCustomSort = draftHasCustomSort;
                  _sortAscending = draftSortAscending;
                  _selectedCategoryId = draftCategoryId;
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
      _stockFilter = ProductStockFilter.all;
      _priceFilter = ProductPriceFilter.all;
      _originFilter = null;
      _hasCustomSort = false;
      _sortAscending = true;
    });
    _requestProducts();
  }

  String _screenTitle() {
    return AppStrings.productsTitle;
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
