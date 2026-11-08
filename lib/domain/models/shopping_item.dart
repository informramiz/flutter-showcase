import 'package:flutter_showcase/domain/models/measure.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'shopping_item.freezed.dart';

/// One line of the shopping list: an ingredient aggregated across every
/// planned meal that uses it.
@freezed
abstract class ShoppingItem with _$ShoppingItem {
  const factory ShoppingItem({
    /// Normalised ingredient name. Stable across regenerations, so the
    /// checked state can be stored against it.
    required String key,

    /// Display name, as first written in a recipe.
    required String name,

    /// Totals per dimension or unit, already converted to a readable unit.
    required List<Measure> totals,

    /// Names of the planned meals that need this ingredient.
    required List<String> mealNames,
    @Default(false) bool checked,
  }) = _ShoppingItem;
}
