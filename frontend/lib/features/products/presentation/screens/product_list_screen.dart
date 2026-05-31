import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/widgets/buyer_bottom_nav.dart';
import '../../domain/product.dart';
import '../../domain/product_repository.dart';
import '../bloc/product_bloc.dart';
import '../widgets/product_visuals.dart';

class ProductListScreen extends StatefulWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
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
              final variantOptions = _selectedCategoryId == null
                  ? const <String>[]
                  : _buildVariantOptions(baseProducts);
              final visibleProducts = state is ProductListLoaded
                  ? _applyLocalFilters(baseProducts)
                  : const <Product>[];

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
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
                            suffixIcon: IconButton(
                              key: const Key('productSearchButton'),
                              onPressed: _requestProducts,
                              icon: const Icon(
                                Icons.arrow_forward_rounded,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _buildTopFilters(variantOptions),
                          ),
                        ),

                      ],
                    ),
                  ),
                  _buildBody(theme, state, visibleProducts),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _loadCategories() async {
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
    final categories = uniqueCategories.values.toList()
      ..sort(
        (a, b) => displayCategoryName(a).compareTo(displayCategoryName(b)),
      );

    if (!mounted) {
      return;
    }
    setState(() {
      _categories = categories;
    });
  }

  Widget _buildBody(
    ThemeData theme,
    ProductState state,
    List<Product> visibleProducts,
  ) {
    if (state is ProductInitial || state is ProductListLoading) {
      return const Expanded(
        child: _ScrollableState(
          child: AppLoadingIndicator(
            message: '\u0110ang t\u1ea3i danh s\u00e1ch s\u1ea3n ph\u1ea9m',
          ),
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
      return const Expanded(
        child: _ScrollableState(
          child: AppEmptyState(
            key: Key('productListEmptyState'),
            message:
                'Kh\u00f4ng t\u00ecm th\u1ea5y s\u1ea3n ph\u1ea9m ph\u00f9 h\u1ee3p',
            icon: Icons.search_off_outlined,
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
        itemCount: visibleProducts.length + 1,
        separatorBuilder: (_, index) =>
            index == 0 ? const SizedBox(height: 8) : const SizedBox(height: 12),
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
                        '${visibleProducts.length} m\u1eb7t h\u00e0ng',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _sortAscending
                            ? 'Gi\u00e1 t\u0103ng d\u1ea7n'
                            : 'Gi\u00e1 gi\u1ea3m d\u1ea7n',
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
    );
  }

  List<Widget> _buildTopFilters(List<String> variantOptions) {
    final widgets = <Widget>[
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: _FilterChipButton(
          label: 'T\u1ea5t c\u1ea3',
          selected: _selectedVariant == _allFilterValue,
          onTap: () {
            setState(() {
              _selectedVariant = _allFilterValue;
            });
          },
        ),
      ),
    ];

    if (_selectedCategoryId == null) {
      for (final category in _categories) {
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
    } else {
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

    widgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 4),
        child: _SortChipButton(
          ascending: _sortAscending,
          onTap: () {
            setState(() {
              _sortAscending = !_sortAscending;
              _hasCustomSort = true;
            });
            _requestProducts();
          },
        ),
      ),
    );

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

  List<Product> _applyLocalFilters(List<Product> products) {
    final filtered = products.where((product) {
      if (_selectedVariant == _allFilterValue) {
        return true;
      }
      return _variantLabel(product) == _selectedVariant;
    }).toList();

    if (_hasCustomSort) {
      filtered.sort((left, right) {
        final result = left.basePrice.compareTo(right.basePrice);
        return _sortAscending ? result : -result;
      });
    }
    return filtered;
  }

  String? _variantLabel(Product product) {
    final lowerName = product.name.toLowerCase();
    if (lowerName.contains('loai 1')) {
      return 'Lo\u1ea1i 1';
    }
    if (lowerName.contains('loai 2')) {
      return 'Lo\u1ea1i 2';
    }
    if (lowerName.contains('xe soi')) {
      return 'X\u00e9 s\u1ee3i';
    }
    if (lowerName.contains('dac biet')) {
      return '\u0110\u1eb7c bi\u1ec7t';
    }
    return null;
  }

  String _screenTitle() {
    if (_selectedCategoryId == null) {
      return 'S\u1ea3n ph\u1ea9m';
    }

    for (final category in _categories) {
      if (category.id == _selectedCategoryId) {
        return displayCategoryName(category);
      }
    }
    return 'S\u1ea3n ph\u1ea9m';
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
        size: 20,
      ),
    );
  }

  void _handleBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go(AppRoutes.home);
    }
  }

  void _openNotifications() {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go(AppRoutes.notifications);
    }
  }

  void _openProductDetail(String productId) {
    if (widget.onOpenProductDetail != null) {
      widget.onOpenProductDetail!(productId);
      return;
    }
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go(AppRoutes.productDetailPath(productId));
    }
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
  final bool ascending;
  final VoidCallback onTap;

  const _SortChipButton({required this.ascending, required this.onTap});

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
          border: Border.all(color: const Color(0xFFD1E7F7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort_rounded, size: 16, color: Color(0xFF006A7C)),
            const SizedBox(width: 6),
            Text(
              ascending
                  ? 'Gi\u00e1 t\u0103ng d\u1ea7n'
                  : 'Gi\u00e1 gi\u1ea3m d\u1ea7n',
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
    final stockColor = productStockColor(product);
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
                          color: stockColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          productStockQuantityLabel(product),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: stockColor,
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
