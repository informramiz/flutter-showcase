import 'package:flutter_showcase/domain/models/measure.dart';
import 'package:flutter_showcase/domain/services/ingredient_measure_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = IngredientMeasureParser();

  group('standard units', () {
    final cases = <String, Measure>{
      '200g': const Measure.standard(amount: 200, unit: MeasureUnit.gram),
      '200 g': const Measure.standard(amount: 200, unit: MeasureUnit.gram),
      '200 grams': const Measure.standard(amount: 200, unit: MeasureUnit.gram),
      '1kg': const Measure.standard(amount: 1, unit: MeasureUnit.kilogram),
      '1.5 kg': const Measure.standard(amount: 1.5, unit: MeasureUnit.kilogram),
      '8 oz': const Measure.standard(amount: 8, unit: MeasureUnit.ounce),
      '2 lbs': const Measure.standard(amount: 2, unit: MeasureUnit.pound),
      '1 lb.': const Measure.standard(amount: 1, unit: MeasureUnit.pound),
      '250ml': const Measure.standard(
        amount: 250,
        unit: MeasureUnit.millilitre,
      ),
      '1 litre': const Measure.standard(amount: 1, unit: MeasureUnit.litre),
      '2 L': const Measure.standard(amount: 2, unit: MeasureUnit.litre),
      '1 tsp': const Measure.standard(amount: 1, unit: MeasureUnit.teaspoon),
      '2 teaspoons': const Measure.standard(
        amount: 2,
        unit: MeasureUnit.teaspoon,
      ),
      '3 tbs': const Measure.standard(amount: 3, unit: MeasureUnit.tablespoon),
      '1 Tblsp': const Measure.standard(
        amount: 1,
        unit: MeasureUnit.tablespoon,
      ),
      '2 tablespoons chopped': const Measure.standard(
        amount: 2,
        unit: MeasureUnit.tablespoon,
      ),
      '1 cup': const Measure.standard(amount: 1, unit: MeasureUnit.cup),
    };
    for (final MapEntry(:key, :value) in cases.entries) {
      test('"$key"', () => expect(parser.parse(key), value));
    }
  });

  group('amounts', () {
    test('mixed number', () {
      expect(
        parser.parse('1 1/2 cups'),
        const Measure.standard(amount: 1.5, unit: MeasureUnit.cup),
      );
    });

    test('plain fraction', () {
      expect(
        parser.parse('3/4 cup'),
        const Measure.standard(amount: 0.75, unit: MeasureUnit.cup),
      );
    });

    test('unicode fraction alone and after a whole number', () {
      expect(
        parser.parse('½ tsp'),
        const Measure.standard(amount: 0.5, unit: MeasureUnit.teaspoon),
      );
      expect(
        parser.parse('1¼ cups'),
        const Measure.standard(amount: 1.25, unit: MeasureUnit.cup),
      );
    });

    test('range uses the upper bound', () {
      expect(parser.parse('1-2'), const Measure.count(2));
      expect(
        parser.parse('2 to 3 tbsp'),
        const Measure.standard(amount: 3, unit: MeasureUnit.tablespoon),
      );
      expect(
        parser.parse('1 – 2 cloves'),
        const Measure.named(amount: 2, unit: 'clove'),
      );
    });

    test('bare number is a count', () {
      expect(parser.parse('3'), const Measure.count(3));
      expect(parser.parse(' 2 '), const Measure.count(2));
    });
  });

  group('named units', () {
    test('singularised so they merge', () {
      expect(
        parser.parse('2 cloves'),
        const Measure.named(amount: 2, unit: 'clove'),
      );
      expect(
        parser.parse('1 clove'),
        const Measure.named(amount: 1, unit: 'clove'),
      );
      expect(
        parser.parse('2 pinches'),
        const Measure.named(amount: 2, unit: 'pinch'),
      );
      expect(
        parser.parse('1 can'),
        const Measure.named(amount: 1, unit: 'can'),
      );
    });

    test('keeps words that only look plural', () {
      expect(
        parser.parse('1 glass'),
        const Measure.named(amount: 1, unit: 'glass'),
      );
    });
  });

  group('notes', () {
    test('text without an amount', () {
      expect(parser.parse('To taste'), const Measure.note('to taste'));
      expect(parser.parse('Pinch'), const Measure.note('pinch'));
      expect(parser.parse('  a  dash '), const Measure.note('a dash'));
    });

    test('empty text', () {
      expect(parser.parse(''), const Measure.note(''));
    });
  });

  test('singularize leaves short words alone', () {
    expect(IngredientMeasureParser.singularize('gas'), 'gas');
    expect(IngredientMeasureParser.singularize('eggs'), 'egg');
  });
}
