import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/core/strings.dart';
import 'package:flutter_showcase/core/theme/theme_mode_provider.dart';
import 'package:flutter_showcase/features/meals/presentation/meal_card.dart';
import 'package:flutter_showcase/features/meals/presentation/meals_providers.dart';
import 'package:flutter_showcase/router.dart';
import 'package:flutter_showcase/shared/state_views.dart';
import 'package:go_router/go_router.dart';

class MealsScreen extends ConsumerWidget {
  const MealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meals = ref.watch(mealsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(Strings.appTitle),
        actions: [
          IconButton(
            tooltip: Strings.toggleTheme,
            icon: const Icon(Icons.brightness_6),
            onPressed: () => ref
                .read(themeModeControllerProvider.notifier)
                .toggle(Theme.of(context).brightness),
          ),
        ],
      ),
      body: Column(
        children: [
          const _SearchField(),
          const _CategoryChips(),
          Expanded(
            child: meals.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(mealsProvider),
              ),
              data: (list) => list.isEmpty
                  ? const EmptyView(
                      title: Strings.emptyMeals,
                      hint: Strings.emptyMealsHint,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      itemCount: list.length,
                      itemBuilder: (context, i) => MealCard(
                        meal: list[i],
                        onTap: () => context.push(Routes.meal(list[i].id)),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends ConsumerWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
    child: TextField(
      onChanged: ref.read(searchQueryProvider.notifier).set,
      textInputAction: TextInputAction.search,
      decoration: const InputDecoration(
        hintText: Strings.searchHint,
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
        isDense: true,
      ),
    ),
  );
}

class _CategoryChips extends ConsumerWidget {
  const _CategoryChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).value;
    final selected = ref.watch(selectedCategoryProvider);
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
                label: Text(c ?? Strings.allCategories),
                selected: selected == c,
                onSelected: (_) =>
                    ref.read(selectedCategoryProvider.notifier).select(c),
              ),
            ),
        ],
      ),
    );
  }
}
