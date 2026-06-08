import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/assets/app_assets.dart';

class DashboardHeader extends StatelessWidget {
  final bool hasNotification;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onProfilePressed;

  const DashboardHeader({
    super.key,
    this.hasNotification = false,
    this.onNotificationPressed,
    this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 14, 10),
          child: Row(
            children: [
              const Expanded(child: _BrandMark()),
              const SizedBox(width: 8),
              _HeaderIconButton(
                tooltip: 'Thông báo',
                onPressed: onNotificationPressed,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.primaryDark,
                      size: 27,
                    ),
                    if (hasNotification)
                      Positioned(
                        top: -1,
                        right: -1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const SizedBox(width: 9, height: 9),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _HeaderIconButton(
                tooltip: 'Hồ sơ',
                onPressed: onProfilePressed,
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.primaryDark,
                  size: 27,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: Image.asset(AppAssets.logoCircle, fit: BoxFit.contain),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            'MarineLink',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback? onPressed;
  final Widget child;

  const _HeaderIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onPressed,
            child: SizedBox(width: 48, height: 48, child: Center(child: child)),
          ),
        ),
      ),
    );
  }
}
