import 'package:flutter_showcase/core/result/result.dart';
import 'package:flutter_showcase/features/meals/data/meal_api.dart';
import 'package:flutter_showcase/features/meals/data/meal_dto.dart';
import 'package:flutter_showcase/features/meals/domain/meal.dart';
import 'package:flutter_showcase/features/meals/domain/meal_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'meal_repository_impl.g.dart';

class MealRepositoryImpl implements MealRepository {
  MealRepositoryImpl(this._api);

  final MealApi _api;

  @override
  Future<Result<List<String>>> categories() => Result.guard(_api.categories);

  @override
  Future<Result<List<Meal>>> search(String query) => Result.guard(() async {
    final dtos = await _api.search(query.trim());
    return dtos.map((d) => d.toDomain()).toList();
  });

  @override
  Future<Result<List<Meal>>> byCategory(String category) =>
      Result.guard(() async {
        final dtos = await _api.byCategory(category);
        // The filter endpoint omits the category, so fill it in.
        return [
          for (final d in dtos) d.toDomain().copyWith(category: category),
        ];
      });

  @override
  Future<Result<Meal>> meal(String id) =>
      Result.guard(() async => (await _api.lookup(id)).toDomain());
}

@Riverpod(keepAlive: true)
MealRepository mealRepository(Ref ref) =>
    MealRepositoryImpl(ref.watch(mealApiProvider));
