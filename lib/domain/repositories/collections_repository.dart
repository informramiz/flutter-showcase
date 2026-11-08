import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/domain/models/meal_collection.dart';

/// User-named groups of meals. A meal can be in any number of collections.
///
/// Names are validated by the caller with `validateCollectionName`; the
/// repository trims them and the database rejects exact duplicates.
abstract interface class CollectionsRepository {
  /// All collections A to Z, with meal counts. Re-emits on every change.
  Stream<List<MealCollection>> watchCollections();

  /// Meals in one collection, most recently added first.
  Stream<List<Meal>> watchMeals(int collectionId);

  /// Ids of the collections that contain the meal.
  Stream<Set<int>> watchCollectionIdsFor(String mealId);

  /// Creates a collection and returns its id.
  Future<int> create(String name);

  Future<void> rename(int collectionId, String name);

  /// Deletes the collection. The meals themselves are kept.
  Future<void> delete(int collectionId);

  /// Puts [meal] in the collection when [included], or takes it out.
  Future<void> setMembership(
    int collectionId,
    Meal meal, {
    required bool included,
  });
}
