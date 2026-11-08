import 'package:flutter_showcase/domain/models/measure.dart';

/// Turns a free-text recipe measure ("1 1/2 cups", "200g", "2 cloves",
/// "to taste") into a [Measure].
///
/// Pure and deterministic, so the shopping list logic can be tested without
/// Flutter. Ranges such as "1-2" use the upper bound, so the list never asks
/// for too little.
class IngredientMeasureParser {
  const IngredientMeasureParser();

  static const _unicodeFractions = {
    '½': ' 1/2',
    '⅓': ' 1/3',
    '⅔': ' 2/3',
    '¼': ' 1/4',
    '¾': ' 3/4',
    '⅛': ' 1/8',
  };

  static const _amount = r'(?:\d+\s+\d+/\d+|\d+/\d+|\d+(?:\.\d+)?)';
  static final _leadingAmount = RegExp(
    '^($_amount)(?:\\s*(?:-|–|to)\\s*($_amount))?\\s*(.*)\$',
  );
  static final _whitespace = RegExp(r'\s+');

  static const _unitAliases = <String, MeasureUnit>{
    'g': MeasureUnit.gram,
    'gr': MeasureUnit.gram,
    'gram': MeasureUnit.gram,
    'grams': MeasureUnit.gram,
    'kg': MeasureUnit.kilogram,
    'kgs': MeasureUnit.kilogram,
    'kilogram': MeasureUnit.kilogram,
    'kilograms': MeasureUnit.kilogram,
    'oz': MeasureUnit.ounce,
    'ounce': MeasureUnit.ounce,
    'ounces': MeasureUnit.ounce,
    'lb': MeasureUnit.pound,
    'lbs': MeasureUnit.pound,
    'pound': MeasureUnit.pound,
    'pounds': MeasureUnit.pound,
    'ml': MeasureUnit.millilitre,
    'millilitre': MeasureUnit.millilitre,
    'millilitres': MeasureUnit.millilitre,
    'milliliter': MeasureUnit.millilitre,
    'milliliters': MeasureUnit.millilitre,
    'l': MeasureUnit.litre,
    'litre': MeasureUnit.litre,
    'litres': MeasureUnit.litre,
    'liter': MeasureUnit.litre,
    'liters': MeasureUnit.litre,
    'tsp': MeasureUnit.teaspoon,
    'tsps': MeasureUnit.teaspoon,
    'teaspoon': MeasureUnit.teaspoon,
    'teaspoons': MeasureUnit.teaspoon,
    'tbsp': MeasureUnit.tablespoon,
    'tbsps': MeasureUnit.tablespoon,
    'tbs': MeasureUnit.tablespoon,
    'tblsp': MeasureUnit.tablespoon,
    'tablespoon': MeasureUnit.tablespoon,
    'tablespoons': MeasureUnit.tablespoon,
    'cup': MeasureUnit.cup,
    'cups': MeasureUnit.cup,
  };

  Measure parse(String raw) {
    var text = raw.trim().toLowerCase();
    for (final entry in _unicodeFractions.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }
    text = text.replaceAll(_whitespace, ' ').trim();

    final match = _leadingAmount.firstMatch(text);
    if (match == null) return Measure.note(text);

    final amount = _parseAmount(match.group(2) ?? match.group(1)!);
    final rest = match.group(3)!.trim();
    if (rest.isEmpty) return Measure.count(amount);

    final word = rest.split(' ').first.replaceAll('.', '');
    final unit = _unitAliases[word];
    if (unit != null) return Measure.standard(amount: amount, unit: unit);
    return Measure.named(amount: amount, unit: singularize(word));
  }

  /// Parses "2", "1.5", "3/4" or "1 1/2".
  static double _parseAmount(String text) {
    final parts = text.split(' ');
    var total = 0.0;
    for (final part in parts) {
      final fraction = part.split('/');
      total += fraction.length == 2
          ? double.parse(fraction[0]) / double.parse(fraction[1])
          : double.parse(part);
    }
    return total;
  }

  /// A deliberately small English singulariser: enough to merge "cloves" with
  /// "clove" and "pinches" with "pinch" without a dictionary.
  static String singularize(String word) {
    if (word.length > 4 && word.endsWith('ches')) {
      return word.substring(0, word.length - 2);
    }
    if (word.length > 3 && word.endsWith('s') && !word.endsWith('ss')) {
      return word.substring(0, word.length - 1);
    }
    return word;
  }
}
