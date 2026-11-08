import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/router.dart';
import 'package:flutter_showcase/ui/core/l10n.dart';
import 'package:flutter_showcase/ui/core/theme/theme_mode_controller.dart';
import 'package:flutter_showcase/ui/core/widgets/freshness_bar.dart';
import 'package:flutter_showcase/ui/core/widgets/meal_card.dart';
import 'package:flutter_showcase/ui/core/widgets/state_views.dart';
import 'package:flutter_showcase/ui/meals/meals_view_model.dart';
import 'package:go_router/go_router.dart';

class MealsScreen extends ConsumerWidget {
  const MealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mealsViewModelProvider);
    final viewModel = ref.read(mealsViewModelProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.appTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.toggleTheme,
            icon: const Icon(Icons.brightness_6),
            onPressed: () => ref
                .read(themeModeControllerProvider.notifier)
                .toggle(Theme.of(context).brightness),
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchField(onChanged: viewModel.search),
          _CategoryChips(
            categories: state.categories.value,
            selected: state.selectedCategory,
            onSelected: viewModel.selectCategory,
          ),
          if (state.meals.hasValue) FreshnessBar(freshness: state.freshness),
          Expanded(
            child: state.meals.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: viewModel.retry,
              ),
              data: (list) => list.isEmpty
                  ? EmptyView(
                      title: context.l10n.emptyMeals,
                      hint: context.l10n.emptyMealsHint,
                    )
                  : RefreshIndicator(
                      onRefresh: viewModel.refresh,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                        itemCount: list.length,
                        itemBuilder: (context, i) => MealCard(
                          meal: list[i],
                          isFavourite: state.favouriteIds.contains(list[i].id),
                          onToggleFavourite: () =>
                              viewModel.toggleFavourite(list[i]),
                          onTap: () => context.push(Routes.meal(list[i].id)),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
    child: TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: context.l10n.searchHint,
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
        isDense: true,
      ),
    ),
  );
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  /// `null` while loading or failed; the row stays empty then.
  final List<String>? categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final categories = this.categories;
    if (categories == null) return const SizedBox(height: 48);
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final c in [null, ...categories])
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
              child: ChoiceChip(
                label: Text(c ?? context.l10n.allCategories),
                selected: selected == c,
                onSelected: (_) => onSelected(c),
              ),
            ),
        ],
      ),
    );
  }
}
