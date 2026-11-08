import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/domain/models/measure.dart';
import 'package:flutter_showcase/domain/models/shopping_item.dart';
import 'package:flutter_showcase/domain/services/shopping_list_builder.dart';
import 'package:flutter_test/flutter_test.dart';

Meal _meal(String name, Map<String, String> ingredients) => Meal(
  id: name,
  name: name,
  thumbnailUrl: '',
  ingredients: [
    for (final MapEntry(:key, :value) in ingredients.entries)
      Ingredient(name: key, measure: value),
  ],
);

ShoppingItem _item(List<ShoppingItem> items, String key) =>
    items.singleWhere((i) => i.key == key);

void main() {
  const builder = ShoppingListBuilder();

  test('sums metric mass and moves to kg past 1000 g', () {
    final items = builder.build([
      _meal('A', {'Flour': '600g'}),
      _meal('B', {'flour': '0.5 kg'}),
    ]);
    expect(items, hasLength(1));
    expect(_item(items, 'flour').totals, [
      const Measure.standard(amount: 1.1, unit: MeasureUnit.kilogram),
    ]);
    expect(_item(items, 'flour').mealNames, ['A', 'B']);
  });

  test('metric wins when units are mixed', () {
    final items = builder.build([
      _meal('A', {'Butter': '100g'}),
      _meal('B', {'Butter': '2 oz'}),
    ]);
    expect(_item(items, 'butter').totals, [
      const Measure.standard(amount: 156.7, unit: MeasureUnit.gram),
    ]);
  });

  test('imperial mass stays imperial', () {
    final items = builder.build([
      _meal('A', {'Beef': '12 oz'}),
      _meal('B', {'Beef': '1 lb'}),
    ]);
    expect(_item(items, 'beef').totals, [
      const Measure.standard(amount: 1.75, unit: MeasureUnit.pound),
    ]);
    expect(
      builder
          .build([
            _meal('A', {'Beef': '4 oz'}),
          ])
          .single
          .totals,
      [const Measure.standard(amount: 4, unit: MeasureUnit.ounce)],
    );
  });

  test('metric volume moves to litres', () {
    final items = builder.build([
      _meal('A', {'Stock': '750ml'}),
      _meal('B', {'Stock': '0.5 l'}),
    ]);
    expect(items.single.totals, [
      const Measure.standard(amount: 1.25, unit: MeasureUnit.litre),
    ]);
    expect(
      builder
          .build([
            _meal('A', {'Milk': '200 ml'}),
          ])
          .single
          .totals,
      [const Measure.standard(amount: 200, unit: MeasureUnit.millilitre)],
    );
  });

  test('imperial volume picks cup, tbsp or tsp by size', () {
    List<Measure> totals(String measure) => builder
        .build([
          _meal('A', {'Oil': measure}),
        ])
        .single
        .totals;

    expect(totals('3 tbsp'), [
      const Measure.standard(amount: 3, unit: MeasureUnit.tablespoon),
    ]);
    expect(totals('2 tsp'), [
      const Measure.standard(amount: 2, unit: MeasureUnit.teaspoon),
    ]);
    expect(totals('1/2 cup'), [
      const Measure.standard(amount: 0.5, unit: MeasureUnit.cup),
    ]);
  });

  test('tablespoons and teaspoons add up', () {
    final items = builder.build([
      _meal('A', {'Soy sauce': '1 tbsp'}),
      _meal('B', {'Soy sauce': '3 tsp'}),
    ]);
    expect(items.single.totals, [
      const Measure.standard(amount: 2, unit: MeasureUnit.tablespoon),
    ]);
  });

  test('mass and volume of one ingredient are listed separately', () {
    final items = builder.build([
      _meal('A', {'Sugar': '100g'}),
      _meal('B', {'Sugar': '1 cup'}),
    ]);
    expect(items.single.totals, [
      const Measure.standard(amount: 100, unit: MeasureUnit.gram),
      const Measure.standard(amount: 1, unit: MeasureUnit.cup),
    ]);
  });

  test('counts and named units sum, notes drop when amounts exist', () {
    final items = builder.build([
      _meal('A', {'Garlic': '2 cloves', 'Eggs': '2'}),
      _meal('B', {'garlic': '1 clove', 'Eggs': '1-3'}),
      _meal('C', {'Garlic': 'to taste'}),
    ]);
    expect(_item(items, 'garlic').totals, [
      const Measure.named(amount: 3, unit: 'clove'),
    ]);
    expect(_item(items, 'eggs').totals, [const Measure.count(5)]);
  });

  test('notes are kept when nothing measurable was asked for', () {
    final items = builder.build([
      _meal('A', {'Salt': 'to taste'}),
      _meal('B', {'Salt': 'Pinch'}),
      _meal('C', {'Salt': ''}),
    ]);
    expect(items.single.totals, [
      const Measure.note('to taste'),
      const Measure.note('pinch'),
    ]);
  });

  test('names are normalised and plurals merge into the singular', () {
    final items = builder.build([
      _meal('A', {'Olive  Oil': '1 tbsp', 'Egg': '1'}),
      _meal('B', {' olive oil ': '1 tbsp', 'Eggs': '2'}),
    ]);
    expect(items.map((i) => i.key), ['egg', 'olive oil']);
    expect(_item(items, 'egg').totals, [const Measure.count(3)]);
    expect(_item(items, 'egg').name, 'Egg');
    expect(_item(items, 'olive oil').name, 'Olive  Oil'.trim());
  });

  test('a plural without its singular keeps its own key', () {
    final items = builder.build([
      _meal('A', {'Peas': '200g'}),
    ]);
    expect(items.single.key, 'peas');
  });

  test('meal names are listed once per item', () {
    final items = builder.build([
      _meal('A', {'Rice': '100g'}),
      _meal('A', {'Rice': '100g'}),
    ]);
    expect(items.single.mealNames, ['A']);
  });

  test('blank ingredient names are skipped', () {
    expect(
      builder.build([
        _meal('A', {' ': '1'}),
      ]),
      isEmpty,
    );
  });

  test('checked keys mark items and the list is sorted', () {
    final items = builder.build(
      [
        _meal('A', {'Tomato': '2', 'Basil': '1 bunch'}),
      ],
      checkedKeys: {'tomato'},
    );
    expect(items.map((i) => i.key), ['basil', 'tomato']);
    expect(_item(items, 'tomato').checked, isTrue);
    expect(_item(items, 'basil').checked, isFalse);
  });

  test('keyFor collapses case and whitespace', () {
    expect(ShoppingListBuilder.keyFor('  Red   Onion '), 'red onion');
  });
}
