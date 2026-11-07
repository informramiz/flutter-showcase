import 'package:flutter_showcase/features/favourites/data/favourites_repository.dart';
import 'package:flutter_showcase/features/meals/domain/meal.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'favourites_providers.g.dart';

@Riverpod(keepAlive: true)
class Favourites extends _$Favourites {
  @override
  List<Meal> build() => ref.watch(favouritesRepositoryProvider).load();

  Future<void> toggle(Meal meal) {
    final exists = state.any((m) => m.id == meal.id);
    state = exists
        ? [
            for (final m in state)
              if (m.id != meal.id) m,
          ]
        : [meal, ...state];
    return ref.read(favouritesRepositoryProvider).save(state);
  }
}

@riverpod
bool isFavourite(Ref ref, String id) =>
    ref.watch(favouritesProvider).any((m) => m.id == id);
