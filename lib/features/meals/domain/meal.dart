import 'package:freezed_annotation/freezed_annotation.dart';

part 'meal.freezed.dart';

@freezed
abstract class Ingredient with _$Ingredient {
  const factory Ingredient({required String name, required String measure}) =
      _Ingredient;
}

/// A meal as the UI sees it. List endpoints only fill the first four fields.
@freezed
abstract class Meal with _$Meal {
  const factory Meal({
    required String id,
    required String name,
    required String thumbnailUrl,
    String? category,
    String? area,
    String? instructions,
    @Default(<Ingredient>[]) List<Ingredient> ingredients,
    @Default(<String>[]) List<String> tags,
  }) = _Meal;
}
