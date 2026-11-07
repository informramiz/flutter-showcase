import 'package:flutter_showcase/features/meals/data/meal_repository_impl.dart';
import 'package:flutter_showcase/features/meals/domain/meal.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'meals_providers.g.dart';

const searchDebounce = Duration(milliseconds: 350);

/// Raw text from the search field, updated on every keystroke.
@Riverpod(keepAlive: true)
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  // Riverpod notifiers expose methods, not setters.
  // ignore: use_setters_to_change_properties
  void set(String value) => state = value;
}

/// Selected category chip, or `null` for "All".
@Riverpod(keepAlive: true)
class SelectedCategory extends _$SelectedCategory {
  @override
  String? build() => null;

  // Riverpod notifiers expose methods, not setters.
  // ignore: use_setters_to_change_properties
  void select(String? value) => state = value;
}

@riverpod
Future<List<String>> categories(Ref ref) async =>
    (await ref.watch(mealRepositoryProvider).categories()).getOrThrow();

/// The list on the home screen.
///
/// Debounce lives here: each keystroke invalidates this provider, the previous
/// run is disposed, and only the run that survives [searchDebounce] hits the
/// network.
@riverpod
Future<List<Meal>> meals(Ref ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  final category = ref.watch(selectedCategoryProvider);
  final repository = ref.watch(mealRepositoryProvider);
  // Fires when a newer keystroke rebuilds this provider.
  var superseded = false;
  ref.onDispose(() => superseded = true);

  if (query.isNotEmpty) {
    await Future<void>.delayed(searchDebounce);
    if (superseded) return const [];
    final found = (await repository.search(query)).getOrThrow();
    // Search results carry their category, so narrow them client-side.
    return category == null
        ? found
        : found.where((m) => m.category == category).toList();
  }
  if (category != null) {
    return (await repository.byCategory(category)).getOrThrow();
  }
  return (await repository.search('')).getOrThrow();
}

@riverpod
Future<Meal> mealDetail(Ref ref, String id) async =>
    (await ref.watch(mealRepositoryProvider).meal(id)).getOrThrow();
