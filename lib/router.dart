import 'package:flutter/material.dart';
import 'package:flutter_showcase/ui/collections/collection_detail_screen.dart';
import 'package:flutter_showcase/ui/collections/collections_screen.dart';
import 'package:flutter_showcase/ui/core/l10n.dart';
import 'package:flutter_showcase/ui/core/widgets/home_shell.dart';
import 'package:flutter_showcase/ui/core/widgets/state_views.dart';
import 'package:flutter_showcase/ui/favourites/favourites_screen.dart';
import 'package:flutter_showcase/ui/meal_detail/meal_detail_screen.dart';
import 'package:flutter_showcase/ui/meals/meals_screen.dart';
import 'package:flutter_showcase/ui/planner/planner_screen.dart';
import 'package:flutter_showcase/ui/shopping/shopping_list_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

/// App paths. The same paths open from deep links such as
/// `mealfinder://open/meal/52772` and from tapped cook reminders.
///
/// Meal detail is nested in every tab's branch, so it keeps the bottom bar
/// and shares that tab's navigator with the list. A Hero only flies between
/// routes of the same navigator.
abstract final class Routes {
  static const meals = '/';
  static const favourites = '/favourites';
  static const planner = '/planner';
  static const shopping = '/planner/shopping';
  static const collections = '/collections';
  static String collection(int id) => '/collections/$id';
  static String meal(String id) => '/meal/$id';

  /// Meal detail inside the tab whose current path is [from].
  static String mealFrom(String from, String id) =>
      from == meals ? meal(id) : '$from/meal/$id';
}

GoRoute _mealDetail() => GoRoute(
  path: 'meal/:mealId',
  builder: (context, state) =>
      MealDetailScreen(id: state.pathParameters['mealId']!),
);

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final router = GoRouter(
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.meals,
                builder: (context, state) => const MealsScreen(),
                routes: [_mealDetail()],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.favourites,
                builder: (context, state) => const FavouritesScreen(),
                routes: [_mealDetail()],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.planner,
                builder: (context, state) => const PlannerScreen(),
                routes: [
                  GoRoute(
                    path: 'shopping',
                    builder: (context, state) => const ShoppingListScreen(),
                  ),
                  _mealDetail(),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.collections,
                builder: (context, state) => const CollectionsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => CollectionDetailScreen(
                      id: int.tryParse(state.pathParameters['id']!) ?? -1,
                    ),
                    routes: [_mealDetail()],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(),
      body: EmptyView(
        icon: Icons.explore_off_outlined,
        title: context.l10n.pageNotFound,
      ),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
}
