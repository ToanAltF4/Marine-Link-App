import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Standard loading indicator widget.
/// Usage: show when BLoC/Cubit state is loading.
class AppLoadingIndicator extends StatelessWidget {
  final String? message;
  const AppLoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox.square(
                dimension: 40,
                child: CircularProgressIndicator(
                  key: Key('appLoadingIndicatorSpinner'),
                  strokeWidth: 3,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 14),
                Text(
                  message!,
                  key: const Key('appLoadingIndicatorMessage'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                  softWrap: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
