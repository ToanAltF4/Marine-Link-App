import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
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
import '../widgets/category_thumbnail_card.dart';
import '../widgets/hot_product_card.dart';
import '../widgets/promo_banner.dart';

const _compactFeaturedGridMaxWidth = 348.0;
const _compactFeaturedCardAspectRatio = 0.80;
final _bulkPromotionPolicyText = AppStrings.bulkDiscountPolicySummary(
  twoPercentMin: CartBulkDiscountPolicy.twoPercentMinQuantity,
  fourPercentMin: CartBulkDiscountPolicy.fourPercentMinQuantity,
  sixPercentMin: CartBulkDiscountPolicy.sixPercentMinQuantity,
  eightPercentMin: CartBulkDiscountPolicy.eightPercentMinQuantity,
);

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
  late Future<List<HomeCategorySummary>> _categoriesFuture;

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
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                    children: [
                      _buildPendingApprovalBanner(theme),
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
                              AppStrings.dealer,
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
                          hintText: AppStrings.searchSeafoodHint,
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
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      PromoBanner(onTap: _submitQuickSearch),
                      const SizedBox(height: 22),
                      Text(
                        AppStrings.productCategories,
                        style: _sectionTitleStyle(theme),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<HomeCategorySummary>>(
                        future: _categoriesFuture,
                        builder: (context, snapshot) {
                          final categories =
                              snapshot.data ?? const <HomeCategorySummary>[];
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
                              message: AppStrings.emptyProductCategories,
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
                                return CategoryThumbnailCard(
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
                                    AppStrings.wholesalePolicy,
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
                              AppStrings.bestSellingProducts,
                              style: _sectionTitleStyle(theme),
                            ),
                          ),
                          TextButton(
                            onPressed: _openCatalog,
                            child: Text(
                              AppStrings.viewAll,
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
                                message: AppStrings.loadingBestSellingProducts,
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
                                message: AppStrings.noFeaturedProducts,
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
                              return HotProductCard(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _categoriesFuture = _loadCategories();
    });
    _productBloc.add(
      const ProductListRequested(featured: true, status: 'ACTIVE', size: 4),
    );
    await _productBloc.stream.firstWhere(
      (state) => state is! ProductListLoading,
    );
  }

  Future<List<HomeCategorySummary>> _loadCategories() async {
    final response = await _productRepository.getProducts(
      page: 0,
      size: 100,
      status: 'ACTIVE',
    );

    final countsByCategory = <String, HomeCategorySummary>{};
    for (final product in response.data ?? const <Product>[]) {
      final category = product.category;
      if (category == null) {
        continue;
      }

      final existing = countsByCategory[category.id];
      countsByCategory[category.id] = HomeCategorySummary(
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
    final ordered = <HomeCategorySummary>[];
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
          String name = AppStrings.defaultDealerName;
          if (state is AuthAuthenticated) {
            name = state.user.fullName;
          }
          return Text(
            AppStrings.greeting(name),
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
        AppStrings.defaultGreeting,
        style: theme.textTheme.headlineSmall?.copyWith(
          color: AppColors.primaryDark,
          fontFamily: 'serif',
          fontWeight: FontWeight.w700,
        ),
      );
    }
  }

  Widget _buildPendingApprovalBanner(ThemeData theme) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated &&
            state.user.status == 'PENDING_APPROVAL') {
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.pending_actions, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppStrings.pendingAccountNotice,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
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
