import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/core/strings.dart';
import 'package:flutter_showcase/features/favourites/presentation/favourites_providers.dart';
import 'package:flutter_showcase/features/meals/domain/meal.dart';
import 'package:flutter_showcase/shared/meal_thumbnail.dart';

class MealCard extends ConsumerWidget {
  const MealCard({required this.meal, required this.onTap, super.key});

  final Meal meal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favourite = ref.watch(isFavouriteProvider(meal.id));
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            MealThumbnail(url: meal.thumbnailUrl, size: 88),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (meal.category != null || meal.area != null)
                    Text(
                      [meal.category, meal.area].nonNulls.join(' · '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: favourite
                  ? Strings.removeFavourite
                  : Strings.addFavourite,
              icon: Icon(favourite ? Icons.favorite : Icons.favorite_border),
              onPressed: () =>
                  ref.read(favouritesProvider.notifier).toggle(meal),
            ),
          ],
        ),
      ),
    );
  }
}
