import 'package:flutter/material.dart';
import 'package:flutter_showcase/ui/collections/collection_detail_screen.dart';
import 'package:flutter_showcase/ui/collections/collections_screen.dart';
import 'package:flutter_showcase/ui/core/widgets/home_shell.dart';
import 'package:flutter_showcase/ui/favourites/favourites_screen.dart';
import 'package:flutter_showcase/ui/meal_detail/meal_detail_screen.dart';
import 'package:flutter_showcase/ui/meals/meals_screen.dart';
import 'package:flutter_showcase/ui/planner/planner_screen.dart';
import 'package:flutter_showcase/ui/shopping/shopping_list_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

abstract final class Routes {
  static const meals = '/';
  static const favourites = '/favourites';
  static const planner = '/planner';
  static const shopping = '/planner/shopping';
  static const collections = '/collections';
  static String collection(int id) => '/collections/$id';
  static String meal(String id) => '/meal/$id';
}

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
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.favourites,
                builder: (context, state) => const FavouritesScreen(),
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
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/meal/:id',
        builder: (context, state) =>
            MealDetailScreen(id: state.pathParameters['id']!),
      ),
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('Page not found'))),
  );
  ref.onDispose(router.dispose);
  return router;
}
