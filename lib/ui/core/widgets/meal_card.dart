import 'package:flutter/material.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/ui/core/l10n.dart';
import 'package:flutter_showcase/ui/core/widgets/meal_thumbnail.dart';

/// A meal row. Stateless: favourite flag and callbacks come from the screen.
class MealCard extends StatelessWidget {
  const MealCard({
    required this.meal,
    required this.isFavourite,
    required this.onTap,
    required this.onToggleFavourite,
    super.key,
  });

  final Meal meal;
  final bool isFavourite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavourite;

  @override
  Widget build(BuildContext context) {
    final favourite = isFavourite;
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
                  ? context.l10n.removeFavourite
                  : context.l10n.addFavourite,
              icon: Icon(favourite ? Icons.favorite : Icons.favorite_border),
              onPressed: onToggleFavourite,
            ),
          ],
        ),
      ),
    );
  }
}
