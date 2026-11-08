import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/router.dart';
import 'package:flutter_showcase/ui/core/l10n.dart';
import 'package:flutter_showcase/ui/core/widgets/meal_card.dart';
import 'package:flutter_showcase/ui/core/widgets/state_views.dart';
import 'package:flutter_showcase/ui/favourites/favourites_view_model.dart';
import 'package:go_router/go_router.dart';

class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meals = ref.watch(favouritesViewModelProvider).meals;
    final viewModel = ref.read(favouritesViewModelProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.favouritesTab)),
      body: meals.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(error: error),
        data: (favourites) => favourites.isEmpty
            ? EmptyView(
                title: context.l10n.emptyFavourites,
                hint: context.l10n.emptyFavouritesHint,
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: favourites.length,
                itemBuilder: (context, i) => MealCard(
                  meal: favourites[i],
                  isFavourite: true,
                  onToggleFavourite: () =>
                      viewModel.toggleFavourite(favourites[i]),
                  onTap: () => context.push(
                    Routes.mealFrom(Routes.favourites, favourites[i].id),
                  ),
                ),
              ),
      ),
    );
  }
}
