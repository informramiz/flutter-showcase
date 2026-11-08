import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/domain/models/shopping_item.dart';
import 'package:flutter_showcase/ui/core/l10n.dart';
import 'package:flutter_showcase/ui/core/widgets/state_views.dart';
import 'package:flutter_showcase/ui/shopping/measure_text.dart';
import 'package:flutter_showcase/ui/shopping/shopping_list_view_model.dart';

/// Everything to buy for the week's plan, with persistent ticks.
class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(shoppingListViewModelProvider).items;
    final viewModel = ref.read(shoppingListViewModelProvider.notifier);
    final anyChecked = items.value?.any((i) => i.checked) ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.shoppingList),
        actions: [
          if (anyChecked)
            IconButton(
              tooltip: context.l10n.uncheckAll,
              icon: const Icon(Icons.remove_done),
              onPressed: () => unawaited(viewModel.uncheckAll()),
            ),
        ],
      ),
      body: items.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(error: error),
        data: (list) => list.isEmpty
            ? EmptyView(
                icon: Icons.shopping_cart_outlined,
                title: context.l10n.emptyShopping,
                hint: context.l10n.emptyShoppingHint,
              )
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, i) => _ItemTile(
                  item: list[i],
                  onChanged: () => unawaited(viewModel.toggle(list[i])),
                ),
              ),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item, required this.onChanged});

  final ShoppingItem item;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final amount = item.totals.map(measureText).join(' + ');
    final style = item.checked
        ? const TextStyle(decoration: TextDecoration.lineThrough)
        : null;
    return CheckboxListTile(
      value: item.checked,
      onChanged: (_) => onChanged(),
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        amount.isEmpty ? item.name : '${item.name} · $amount',
        style: style,
      ),
      subtitle: Text(context.l10n.usedIn(item.mealNames.join(', '))),
    );
  }
}
