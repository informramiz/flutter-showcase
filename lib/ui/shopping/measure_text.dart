import 'package:flutter_showcase/domain/models/measure.dart';

/// Short display form of a measure: `200 g`, `1.5 cup`, `2 clove`.
String measureText(Measure measure) => switch (measure) {
  StandardMeasure(:final amount, :final unit) =>
    '${_number(amount)} ${_symbol(unit)}',
  CountMeasure(:final amount) => _number(amount),
  NamedMeasure(:final amount, :final unit) => '${_number(amount)} $unit',
  NoteMeasure(:final text) => text,
};

String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');

String _symbol(MeasureUnit unit) => switch (unit) {
  MeasureUnit.gram => 'g',
  MeasureUnit.kilogram => 'kg',
  MeasureUnit.ounce => 'oz',
  MeasureUnit.pound => 'lb',
  MeasureUnit.millilitre => 'ml',
  MeasureUnit.litre => 'l',
  MeasureUnit.teaspoon => 'tsp',
  MeasureUnit.tablespoon => 'tbsp',
  MeasureUnit.cup => 'cup',
};
