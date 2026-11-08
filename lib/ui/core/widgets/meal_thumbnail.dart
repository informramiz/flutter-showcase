import 'package:flutter/material.dart';

/// Hero tag shared by a meal's list thumbnail and its detail image.
Object mealHeroTag(String mealId) => 'meal-$mealId';

class MealThumbnail extends StatelessWidget {
  const MealThumbnail({required this.url, this.size, this.heroTag, super.key});

  final String url;
  final double? size;

  /// When set, the image flies between routes that share this tag.
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.restaurant),
    );
    final Widget image = Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : placeholder,
    );
    final tag = heroTag;
    return SizedBox(
      width: size,
      height: size,
      child: tag == null ? image : Hero(tag: tag, child: image),
    );
  }
}
