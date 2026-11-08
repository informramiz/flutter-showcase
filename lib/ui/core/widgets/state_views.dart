import 'package:flutter/material.dart';
import 'package:flutter_showcase/ui/core/failure_message.dart';
import 'package:flutter_showcase/ui/core/l10n.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: CircularProgressIndicator(semanticsLabel: context.l10n.loading),
  );
}

class ErrorView extends StatelessWidget {
  const ErrorView({required this.error, required this.onRetry, super.key});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _Message(
    icon: Icons.error_outline,
    title: describeError(error, context.l10n),
    action: FilledButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh),
      label: Text(context.l10n.retry),
    ),
  );
}

class EmptyView extends StatelessWidget {
  const EmptyView({required this.title, required this.hint, super.key});

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) =>
      _Message(icon: Icons.search_off, title: title, subtitle: hint);
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
