import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/core/strings.dart';
import 'package:flutter_showcase/features/favourites/presentation/favourites_providers.dart';
import 'package:flutter_showcase/features/meals/presentation/meal_card.dart';
import 'package:flutter_showcase/router.dart';
import 'package:flutter_showcase/shared/state_views.dart';
import 'package:go_router/go_router.dart';

class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favourites = ref.watch(favouritesProvider);
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
                onTap: () => context.push(Routes.meal(favourites[i].id)),
              ),
            ),
    );
  }
}
