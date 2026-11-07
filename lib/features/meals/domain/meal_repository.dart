import 'package:flutter_showcase/core/result/result.dart';
import 'package:flutter_showcase/features/meals/domain/meal.dart';

abstract interface class MealRepository {
  Future<Result<List<String>>> categories();

  /// Meals whose name contains [query]. An empty query returns a default set.
  Future<Result<List<Meal>>> search(String query);

  Future<Result<List<Meal>>> byCategory(String category);

  Future<Result<Meal>> meal(String id);
}
