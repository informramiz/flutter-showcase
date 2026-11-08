import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/router.dart';
import 'package:flutter_showcase/ui/collections/collection_actions.dart';
import 'package:flutter_showcase/ui/collections/collections_view_model.dart';
import 'package:flutter_showcase/ui/core/l10n.dart';
import 'package:flutter_showcase/ui/core/widgets/meal_thumbnail.dart';
import 'package:flutter_showcase/ui/core/widgets/state_views.dart';
import 'package:go_router/go_router.dart';

class CollectionDetailScreen extends ConsumerWidget {
  const CollectionDetailScreen({required this.id, super.key});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(collectionDetailViewModelProvider(id));
    final viewModel = ref.read(collectionDetailViewModelProvider(id).notifier);
    final collection = state.collection;
    if (state.collectionLoaded && collection == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyView(title: l10n.pageNotFound),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(collection?.name ?? ''),
        actions: [
          if (collection != null)
            CollectionMenu(
              collection: collection,
              onDeleted: () => context.go(Routes.collections),
            ),
        ],
      ),
      body: state.meals.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(error: error),
        data: (meals) => meals.isEmpty
            ? EmptyView(
                title: l10n.emptyCollection,
                hint: l10n.emptyCollectionHint,
              )
            : ListView.builder(
                itemCount: meals.length,
                itemBuilder: (context, i) => ListTile(
                  key: ValueKey('collection-meal-${meals[i].id}'),
                  leading: MealThumbnail(url: meals[i].thumbnailUrl, size: 48),
                  title: Text(meals[i].name),
                  subtitle: meals[i].category == null
                      ? null
                      : Text(meals[i].category!),
                  trailing: IconButton(
                    tooltip: l10n.removeFromCollection,
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => viewModel.remove(meals[i]),
                  ),
                  onTap: () => context.push(Routes.meal(meals[i].id)),
                ),
              ),
      ),
    );
  }
}
