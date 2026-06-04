import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class BuyerNavigation {
  BuyerNavigation._();

  static final List<String> _tabStack = <String>[];

  static const Map<String, int> _buyerRootTabIndexes = {
    '/home': 0,
    '/products': 1,
    '/cart': 2,
    '/chat': 3,
    '/profile': 4,
  };

  static Set<String> get _buyerRootTabs => _buyerRootTabIndexes.keys.toSet();

  @visibleForTesting
  static void resetForTesting() {
    _tabStack.clear();
  }

  static void push(BuildContext context, String location) {
    final router = GoRouter.maybeOf(context);
    if (router == null) {
      return;
    }

    final current = _currentLocation(context);
    if (current == location) {
      _syncTabStack(current);
      return;
    }

    if (_switchBranch(context, location)) {
      return;
    }

    _syncTabStack(current);
    if (_popBackToExistingTab(context, location)) {
      return;
    }

    router.push(location);
    _recordTab(location);
  }

  static void popOrGo(BuildContext context, String fallbackLocation) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      if (_tabStack.isNotEmpty) {
        _tabStack.removeLast();
      }
      return;
    }

    if (_switchBranch(context, fallbackLocation)) {
      return;
    }

    GoRouter.maybeOf(context)?.go(fallbackLocation);
    _tabStack
      ..clear()
      ..add(_tabKey(fallbackLocation));
  }

  static bool _switchBranch(BuildContext context, String location) {
    final tabKey = _tabKey(location);
    final tabIndex = _buyerRootTabIndexes[tabKey];
    if (tabIndex == null) {
      return false;
    }

    final shell = StatefulNavigationShell.maybeOf(context);
    if (shell == null) {
      return false;
    }

    if (_isPlainRootTab(location)) {
      shell.goBranch(tabIndex);
    } else {
      GoRouter.maybeOf(context)?.go(location);
    }

    _tabStack
      ..clear()
      ..add(tabKey);
    return true;
  }

  static bool _popBackToExistingTab(BuildContext context, String location) {
    final targetKey = _tabKey(location);
    if (!_buyerRootTabs.contains(targetKey)) {
      return false;
    }

    final targetIndex = _tabStack.lastIndexOf(targetKey);
    if (targetIndex < 0) {
      return false;
    }

    final navigator = Navigator.of(context);
    while (_tabStack.length - 1 > targetIndex && navigator.canPop()) {
      navigator.pop();
      _tabStack.removeLast();
    }

    return _tabStack.isNotEmpty && _tabStack.last == targetKey;
  }

  static void _syncTabStack(String? location) {
    final key = _tabKey(location);
    if (!_buyerRootTabs.contains(key)) {
      return;
    }

    if (_tabStack.isEmpty) {
      _tabStack.add(key);
      return;
    }

    final existingIndex = _tabStack.lastIndexOf(key);
    if (existingIndex >= 0) {
      _tabStack.removeRange(existingIndex + 1, _tabStack.length);
      return;
    }

    _tabStack.add(key);
  }

  static void _recordTab(String location) {
    final key = _tabKey(location);
    if (!_buyerRootTabs.contains(key)) {
      return;
    }
    if (_tabStack.isEmpty || _tabStack.last != key) {
      _tabStack.add(key);
    }
  }

  static String? _currentLocation(BuildContext context) {
    try {
      return GoRouterState.of(context).uri.toString();
    } on Exception {
      return null;
    }
  }

  static String _tabKey(String? location) {
    if (location == null || location.isEmpty) {
      return '';
    }

    try {
      final uri = Uri.parse(location);
      return uri.path;
    } on Exception {
      return location;
    }
  }

  static bool _isPlainRootTab(String location) {
    try {
      final uri = Uri.parse(location);
      return uri.queryParameters.isEmpty && uri.fragment.isEmpty;
    } on Exception {
      return true;
    }
  }
}
