import 'package:flutter/material.dart';

class StatusView extends StatelessWidget {
  final IconData? icon;
  final String message;
  final bool isLoading;
  final bool isError;
  final String? actionLabel;
  final VoidCallback? onAction;

  const StatusView({
    super.key,
    this.icon,
    required this.message,
    this.isLoading = false,
    this.isError = false,
    this.actionLabel,
    this.onAction,
  });

  const StatusView.loading({super.key, required this.message})
      : icon = null,
        isLoading = true,
        isError = false,
        actionLabel = null,
        onAction = null;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const CircularProgressIndicator()
            else if (icon != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isError
                      ? scheme.errorContainer
                      : scheme.primaryContainer.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 44,
                  color: isError
                      ? scheme.onErrorContainer
                      : scheme.onPrimaryContainer,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAction,
                icon: Icon(isError ? Icons.refresh : Icons.filter_alt_off),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
