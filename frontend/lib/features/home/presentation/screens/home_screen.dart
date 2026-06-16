import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/navigation/buyer_navigation.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_back_exit_scope.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/widgets/buyer_bottom_nav.dart';
import '../../../../shared/widgets/dashboard_header.dart';
import '../../../cart/domain/cart_pricing.dart';
import '../../../products/domain/product.dart';
import '../../../products/domain/product_repository.dart';
import '../../../products/presentation/bloc/product_bloc.dart';
import '../../../products/presentation/widgets/product_visuals.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

const _compactFeaturedGridMaxWidth = 348.0;
const _compactFeaturedCardAspectRatio = 0.80;
const _bulkPromotionTitle = 'Ưu đãi mua nhiều';
const _bulkPromotionBannerText =
    'Giảm đến 8% cho đơn hàng từ ${CartBulkDiscountPolicy.eightPercentMinQuantity}kg';
const _bulkPromotionPolicyText =
    '${CartBulkDiscountPolicy.twoPercentMinQuantity}-99kg giảm 2% • ${CartBulkDiscountPolicy.fourPercentMinQuantity}-199kg giảm 4% • ${CartBulkDiscountPolicy.sixPercentMinQuantity}-499kg giảm 6% • ≥ ${CartBulkDiscountPolicy.eightPercentMinQuantity}kg giảm 8%';

class HomeScreen extends StatefulWidget {
  final ProductRepository? productRepository;
  final ValueChanged<String>? onQuickSearch;
  final ValueChanged<String>? onOpenProductDetail;
  final ValueChanged<String>? onOpenCategory;

  const HomeScreen({
    super.key,
    this.productRepository,
    this.onQuickSearch,
    this.onOpenProductDetail,
    this.onOpenCategory,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  late final ProductRepository _productRepository;
  late final ProductBloc _productBloc;
  late final Future<List<_HomeCategorySummary>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _productRepository = widget.productRepository ?? sl<ProductRepository>();
    _productBloc = ProductBloc(productRepository: _productRepository)
      ..add(
        const ProductListRequested(featured: true, status: 'ACTIVE', size: 4),
      );
    _categoriesFuture = _loadCategories();
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

    return AppBackExitScope(
      child: Scaffold(
        key: const Key('homeScreen'),
        backgroundColor: const Color(0xFFF8FBFF),
        bottomNavigationBar: const BuyerBottomNav(
          currentTab: BuyerBottomNavTab.home,
        ),
        body: BlocProvider.value(
          value: _productBloc,
          child: Column(
            children: [
              DashboardHeader(
                hasNotification: true,
                onNotificationPressed: _openNotifications,
                onProfilePressed: _openProfile,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                  children: [
                    _buildGreetingWidget(theme),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9F3FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.storefront_outlined,
                            size: 16,
                            color: Color(0xFF006A7C),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '\u0110\u1ea1i l\u00fd',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: const Color(0xFF006A7C),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      key: const Key('homeQuickSearchField'),
                      controller: _searchController,
                      onSubmitted: (_) => _submitQuickSearch(),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText:
                            'T\u00ecm ki\u1ebfm h\u1ea3i s\u1ea3n kh\u00f4...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 30,
                          color: AppColors.textSecondary,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _PromoBanner(onTap: _submitQuickSearch),
                    const SizedBox(height: 22),
                    Text(
                      'Danh m\u1ee5c s\u1ea3n ph\u1ea9m',
                      style: _sectionTitleStyle(theme),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<_HomeCategorySummary>>(
                      future: _categoriesFuture,
                      builder: (context, snapshot) {
                        final categories =
                            snapshot.data ?? const <_HomeCategorySummary>[];
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            categories.isEmpty) {
                          return const SizedBox(
                            height: 124,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (categories.isEmpty) {
                          return const AppEmptyState(
                            message:
                                'Ch\u01b0a c\u00f3 danh m\u1ee5c s\u1ea3n ph\u1ea9m.',
                            icon: Icons.category_outlined,
                          );
                        }

                        return SizedBox(
                          height: 124,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final item = categories[index];
                              return _CategoryThumbnailCard(
                                key: Key(
                                  'homeCategoryChip-${item.category.id}',
                                ),
                                summary: item,
                                onTap: () => _openCategory(item.category.id),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF59D4FF)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF006A7C),
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.info_outline_rounded,
                              size: 20,
                              color: Color(0xFF006A7C),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ch\u00ednh s\u00e1ch gi\u00e1 s\u1ec9',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _bulkPromotionPolicyText,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: AppColors.textPrimary,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'S\u1ea3n ph\u1ea9m b\u00e1n ch\u1ea1y',
                            style: _sectionTitleStyle(theme),
                          ),
                        ),
                        TextButton(
                          onPressed: _openCatalog,
                          child: Text(
                            'Xem t\u1ea5t c\u1ea3',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: const Color(0xFF006A7C),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    BlocBuilder<ProductBloc, ProductState>(
                      builder: (context, state) {
                        if (state is ProductInitial ||
                            state is ProductListLoading) {
                          return const SizedBox(
                            height: 360,
                            child: AppLoadingIndicator(
                              message:
                                  '\u0110ang t\u1ea3i s\u1ea3n ph\u1ea9m b\u00e1n ch\u1ea1y',
                            ),
                          );
                        }
                        if (state is ProductListError) {
                          return SizedBox(
                            height: 320,
                            child: AppErrorState(
                              message: state.message,
                              onRetry: () => _productBloc.add(
                                const ProductListRequested(
                                  featured: true,
                                  status: 'ACTIVE',
                                  size: 4,
                                ),
                              ),
                            ),
                          );
                        }
                        if (state is ProductListEmpty) {
                          return const SizedBox(
                            height: 220,
                            child: AppEmptyState(
                              message:
                                  'Ch\u01b0a c\u00f3 s\u1ea3n ph\u1ea9m n\u1ed5i b\u1eadt.',
                              icon: Icons.inventory_2_outlined,
                            ),
                          );
                        }

                        final loaded = state as ProductListLoaded;
                        final screenWidth = MediaQuery.sizeOf(context).width;
                        final compactGrid = screenWidth < 560;
                        final cardAspectRatio = compactGrid
                            ? _compactFeaturedCardAspectRatio
                            : 0.74;

                        final productGrid = GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: loaded.products.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 12,
                                childAspectRatio: cardAspectRatio,
                              ),
                          itemBuilder: (context, index) {
                            final product = loaded.products[index];
                            return _HotProductCard(
                              product: product,
                              onTap: () => _openProductDetail(product.id),
                            );
                          },
                        );

                        if (!compactGrid) {
                          return productGrid;
                        }

                        return Align(
                          alignment: Alignment.center,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: _compactFeaturedGridMaxWidth,
                            ),
                            child: productGrid,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<_HomeCategorySummary>> _loadCategories() async {
    final response = await _productRepository.getProducts(
      page: 0,
      size: 100,
      status: 'ACTIVE',
    );

    final countsByCategory = <String, _HomeCategorySummary>{};
    for (final product in response.data ?? const <Product>[]) {
      final category = product.category;
      if (category == null) {
        continue;
      }

      final existing = countsByCategory[category.id];
      countsByCategory[category.id] = _HomeCategorySummary(
        category: category,
        previewPath:
            existing?.previewPath ??
            categoryPreviewAsset(category.id) ??
            product.imageUrl,
      );
    }

    const orderedCategoryIds = [
      'cat-001',
      'cat-002',
      'cat-003',
      'cat-005',
      'cat-004',
    ];
    final ordered = <_HomeCategorySummary>[];
    for (final id in orderedCategoryIds) {
      final item = countsByCategory[id];
      if (item != null) {
        ordered.add(item);
      }
    }

    final remaining =
        countsByCategory.values
            .where((item) => !orderedCategoryIds.contains(item.category.id))
            .toList()
          ..sort((a, b) => a.category.name.compareTo(b.category.name));
    ordered.addAll(remaining);
    return ordered;
  }

  void _submitQuickSearch() {
    final query = _searchController.text.trim();
    if (widget.onQuickSearch != null) {
      widget.onQuickSearch!(query);
      return;
    }
    if (!mounted) return;
    BuyerNavigation.push(context, AppRoutes.productListLocation(query: query));
  }

  void _openCatalog() {
    if (!mounted) return;
    BuyerNavigation.push(context, AppRoutes.productList);
  }

  void _openNotifications() {
    if (!mounted) return;
    BuyerNavigation.push(context, AppRoutes.notifications);
  }

  void _openProfile() {
    if (!mounted) return;
    BuyerNavigation.push(context, AppRoutes.profile);
  }

  void _openCategory(String categoryId) {
    if (widget.onOpenCategory != null) {
      widget.onOpenCategory!(categoryId);
      return;
    }
    if (!mounted) return;
    BuyerNavigation.push(
      context,
      AppRoutes.productListLocation(categoryId: categoryId),
    );
  }

  void _openProductDetail(String productId) {
    if (widget.onOpenProductDetail != null) {
      widget.onOpenProductDetail!(productId);
      return;
    }
    if (!mounted) return;
    BuyerNavigation.push(context, AppRoutes.productDetailPath(productId));
  }

  Widget _buildGreetingWidget(ThemeData theme) {
    try {
      final authBloc = BlocProvider.of<AuthBloc>(context);
      return BlocBuilder<AuthBloc, AuthState>(
        bloc: authBloc,
        builder: (context, state) {
          String name = 'Nguy\u1ec5n V\u0103n A';
          if (state is AuthAuthenticated) {
            name = state.user.fullName;
          }
          return Text(
            'Xin ch\u00e0o, $name',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.primaryDark,
              fontFamily: 'serif',
              fontWeight: FontWeight.w700,
            ),
          );
        },
      );
    } catch (_) {
      return Text(
        'Xin ch\u00e0o, Nguy\u1ec5n V\u0103n A',
        style: theme.textTheme.headlineSmall?.copyWith(
          color: AppColors.primaryDark,
          fontFamily: 'serif',
          fontWeight: FontWeight.w700,
        ),
      );
    }
  }
}

class _HomeCategorySummary {
  final Category category;
  final String? previewPath;

  const _HomeCategorySummary({
    required this.category,
    required this.previewPath,
  });
}

class _PromoBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _PromoBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 560;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D4C97), Color(0xFF087B87)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x220B4F8F),
                blurRadius: 22,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: SizedBox(height: compact ? 136 : 160),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _DotPatternPainter()),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA726),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '\u01afu \u0111\u00e3i',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(height: compact ? 6 : 10),
                Text(
                  _bulkPromotionTitle,
                  style:
                      (compact
                              ? theme.textTheme.titleMedium
                              : theme.textTheme.titleLarge)
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                ),
                SizedBox(height: compact ? 4 : 6),
                Text(
                  _bulkPromotionBannerText,
                  style:
                      (compact
                              ? theme.textTheme.bodyMedium
                              : theme.textTheme.bodyLarge)
                          ?.copyWith(
                            color: Colors.white.withValues(alpha: 0.94),
                            fontWeight: FontWeight.w500,
                          ),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: FilledButton(
                    key: const Key('homeQuickSearchButton'),
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE8F4FF),
                      foregroundColor: AppColors.primaryDark,
                      minimumSize: Size(0, compact ? 32 : 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: compact
                          ? theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            )
                          : null,
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 12 : 18,
                        vertical: compact ? 6 : 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text('Xem ngay'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryThumbnailCard extends StatelessWidget {
  final _HomeCategorySummary summary;
  final VoidCallback onTap;

  const _CategoryThumbnailCard({
    super.key,
    required this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final previewProvider = _imageProvider(summary.previewPath);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 82,
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F6FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12052449),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
                image: previewProvider != null
                    ? DecorationImage(image: previewProvider, fit: BoxFit.cover)
                    : null,
              ),
              child: previewProvider == null
                  ? Icon(
                      categorySymbolIcon(summary.category.id),
                      color: const Color(0xFF006A7C),
                      size: 28,
                    )
                  : null,
            ),
            const SizedBox(height: 10),
            Text(
              displayCategoryName(summary.category),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider<Object>? _imageProvider(String? path) {
    if (path == null || path.isEmpty) {
      return null;
    }
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    return null;
  }
}

class _HotProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _HotProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageProvider = productImageProvider(product);
    final compact = MediaQuery.sizeOf(context).width < 560;
    final imageHeight = compact ? 108.0 : 160.0;
    final contentPadding = compact ? 9.0 : 14.0;

    return InkWell(
      key: Key('featuredProductCard-${product.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12052449),
              blurRadius: 20,
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
                height: imageHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6E7FF),
                  image: imageProvider != null
                      ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                      : null,
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: productStockBgColor(product),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      productStockLabel(product),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: productStockTextColor(product),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  contentPadding,
                  contentPadding,
                  contentPadding,
                  contentPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayProductName(product),
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (compact
                                  ? theme.textTheme.titleMedium?.copyWith(
                                      fontSize: 14,
                                      height: 1.1,
                                    )
                                  : theme.textTheme.titleLarge)
                              ?.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    SizedBox(height: compact ? 3 : 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: compact ? 14 : 18,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: compact ? 3 : 4),
                        Expanded(
                          child: Text(
                            displayOrigin(product.origin),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                (compact
                                        ? theme.textTheme.bodySmall?.copyWith(
                                            fontSize: 11,
                                            height: 1.1,
                                          )
                                        : theme.textTheme.bodyLarge)
                                    ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        children: [
                          TextSpan(
                            text: MoneyFormatter.format(product.basePrice),
                            style:
                                (compact
                                        ? theme.textTheme.titleMedium?.copyWith(
                                            fontSize: 14,
                                            height: 1.1,
                                          )
                                        : theme.textTheme.titleLarge)
                                    ?.copyWith(
                                      color: const Color(0xFF006A7C),
                                      fontWeight: FontWeight.w800,
                                    ),
                          ),
                          TextSpan(
                            text: '/${product.unit}',
                            style:
                                (compact
                                        ? theme.textTheme.bodyMedium?.copyWith(
                                            fontSize: 11,
                                            height: 1.1,
                                          )
                                        : theme.textTheme.bodyLarge)
                                    ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: compact ? 3 : 6),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 9 : 10,
                        vertical: compact ? 3 : 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F1FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'MOQ: ${product.minOrderQuantity}${product.unit}',
                        style:
                            (compact
                                    ? theme.textTheme.bodySmall?.copyWith(
                                        fontSize: 11,
                                        height: 1.1,
                                      )
                                    : theme.textTheme.bodyMedium)
                                ?.copyWith(color: AppColors.primaryDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

TextStyle? _sectionTitleStyle(ThemeData theme) {
  return theme.textTheme.titleLarge?.copyWith(
    color: AppColors.primaryDark,
    fontSize: 20,
    height: 26 / 20,
    fontWeight: FontWeight.w600,
  );
}

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.16);
    const step = 20.0;
    const radius = 1.2;

    for (double x = 8; x < size.width; x += step) {
      for (double y = 8; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
