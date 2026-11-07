import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/router.dart';
import 'package:flutter_showcase/ui/core/strings.dart';
import 'package:flutter_showcase/ui/core/widgets/meal_card.dart';
import 'package:flutter_showcase/ui/core/widgets/state_views.dart';
import 'package:flutter_showcase/ui/favourites/favourites_view_model.dart';
import 'package:go_router/go_router.dart';

class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favourites = ref.watch(favouritesViewModelProvider).meals;
    final viewModel = ref.read(favouritesViewModelProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.favouritesTab)),
      body: favourites.isEmpty
          ? const EmptyView(
              title: Strings.emptyFavourites,
              hint: Strings.emptyFavouritesHint,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: favourites.length,
              itemBuilder: (context, i) => MealCard(
                meal: favourites[i],
                isFavourite: true,
                onToggleFavourite: () =>
                    viewModel.toggleFavourite(favourites[i]),
                onTap: () => context.push(Routes.meal(favourites[i].id)),
              ),
            ),
    );
  }
}
