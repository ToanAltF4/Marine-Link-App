import 'package:flutter/material.dart';

import '../../../../core/assets/app_assets.dart';

class AuthBrandHeader extends StatelessWidget {
  final bool compact;

  const AuthBrandHeader({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(compact ? 18 : 24),
          child: Image.asset(
            AppAssets.logoSquare,
            width: compact ? 78 : 96,
            height: compact ? 78 : 96,
          ),
        ),
        SizedBox(height: compact ? 12 : 18),
        Text(
          'MarineLink',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: const Color(0xFF052449),
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        SizedBox(height: compact ? 8 : 12),
        Text(
          'Nền tảng giao thương hải sản B2B hàng đầu',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: const Color(0xFF303642),
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class AuthCard extends StatelessWidget {
  final Widget child;

  const AuthCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2A4A).withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(28), child: child),
    );
  }
}
