import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/ui/core/strings.dart';
import 'package:flutter_showcase/ui/core/widgets/meal_thumbnail.dart';
import 'package:flutter_showcase/ui/core/widgets/state_views.dart';
import 'package:flutter_showcase/ui/meal_detail/meal_detail_view_model.dart';

class MealDetailScreen extends ConsumerWidget {
  const MealDetailScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mealDetailViewModelProvider(id));
    final viewModel = ref.read(mealDetailViewModelProvider(id).notifier);
    final meal = state.meal;
    return Scaffold(
      appBar: AppBar(
        title: Text(meal.value?.name ?? ''),
        actions: [
          if (meal.hasValue)
            IconButton(
              tooltip: state.isFavourite
                  ? Strings.removeFavourite
                  : Strings.addFavourite,
              icon: Icon(
                state.isFavourite ? Icons.favorite : Icons.favorite_border,
              ),
              onPressed: viewModel.toggleFavourite,
            ),
        ],
      ),
      body: meal.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(error: error, onRetry: viewModel.retry),
        data: (m) => _MealBody(meal: m),
      ),
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
