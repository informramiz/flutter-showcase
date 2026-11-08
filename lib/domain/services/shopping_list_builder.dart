import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/domain/models/measure.dart';
import 'package:flutter_showcase/domain/models/shopping_item.dart';
import 'package:flutter_showcase/domain/services/ingredient_measure_parser.dart';

/// Builds a de-duplicated shopping list from planned meals.
///
/// Ingredients merge by normalised name ("Olive  Oil" = "olive oil"), and a
/// plural merges into its singular when both appear ("Eggs" + "Egg"). Amounts
/// sum within a dimension (all mass in grams, all volume in millilitres) and
/// are shown in metric when any recipe used metric, imperial otherwise.
class ShoppingListBuilder {
  const ShoppingListBuilder({
    IngredientMeasureParser parser = const IngredientMeasureParser(),
  }) : _parser = parser;

  final IngredientMeasureParser _parser;

  static final _whitespace = RegExp(r'\s+');

  /// The key an ingredient name is grouped and stored under.
  static String keyFor(String name) =>
      name.trim().toLowerCase().replaceAll(_whitespace, ' ');

  List<ShoppingItem> build(
    Iterable<Meal> meals, {
    Set<String> checkedKeys = const {},
  }) {
    final groups = <String, _Group>{};
    for (final meal in meals) {
      for (final ingredient in meal.ingredients) {
        final key = keyFor(ingredient.name);
        if (key.isEmpty) continue;
        groups
            .putIfAbsent(key, () => _Group(ingredient.name.trim()))
            .add(_parser.parse(ingredient.measure), meal.name);
      }
    }
    _mergePlurals(groups);

    final items = [
      for (final MapEntry(:key, :value) in groups.entries)
        ShoppingItem(
          key: key,
          name: value.name,
          totals: value.totals(),
          mealNames: value.mealNames.toList(),
          checked: checkedKeys.contains(key),
        ),
    ]..sort((a, b) => a.key.compareTo(b.key));
    return items;
  }

  static void _mergePlurals(Map<String, _Group> groups) {
    for (final key in groups.keys.toList()) {
      final singular = IngredientMeasureParser.singularize(key);
      if (singular == key) continue;
      final target = groups[singular];
      if (target == null) continue;
      target.absorb(groups.remove(key)!);
    }
  }
}

class _Group {
  _Group(this.name);

  final String name;
  final mealNames = <String>{};
  final named = <String, double>{};
  final notes = <String>{};
  double massGrams = 0;
  double volumeMl = 0;
  double count = 0;
  bool hasMass = false;
  bool hasVolume = false;
  bool metricMass = false;
  bool metricVolume = false;

  void add(Measure measure, String mealName) {
    mealNames.add(mealName);
    switch (measure) {
      case StandardMeasure(:final amount, :final unit):
        final base = amount * unit.toBase;
        if (unit.dimension == Dimension.mass) {
          massGrams += base;
          hasMass = true;
          metricMass |= unit.isMetric;
        } else {
          volumeMl += base;
          hasVolume = true;
          metricVolume |= unit.isMetric;
        }
      case CountMeasure(:final amount):
        count += amount;
      case NamedMeasure(:final amount, :final unit):
        named[unit] = (named[unit] ?? 0) + amount;
      case NoteMeasure(:final text):
        if (text.isNotEmpty) notes.add(text);
    }
  }

  void absorb(_Group other) {
    mealNames.addAll(other.mealNames);
    for (final MapEntry(:key, :value) in other.named.entries) {
      named[key] = (named[key] ?? 0) + value;
    }
    notes.addAll(other.notes);
    massGrams += other.massGrams;
    volumeMl += other.volumeMl;
    count += other.count;
    hasMass |= other.hasMass;
    hasVolume |= other.hasVolume;
    metricMass |= other.metricMass;
    metricVolume |= other.metricVolume;
  }

  List<Measure> totals() => [
    if (hasMass) _readable(massGrams, metric: metricMass, mass: true),
    if (hasVolume) _readable(volumeMl, metric: metricVolume, mass: false),
    if (count > 0) Measure.count(_round(count)),
    for (final MapEntry(:key, :value) in named.entries)
      Measure.named(amount: _round(value), unit: key),
    // Free-text notes only matter when nothing measurable was asked for.
    if (!hasMass && !hasVolume && count == 0 && named.isEmpty)
      for (final note in notes) Measure.note(note),
  ];

  static Measure _readable(
    double base, {
    required bool metric,
    required bool mass,
  }) {
    final MeasureUnit unit;
    if (mass) {
      unit = metric
          ? (base >= MeasureUnit.kilogram.toBase
                ? MeasureUnit.kilogram
                : MeasureUnit.gram)
          : (base >= MeasureUnit.pound.toBase
                ? MeasureUnit.pound
                : MeasureUnit.ounce);
    } else if (metric) {
      unit = base >= MeasureUnit.litre.toBase
          ? MeasureUnit.litre
          : MeasureUnit.millilitre;
    } else if (base >= MeasureUnit.cup.toBase / 4) {
      unit = MeasureUnit.cup;
    } else if (base >= MeasureUnit.tablespoon.toBase) {
      unit = MeasureUnit.tablespoon;
    } else {
      unit = MeasureUnit.teaspoon;
    }
    return Measure.standard(amount: _round(base / unit.toBase), unit: unit);
  }

  static double _round(double value) => (value * 100).roundToDouble() / 100;
}
