import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/di/providers.dart';
import 'package:flutter_showcase/ui/core/l10n.dart';
import 'package:flutter_showcase/ui/core/widgets/offline_banner.dart';
import 'package:go_router/go_router.dart';

/// Bottom navigation with an offline banner above the current tab.
class HomeShell extends ConsumerWidget {
  const HomeShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider).value ?? true;
    return Scaffold(
      body: Column(
        children: [
          if (!online) const OfflineBanner(),
          Expanded(child: shell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.restaurant_menu),
            label: context.l10n.mealsTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite),
            label: context.l10n.favouritesTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month),
            label: context.l10n.plannerTab,
          ),
        ],
      ),
    );
  }
}
