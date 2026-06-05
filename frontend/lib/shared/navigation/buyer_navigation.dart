import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class BuyerNavigation {
  BuyerNavigation._();

  static final List<String> _tabStack = <String>[];
  static StatefulNavigationShell? _activeShell;

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
    _activeShell = null;
  }

  static void attachShell(StatefulNavigationShell shell) {
    _activeShell = shell;
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

    _syncTabStack(current);
    if (_switchBranch(context, location)) {
      return;
    }

    if (_popBackToExistingTab(context, location)) {
      return;
    }

    router.push(location);
    _recordTab(location);
  }

  static bool popOrGo(BuildContext context, String fallbackLocation) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      final currentTab = _tabKey(_currentLocation(context));
      navigator.pop();
      if (_buyerRootTabs.contains(currentTab) &&
          _tabStack.isNotEmpty &&
          _tabStack.last == currentTab) {
        _tabStack.removeLast();
      }
      return true;
    }

    if (_popTabHistory(context)) {
      return true;
    }

    final current = _currentLocation(context);
    if (_tabKey(current) == _tabKey(fallbackLocation)) {
      return false;
    }

    if (_switchBranch(context, fallbackLocation, recordHistory: false)) {
      _resetTabStack(fallbackLocation);
      return true;
    }

    GoRouter.maybeOf(context)?.go(fallbackLocation);
    _resetTabStack(fallbackLocation);
    return true;
  }

  static bool _switchBranch(
    BuildContext context,
    String location, {
    bool recordHistory = true,
  }) {
    final tabKey = _tabKey(location);
    final tabIndex = _buyerRootTabIndexes[tabKey];
    if (tabIndex == null) {
      return false;
    }

    if (!_hasShell(context)) {
      return false;
    }

    if (_isPlainRootTab(location)) {
      _goBranch(context, tabIndex);
    } else {
      GoRouter.maybeOf(context)?.go(location);
    }

    if (recordHistory) {
      final existingIndex = _tabStack.lastIndexOf(tabKey);
      if (existingIndex >= 0) {
        _tabStack.removeRange(existingIndex + 1, _tabStack.length);
      } else {
        _tabStack.add(tabKey);
      }
    }
    return true;
  }

  static bool _popTabHistory(BuildContext context) {
    if (!_hasShell(context)) {
      return false;
    }

    _syncTabStack(_currentLocation(context));
    if (_tabStack.length <= 1) {
      return false;
    }

    _tabStack.removeLast();
    final previousTab = _tabStack.last;
    final previousIndex = _buyerRootTabIndexes[previousTab];
    if (previousIndex == null) {
      return false;
    }

    _goBranch(context, previousIndex);
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

  static bool _hasShell(BuildContext context) {
    return StatefulNavigationShell.maybeOf(context) != null ||
        _activeShell != null;
  }

  static void _goBranch(BuildContext context, int index) {
    final shellState = StatefulNavigationShell.maybeOf(context);
    if (shellState != null) {
      shellState.goBranch(index);
      return;
    }

    _activeShell?.goBranch(index);
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

  static void _resetTabStack(String location) {
    _tabStack
      ..clear()
      ..add(_tabKey(location));
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
