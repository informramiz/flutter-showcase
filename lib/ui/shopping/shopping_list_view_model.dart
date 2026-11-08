import 'dart:async';

import 'package:flutter_showcase/di/providers.dart';
import 'package:flutter_showcase/domain/models/plan.dart';
import 'package:flutter_showcase/domain/models/shopping_item.dart';
import 'package:flutter_showcase/domain/services/shopping_list_builder.dart';
import 'package:flutter_showcase/ui/shopping/shopping_list_ui_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shopping_list_view_model.g.dart';

/// View model of the Shopping list: the plan and the ticked keys, combined
/// by [ShoppingListBuilder] whenever either changes.
@riverpod
class ShoppingListViewModel extends _$ShoppingListViewModel {
  static const _builder = ShoppingListBuilder();

  List<PlannedMeal>? _plan;
  Set<String>? _checked;

  @override
  ShoppingListUiState build() {
    final repository = ref.watch(plannerRepositoryProvider);
    final plan = repository.watchPlan().listen((plan) {
      _plan = plan;
      _emit();
    }, onError: _fail);
    final checked = repository.watchCheckedKeys().listen((keys) {
      _checked = keys;
      _emit();
    }, onError: _fail);
    ref.onDispose(() {
      unawaited(plan.cancel());
      unawaited(checked.cancel());
    });
    return const ShoppingListUiState();
  }

  Future<void> toggle(ShoppingItem item) => ref
      .read(plannerRepositoryProvider)
      .setChecked(item.key, checked: !item.checked);

  Future<void> uncheckAll() => ref.read(plannerRepositoryProvider).uncheckAll();

  void _emit() {
    final plan = _plan;
    final checked = _checked;
    if (plan == null || checked == null) return;
    state = ShoppingListUiState(
      items: AsyncData(
        _builder.build([for (final e in plan) e.meal], checkedKeys: checked),
      ),
    );
  }

  void _fail(Object error, StackTrace stack) =>
      state = ShoppingListUiState(items: AsyncError(error, stack));
}
