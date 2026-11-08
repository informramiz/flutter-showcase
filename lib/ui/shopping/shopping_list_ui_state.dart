import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/domain/models/shopping_item.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'shopping_list_ui_state.freezed.dart';

/// Everything the Shopping list screen renders, as one immutable value.
@freezed
abstract class ShoppingListUiState with _$ShoppingListUiState {
  const factory ShoppingListUiState({
    @Default(AsyncLoading<List<ShoppingItem>>())
    AsyncValue<List<ShoppingItem>> items,
  }) = _ShoppingListUiState;
}
