import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marinelink/app/router/app_router.dart';
import 'package:marinelink/app/theme/app_theme.dart';
import 'package:marinelink/shared/navigation/buyer_navigation.dart';
import 'package:marinelink/shared/widgets/buyer_bottom_nav.dart';

void main() {
  setUp(BuyerNavigation.resetForTesting);
  tearDown(BuyerNavigation.resetForTesting);

  testWidgets('returns to existing buyer tab stack instead of reloading tabs', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const _TabProbe(
            tab: BuyerBottomNavTab.home,
            fieldKey: Key('homeStateField'),
          ),
        ),
        GoRoute(
          path: AppRoutes.productList,
          builder: (context, state) => const _TabProbe(
            tab: BuyerBottomNavTab.products,
            fieldKey: Key('productStateField'),
          ),
        ),
        GoRoute(
          path: AppRoutes.cart,
          builder: (context, state) => const _TabProbe(
            tab: BuyerBottomNavTab.cart,
            fieldKey: Key('cartStateField'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );

    await tester.enterText(
      find.byKey(const Key('homeStateField')),
      'home kept',
    );
    await tester.tap(find.text('S\u1ea3n ph\u1ea9m'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('productStateField')),
      'product kept',
    );
    await tester.tap(find.text('Gi\u1ecf h\u00e0ng'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('S\u1ea3n ph\u1ea9m'));
    await tester.pumpAndSettle();

    var productField = tester.widget<TextField>(
      find.byKey(const Key('productStateField')),
    );
    expect(productField.controller?.text, 'product kept');

    await tester.tap(find.text('Gi\u1ecf h\u00e0ng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trang ch\u1ee7'));
    await tester.pumpAndSettle();

    final homeField = tester.widget<TextField>(
      find.byKey(const Key('homeStateField')),
    );
    expect(homeField.controller?.text, 'home kept');
  });

  testWidgets('returns from buyer orders screen to profile tab root', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.orders,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            BuyerNavigation.attachShell(navigationShell);
            return navigationShell;
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.home,
                  builder: (context, state) => const _TabProbe(
                    tab: BuyerBottomNavTab.home,
                    fieldKey: Key('homeStateField'),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.productList,
                  builder: (context, state) => const _TabProbe(
                    tab: BuyerBottomNavTab.products,
                    fieldKey: Key('productStateField'),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.cart,
                  builder: (context, state) => const _TabProbe(
                    tab: BuyerBottomNavTab.cart,
                    fieldKey: Key('cartStateField'),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.chat,
                  builder: (context, state) => const _TabProbe(
                    tab: BuyerBottomNavTab.chat,
                    fieldKey: Key('chatStateField'),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.profile,
                  builder: (context, state) => const _TabProbe(
                    tab: BuyerBottomNavTab.profile,
                    fieldKey: Key('profileStateField'),
                  ),
                ),
                GoRoute(
                  path: AppRoutes.orders,
                  builder: (context, state) => const _TabProbe(
                    tab: BuyerBottomNavTab.profile,
                    fieldKey: Key('ordersStateField'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );

    expect(find.byKey(const Key('ordersStateField')), findsOneWidget);

    await tester.tap(find.text('T\u00e0i kho\u1ea3n'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profileStateField')), findsOneWidget);
    expect(find.byKey(const Key('ordersStateField')), findsNothing);
  });
}

class _TabProbe extends StatefulWidget {
  final BuyerBottomNavTab tab;
  final Key fieldKey;

  const _TabProbe({required this.tab, required this.fieldKey});

  @override
  State<_TabProbe> createState() => _TabProbeState();
}

class _TabProbeState extends State<_TabProbe> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextField(key: widget.fieldKey, controller: _controller),
      ),
      bottomNavigationBar: BuyerBottomNav(currentTab: widget.tab),
    );
  }
}
