import 'package:freezed_annotation/freezed_annotation.dart';

part 'meal_collection.freezed.dart';

/// A user-created group of meals, such as "Quick dinners".
@freezed
abstract class MealCollection with _$MealCollection {
  const factory MealCollection({
    required int id,
    required String name,
    @Default(0) int mealCount,
  }) = _MealCollection;
}
