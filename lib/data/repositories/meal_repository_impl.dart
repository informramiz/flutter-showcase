import 'package:flutter_showcase/core/result/result.dart';
import 'package:flutter_showcase/data/models/meal_dto.dart';
import 'package:flutter_showcase/data/services/meal_api_service.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/domain/repositories/meal_repository.dart';

/// Source of truth for meals: maps DTOs to domain models and failures to
/// `Result`s.
class MealRepositoryImpl implements MealRepository {
  MealRepositoryImpl(this._api);

  final MealApiService _api;

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
