import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/router.dart';
import 'package:flutter_showcase/ui/collections/collection_actions.dart';
import 'package:flutter_showcase/ui/collections/collections_view_model.dart';
import 'package:flutter_showcase/ui/core/l10n.dart';
import 'package:flutter_showcase/ui/core/widgets/state_views.dart';
import 'package:go_router/go_router.dart';

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final collections = ref.watch(collectionsViewModelProvider).collections;
    final viewModel = ref.read(collectionsViewModelProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.collectionsTab)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => unawaited(_create(context, viewModel)),
        icon: const Icon(Icons.add),
        label: Text(l10n.newCollection),
      ),
      body: collections.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(error: error),
        data: (items) => items.isEmpty
            ? EmptyView(
                title: l10n.emptyCollections,
                hint: l10n.emptyCollectionsHint,
              )
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, i) => ListTile(
                  key: ValueKey('collection-${items[i].id}'),
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(items[i].name),
                  subtitle: Text(l10n.mealCount(items[i].mealCount)),
                  trailing: CollectionMenu(collection: items[i]),
                  onTap: () => context.go(Routes.collection(items[i].id)),
                ),
              ),
      ),
    );
  }

  Future<void> _create(
    BuildContext context,
    CollectionsViewModel viewModel,
  ) async {
    final name = await promptNewCollection(context, viewModel);
    if (name != null) await viewModel.create(name);
  }
}
