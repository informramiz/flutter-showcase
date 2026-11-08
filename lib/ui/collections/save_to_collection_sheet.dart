import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/ui/collections/collection_actions.dart';
import 'package:flutter_showcase/ui/collections/collections_view_model.dart';
import 'package:flutter_showcase/ui/core/l10n.dart';
import 'package:flutter_showcase/ui/core/widgets/state_views.dart';

/// Bottom sheet listing every collection with a checkbox for [meal].
/// Changes apply as they are tapped.
Future<void> showSaveToCollectionSheet(BuildContext context, Meal meal) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SaveToCollectionSheet(meal: meal),
    );

class SaveToCollectionSheet extends ConsumerWidget {
  const SaveToCollectionSheet({required this.meal, super.key});

  final Meal meal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = saveToCollectionViewModelProvider(meal.id);
    final state = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.saveToCollection,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Flexible(
            child: state.collections.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(error: error),
              data: (items) => ListView(
                shrinkWrap: true,
                children: [
                  for (final c in items)
                    CheckboxListTile(
                      key: ValueKey('save-to-${c.id}'),
                      value: state.selectedIds.contains(c.id),
                      title: Text(c.name),
                      subtitle: Text(l10n.mealCount(c.mealCount)),
                      onChanged: (_) => unawaited(viewModel.toggle(c, meal)),
                    ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: Text(l10n.newCollection),
            onTap: () => unawaited(_create(context, ref, viewModel)),
          ),
        ],
      ),
    );
  }

  Future<void> _create(
    BuildContext context,
    WidgetRef ref,
    SaveToCollectionViewModel viewModel,
  ) async {
    final name = await promptNewCollection(
      context,
      ref.read(collectionsViewModelProvider.notifier),
    );
    if (name != null) await viewModel.createWith(name, meal);
  }
}
