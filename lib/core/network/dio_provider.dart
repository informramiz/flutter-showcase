import 'package:dio/dio.dart';
import 'package:flutter_showcase/core/network/failure_interceptor.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_provider.g.dart';

/// TheMealDB documents `1` as its public test key. It is part of the URL.
const mealDbBaseUrl = 'https://www.themealdb.com/api/json/v1/1/';

@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final client = Dio(
    BaseOptions(
      baseUrl: mealDbBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  )..interceptors.add(FailureInterceptor());
  ref.onDispose(client.close);
  return client;
}
