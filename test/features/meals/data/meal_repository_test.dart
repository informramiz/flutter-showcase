import 'package:flutter_showcase/core/result/failure.dart';
import 'package:flutter_showcase/core/result/result.dart';
import 'package:flutter_showcase/features/meals/data/meal_api.dart';
import 'package:flutter_showcase/features/meals/data/meal_dto.dart';
import 'package:flutter_showcase/features/meals/data/meal_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fixtures.dart';

class MockMealApi extends Mock implements MealApi {}

void main() {
  late MockMealApi api;
  late MealRepositoryImpl repository;

  setUp(() {
    api = MockMealApi();
    repository = MealRepositoryImpl(api);
  });

  test('search trims the query and maps DTOs to domain', () async {
    when(() => api.search('pasta')).thenAnswer(
      (_) async => [MealDto.fromJson(mealJson())],
    );

    final result = await repository.search('  pasta ');

    final meals = (result as Success).value as List;
    expect(meals, hasLength(1));
    verify(() => api.search('pasta')).called(1);
  });

  test('byCategory fills in the category the endpoint omits', () async {
    when(() => api.byCategory('Seafood')).thenAnswer(
      (_) async => [
        MealDto.fromJson({
          'idMeal': '5',
          'strMeal': 'Fish',
          'strMealThumb': 'u',
        }),
      ],
    );

    final meals = (await repository.byCategory('Seafood')).getOrThrow();

    expect(meals.single.category, 'Seafood');
  });

  test('categories passes the list through', () async {
    when(() => api.categories()).thenAnswer((_) async => ['Beef', 'Pasta']);
    expect((await repository.categories()).getOrThrow(), ['Beef', 'Pasta']);
  });

  test('meal maps the looked-up DTO', () async {
    when(() => api.lookup('1')).thenAnswer(
      (_) async => MealDto.fromJson(mealJson()),
    );
    final meal = (await repository.meal('1')).getOrThrow();
    expect(meal.ingredients, hasLength(2));
  });

  test('API failures become Err instead of throwing', () async {
    when(() => api.search(any())).thenThrow(const NetworkFailure());
    when(() => api.lookup(any())).thenThrow(const NotFoundFailure());
    when(() => api.byCategory(any())).thenThrow(const ServerFailure(500));
    when(() => api.categories()).thenThrow(const ParseFailure());

    expect(await repository.search('x'), isA<Err<dynamic>>());
    expect(await repository.meal('x'), isA<Err<dynamic>>());
    expect(await repository.byCategory('x'), isA<Err<dynamic>>());
    expect(await repository.categories(), isA<Err<dynamic>>());
  });
}
