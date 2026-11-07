import 'package:flutter/material.dart';
import 'package:flutter_showcase/features/favourites/presentation/favourites_screen.dart';
import 'package:flutter_showcase/features/meals/presentation/meal_detail_screen.dart';
import 'package:flutter_showcase/features/meals/presentation/meals_screen.dart';
import 'package:flutter_showcase/shared/home_shell.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

abstract final class Routes {
  static const meals = '/';
  static const favourites = '/favourites';
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
