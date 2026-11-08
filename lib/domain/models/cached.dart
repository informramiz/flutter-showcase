import 'package:flutter_showcase/core/result/failure.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'cached.freezed.dart';

/// One emission of an offline-first read: the data plus how fresh it is.
///
/// A stale-while-revalidate read emits the cached copy first (with
/// [isRefreshing] set), then either the fresh copy, or the cached copy again
/// with the [refreshFailure] that stopped the refresh.
@freezed
abstract class Cached<T> with _$Cached<T> {
  const factory Cached(
    T data, {

    /// When the data was last fetched from the network. `null` for results
    /// assembled from the local library, such as an offline search.
    DateTime? fetchedAt,
    @Default(false) bool isRefreshing,
    AppFailure? refreshFailure,
  }) = _Cached<T>;
}
