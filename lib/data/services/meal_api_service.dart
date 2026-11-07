import 'package:dio/dio.dart';
import 'package:flutter_showcase/core/network/failure_interceptor.dart';
import 'package:flutter_showcase/core/result/failure.dart';
import 'package:flutter_showcase/data/models/meal_dto.dart';

/// TheMealDB documents `1` as its public test key. It is part of the URL.
const mealDbBaseUrl = 'https://www.themealdb.com/api/json/v1/1/';

/// Service: the only code that talks HTTP to TheMealDB.
///
/// Methods return DTOs or throw [AppFailure]; repositories turn that into
/// a `Result`.
class MealApiService {
  MealApiService(this._dio);

  final Dio _dio;

  Future<List<String>> categories() async {
    final meals = await _meals('list.php', {'c': 'list'});
    return [
      for (final m in meals)
        if (m['strCategory'] case final String c) c,
    ];
  }

  Future<List<MealDto>> search(String query) async {
    final meals = await _meals('search.php', {'s': query});
    return _parse(meals);
  }

  Future<List<MealDto>> byCategory(String category) async {
    final meals = await _meals('filter.php', {'c': category});
    return _parse(meals);
  }

  Future<MealDto> lookup(String id) async {
    final meals = await _meals('lookup.php', {'i': id});
    if (meals.isEmpty) throw const NotFoundFailure();
    return _parse(meals).first;
  }

  List<MealDto> _parse(List<Map<String, dynamic>> meals) {
    try {
      return meals.map(MealDto.fromJson).toList();
    } on Object {
      throw const ParseFailure();
    }
  }

  /// TheMealDB answers `{"meals": null}` (not 404) when nothing matches.
  Future<List<Map<String, dynamic>>> _meals(
    String path,
    Map<String, String> query,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: query,
      );
      final meals = response.data?['meals'];
      if (meals == null) return const [];
      if (meals is! List<dynamic>) throw const ParseFailure();
      return meals.whereType<Map<String, dynamic>>().toList();
    } on DioException catch (e) {
      throw FailureInterceptor.mapFailure(e);
    }
  }
}
