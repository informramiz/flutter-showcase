import 'package:flutter_showcase/features/meals/domain/meal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'meal_dto.freezed.dart';
part 'meal_dto.g.dart';

/// TheMealDB flattens ingredients into `strIngredient1..20` and
/// `strMeasure1..20`. This folds them into a list while decoding.
Object? _readIngredients(Map<dynamic, dynamic> json, String _) {
  final items = <Map<String, String>>[];
  for (var i = 1; i <= 20; i++) {
    final name = (json['strIngredient$i'] as String?)?.trim() ?? '';
    if (name.isEmpty) continue;
    final measure = (json['strMeasure$i'] as String?)?.trim() ?? '';
    items.add({'name': name, 'measure': measure});
  }
  return items;
}

@freezed
abstract class IngredientDto with _$IngredientDto {
  const factory IngredientDto({
    required String name,
    required String measure,
  }) = _IngredientDto;

  factory IngredientDto.fromJson(Map<String, dynamic> json) =>
      _$IngredientDtoFromJson(json);
}

@freezed
abstract class MealDto with _$MealDto {
  const factory MealDto({
    @JsonKey(name: 'idMeal') required String id,
    @JsonKey(name: 'strMeal') required String name,
    @JsonKey(name: 'strMealThumb') required String thumbnailUrl,
    @JsonKey(name: 'strCategory') String? category,
    @JsonKey(name: 'strArea') String? area,
    @JsonKey(name: 'strInstructions') String? instructions,
    @JsonKey(name: 'strTags') String? tags,
    @JsonKey(readValue: _readIngredients)
    @Default(<IngredientDto>[])
    List<IngredientDto> ingredients,
  }) = _MealDto;

  factory MealDto.fromJson(Map<String, dynamic> json) =>
      _$MealDtoFromJson(json);
}

extension MealDtoMapper on MealDto {
  Meal toDomain() => Meal(
    id: id,
    name: name,
    thumbnailUrl: thumbnailUrl,
    category: category,
    area: area,
    instructions: instructions?.replaceAll('\r\n', '\n').trim(),
    ingredients: [
      for (final i in ingredients) Ingredient(name: i.name, measure: i.measure),
    ],
    tags: (tags ?? '')
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList(),
  );
}
