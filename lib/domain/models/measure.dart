import 'package:freezed_annotation/freezed_annotation.dart';

part 'measure.freezed.dart';

/// What a [MeasureUnit] measures. Units only add up within one dimension.
enum Dimension { mass, volume }

/// A unit that converts to a base unit: grams for mass, millilitres for
/// volume.
enum MeasureUnit {
  gram(Dimension.mass, 1, isMetric: true),
  kilogram(Dimension.mass, 1000, isMetric: true),
  ounce(Dimension.mass, 28.349523125),
  pound(Dimension.mass, 453.59237),
  millilitre(Dimension.volume, 1, isMetric: true),
  litre(Dimension.volume, 1000, isMetric: true),
  teaspoon(Dimension.volume, 4.92892159375),
  tablespoon(Dimension.volume, 14.78676478125),
  cup(Dimension.volume, 240)
  ;

  const MeasureUnit(this.dimension, this.toBase, {this.isMetric = false});

  final Dimension dimension;

  /// How many base units (g or ml) one of this unit is.
  final double toBase;
  final bool isMetric;
}

/// A parsed ingredient measure such as "200g", "2 cloves" or "to taste".
@freezed
sealed class Measure with _$Measure {
  /// A convertible amount, e.g. `1.5 cup`.
  const factory Measure.standard({
    required double amount,
    required MeasureUnit unit,
  }) = StandardMeasure;

  /// A bare number of items, e.g. "3" (eggs).
  const factory Measure.count(double amount) = CountMeasure;

  /// An amount of a unit we cannot convert, e.g. `2 clove`, `1 can`.
  const factory Measure.named({required double amount, required String unit}) =
      NamedMeasure;

  /// Free text with no amount, e.g. "to taste", "pinch".
  const factory Measure.note(String text) = NoteMeasure;
}
