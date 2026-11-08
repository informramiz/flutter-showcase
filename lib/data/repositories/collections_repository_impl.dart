import 'package:flutter_showcase/core/time/clock.dart';
import 'package:flutter_showcase/data/database/collections_dao.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/domain/models/meal_collection.dart';
import 'package:flutter_showcase/domain/repositories/collections_repository.dart';

class CollectionsRepositoryImpl implements CollectionsRepository {
  CollectionsRepositoryImpl(this._dao, this._clock);

  final CollectionsDao _dao;
  final Clock _clock;

  @override
  Stream<List<MealCollection>> watchCollections() => _dao.watchCollections();

  @override
  Stream<List<Meal>> watchMeals(int collectionId) =>
      _dao.watchMeals(collectionId);

  @override
  Stream<Set<int>> watchCollectionIdsFor(String mealId) =>
      _dao.watchCollectionIdsFor(mealId);

  @override
  Future<int> create(String name) =>
      _dao.createCollection(name.trim(), _clock());

  @override
  Future<void> rename(int collectionId, String name) =>
      _dao.renameCollection(collectionId, name.trim());

  @override
  Future<void> delete(int collectionId) => _dao.deleteCollection(collectionId);

  @override
  Future<void> setMembership(
    int collectionId,
    Meal meal, {
    required bool included,
  }) => included
      ? _dao.addMeal(collectionId, meal, _clock())
      : _dao.removeMeal(collectionId, meal.id);
}
