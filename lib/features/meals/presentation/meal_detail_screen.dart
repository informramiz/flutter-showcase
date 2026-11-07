import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/core/strings.dart';
import 'package:flutter_showcase/features/favourites/presentation/favourites_providers.dart';
import 'package:flutter_showcase/features/meals/domain/meal.dart';
import 'package:flutter_showcase/features/meals/presentation/meals_providers.dart';
import 'package:flutter_showcase/shared/meal_thumbnail.dart';
import 'package:flutter_showcase/shared/state_views.dart';

class MealDetailScreen extends ConsumerWidget {
  const MealDetailScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meal = ref.watch(mealDetailProvider(id));
    return Scaffold(
      appBar: AppBar(
        title: Text(meal.value?.name ?? ''),
        actions: [
          if (meal.value case final loaded?) _FavouriteButton(meal: loaded),
        ],
      ),
      body: meal.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(mealDetailProvider(id)),
        ),
        data: (m) => _MealBody(meal: m),
      ),
    );
  }
}

class _FavouriteButton extends ConsumerWidget {
  const _FavouriteButton({required this.meal});

  final Meal meal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favourite = ref.watch(isFavouriteProvider(meal.id));
    return IconButton(
      tooltip: favourite ? Strings.removeFavourite : Strings.addFavourite,
      icon: Icon(favourite ? Icons.favorite : Icons.favorite_border),
      onPressed: () => ref.read(favouritesProvider.notifier).toggle(meal),
    );
  }
}

class _MealBody extends StatelessWidget {
  const _MealBody({required this.meal});

  final Meal meal;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: MealThumbnail(url: meal.thumbnailUrl),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(meal.name, style: text.headlineSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final label in [meal.category, meal.area, ...meal.tags])
                    if (label != null) Chip(label: Text(label)),
                ],
              ),
              if (meal.ingredients.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(Strings.ingredients, style: text.titleLarge),
                const SizedBox(height: 4),
                for (final i in meal.ingredients)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(i.name),
                    trailing: Text(i.measure),
                  ),
              ],
              if (meal.instructions case final steps?) ...[
                const SizedBox(height: 16),
                Text(Strings.instructions, style: text.titleLarge),
                const SizedBox(height: 8),
                Text(steps),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
