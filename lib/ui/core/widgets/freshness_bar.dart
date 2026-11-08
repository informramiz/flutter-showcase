import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/di/providers.dart';
import 'package:flutter_showcase/ui/core/freshness.dart';
import 'package:flutter_showcase/ui/core/l10n.dart';

/// "Saved 3 hours ago" in the user's language.
String savedAgo(Duration age, AppLocalizations l10n) {
  if (age.inDays >= 1) return l10n.savedDaysAgo(age.inDays);
  if (age.inHours >= 1) return l10n.savedHoursAgo(age.inHours);
  return l10n.savedMinutesAgo(age.inMinutes < 0 ? 0 : age.inMinutes);
}

/// Thin strip above cached content: a progress line while revalidating,
/// and a note when what is shown could not be refreshed.
class FreshnessBar extends ConsumerWidget {
  const FreshnessBar({required this.freshness, super.key});

  final Freshness freshness;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (freshness.isRefreshing) {
      return const LinearProgressIndicator(minHeight: 2);
    }
    final l10n = context.l10n;
    final fetchedAt = freshness.fetchedAt;
    final String message;
    if (fetchedAt == null) {
      if (freshness.refreshFailure == null) return const SizedBox.shrink();
      message = l10n.savedOnDevice;
    } else if (freshness.refreshFailure != null) {
      final age = ref.watch(clockProvider)().difference(fetchedAt);
      message = '${l10n.refreshFailed} · ${savedAgo(age, l10n)}';
    } else {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Icon(Icons.history, size: 16, color: scheme.onSecondaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onSecondaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
