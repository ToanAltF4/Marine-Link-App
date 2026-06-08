import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Standard error state widget.
/// Usage: show when BLoC/Cubit state is failure.
/// Does NOT display raw backend message if it could expose sensitive info.
class AppErrorState extends StatelessWidget {
  final String message;
  final String? retryLabel;
  final VoidCallback? onRetry;

  const AppErrorState({
    super.key,
    required this.message,
    this.retryLabel,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Icon(
                    Icons.error_outline_rounded,
                    key: const Key('appErrorStateIcon'),
                    size: 36,
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                message,
                key: const Key('appErrorStateMessage'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.35,
                ),
                textAlign: TextAlign.center,
                softWrap: true,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  key: const Key('appErrorStateRetryButton'),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    retryLabel ?? 'Thử lại',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
