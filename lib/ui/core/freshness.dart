import 'package:flutter_showcase/core/result/failure.dart';
import 'package:flutter_showcase/domain/models/cached.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'freshness.freezed.dart';

/// How current the data on screen is, for the "saved X ago" banner and the
/// refresh indicator.
@freezed
abstract class Freshness with _$Freshness {
  const factory Freshness({
    /// When the shown data was fetched; `null` for offline local results.
    DateTime? fetchedAt,
    @Default(false) bool isRefreshing,

    /// Why the last refresh failed, while older data is still shown.
    AppFailure? refreshFailure,
  }) = _Freshness;

  factory Freshness.of(Cached<Object?> cached) => Freshness(
    fetchedAt: cached.fetchedAt,
    isRefreshing: cached.isRefreshing,
    refreshFailure: cached.refreshFailure,
  );
}
