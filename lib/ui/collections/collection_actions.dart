import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/domain/models/meal_collection.dart';
import 'package:flutter_showcase/ui/collections/collection_name_dialog.dart';
import 'package:flutter_showcase/ui/collections/collections_view_model.dart';
import 'package:flutter_showcase/ui/core/l10n.dart';

/// What the rename/delete menu on a collection offers.
enum CollectionAction { rename, delete }

/// The ⋮ menu shared by the Collections list and a collection's page.
/// [onDeleted] runs after a confirmed delete.
class CollectionMenu extends ConsumerWidget {
  const CollectionMenu({required this.collection, this.onDeleted, super.key});

  final MealCollection collection;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final viewModel = ref.read(collectionsViewModelProvider.notifier);
    return PopupMenuButton<CollectionAction>(
      onSelected: (action) => unawaited(switch (action) {
        CollectionAction.rename => _rename(context, viewModel),
        CollectionAction.delete => _delete(context, viewModel),
      }),
      itemBuilder: (_) => [
        PopupMenuItem(value: CollectionAction.rename, child: Text(l10n.rename)),
        PopupMenuItem(value: CollectionAction.delete, child: Text(l10n.delete)),
      ],
    );
  }

  Future<void> _rename(
    BuildContext context,
    CollectionsViewModel viewModel,
  ) async {
    final name = await showCollectionNameDialog(
      context,
      title: context.l10n.rename,
      confirmLabel: context.l10n.save,
      initial: collection.name,
      validate: (name) => viewModel.validate(name, renaming: collection.id),
    );
    if (name != null) await viewModel.rename(collection.id, name);
  }

  Future<void> _delete(
    BuildContext context,
    CollectionsViewModel viewModel,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.deleteCollection(collection.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await viewModel.delete(collection.id);
    onDeleted?.call();
  }
}

/// Opens the "New collection" dialog and creates it. Resolves to the new
/// collection's name, or `null` when cancelled.
Future<String?> promptNewCollection(
  BuildContext context,
  CollectionsViewModel viewModel,
) => showCollectionNameDialog(
  context,
  title: context.l10n.newCollection,
  confirmLabel: context.l10n.create,
  validate: viewModel.validate,
);
