import 'package:flutter_showcase/domain/models/measure.dart';
import 'package:flutter_showcase/ui/shopping/measure_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats each kind of measure', () {
    expect(
      [
        const Measure.standard(amount: 200, unit: MeasureUnit.gram),
        const Measure.standard(amount: 1.5, unit: MeasureUnit.cup),
        const Measure.standard(amount: 0.25, unit: MeasureUnit.kilogram),
        const Measure.count(3),
        const Measure.named(amount: 2, unit: 'clove'),
        const Measure.note('to taste'),
      ].map(measureText),
      ['200 g', '1.5 cup', '0.25 kg', '3', '2 clove', 'to taste'],
    );
  });

  test('every unit has a symbol', () {
    expect(
      {
        for (final unit in MeasureUnit.values)
          measureText(Measure.standard(amount: 1, unit: unit)),
      },
      hasLength(MeasureUnit.values.length),
    );
  });
}
