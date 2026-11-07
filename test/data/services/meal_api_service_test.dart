import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_showcase/core/network/failure_interceptor.dart';
import 'package:flutter_showcase/core/result/failure.dart';
import 'package:flutter_showcase/data/models/meal_dto.dart';
import 'package:flutter_showcase/data/services/meal_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';

class MockDio extends Mock implements Dio {}

/// Serves canned responses through the real Dio stack, so the
/// [FailureInterceptor] is exercised too.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.respond);

  final ResponseBody Function(RequestOptions options) respond;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(String body, {int status = 200}) => ResponseBody.fromString(
  body,
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

void main() {
  group('MealApiService with a mocked Dio', () {
    late MockDio dio;
    late MealApiService api;

    setUp(() {
      dio = MockDio();
      api = MealApiService(dio);
    });

    void stub(Object? data) {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(),
          data: data as Map<String, dynamic>?,
        ),
      );
    }

    test('search sends the query and parses meals', () async {
      stub({
        'meals': [mealJson(name: 'Arrabiata')],
      });

      final meals = await api.search('arra');

      expect(meals.single.name, 'Arrabiata');
      verify(
        () => dio.get<Map<String, dynamic>>(
          'search.php',
          queryParameters: {'s': 'arra'},
        ),
      ).called(1);
    });

    test('null meals means an empty list, not an error', () async {
      stub({'meals': null});
      expect(await api.search('zzz'), isEmpty);
    });

    test('categories reads strCategory and skips malformed rows', () async {
      stub({
        'meals': [
          {'strCategory': 'Beef'},
          {'other': 1},
          {'strCategory': 'Pasta'},
        ],
      });
      expect(await api.categories(), ['Beef', 'Pasta']);
    });

    test('byCategory calls filter.php', () async {
      stub({
        'meals': [mealJson()],
      });
      await api.byCategory('Pasta');
      verify(
        () => dio.get<Map<String, dynamic>>(
          'filter.php',
          queryParameters: {'c': 'Pasta'},
        ),
      ).called(1);
    });

    test('lookup throws NotFoundFailure when nothing matches', () {
      stub({'meals': null});
      expect(api.lookup('999'), throwsA(isA<NotFoundFailure>()));
    });

    test('lookup returns the first meal', () async {
      stub({
        'meals': [mealJson(id: '7')],
      });
      expect((await api.lookup('7')).id, '7');
    });

    test('a payload with the wrong shape is a ParseFailure', () {
      stub({'meals': 'nope'});
      expect(api.search('x'), throwsA(isA<ParseFailure>()));
    });

    test('a meal missing required fields is a ParseFailure', () {
      stub({
        'meals': [
          {'idMeal': '1'},
        ],
      });
      expect(api.search('x'), throwsA(isA<ParseFailure>()));
    });
  });

  group('MealApiService through the real Dio stack', () {
    MealApiService build(ResponseBody Function(RequestOptions) respond) {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/'))
        ..httpClientAdapter = _FakeAdapter(respond)
        ..interceptors.add(FailureInterceptor());
      return MealApiService(dio);
    }

    test('maps a 500 to ServerFailure', () {
      final api = build((_) => _json('{}', status: 500));
      expect(
        api.search('x'),
        throwsA(isA<ServerFailure>().having((f) => f.statusCode, 'code', 500)),
      );
    });

    test('maps a 404 to NotFoundFailure', () {
      final api = build((_) => _json('{}', status: 404));
      expect(api.lookup('1'), throwsA(isA<NotFoundFailure>()));
    });

    test('maps a connection error to NetworkFailure', () {
      final api = build(
        (o) => throw DioException.connectionError(
          requestOptions: o,
          reason: 'offline',
        ),
      );
      expect(api.search('x'), throwsA(isA<NetworkFailure>()));
    });

    test('decodes a real response body', () async {
      final api = build(
        (_) => _json(
          '{"meals":[{"idMeal":"9","strMeal":"Soup",'
          '"strMealThumb":"u","strIngredient1":"Water","strMeasure1":"1L"}]}',
        ),
      );
      final meal = (await api.search('soup')).single;
      expect(meal.ingredients.single.name, 'Water');
    });
  });

  group('MealDto', () {
    test('folds flattened ingredients and drops blank ones', () {
      final dto = MealDto.fromJson(mealJson());
      expect(dto.ingredients.map((i) => i.name), ['Spaghetti', 'Tomato']);
      expect(dto.ingredients.last.measure, isEmpty);
    });

    test('toDomain normalises line breaks and splits tags', () {
      final meal = MealDto.fromJson(mealJson()).toDomain();
      expect(meal.instructions, 'Step one.\nStep two.');
      expect(meal.tags, ['Meat', 'Casserole']);
      expect(meal.ingredients.first.measure, '200g');
    });

    test('toDomain tolerates missing optional fields', () {
      final meal = MealDto.fromJson({
        'idMeal': '1',
        'strMeal': 'A',
        'strMealThumb': 'u',
      }).toDomain();
      expect(meal.category, isNull);
      expect(meal.instructions, isNull);
      expect(meal.tags, isEmpty);
      expect(meal.ingredients, isEmpty);
    });
  });
}
