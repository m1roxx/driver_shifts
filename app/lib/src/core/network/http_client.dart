import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:driver_shifts/src/core/config/env.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@module
abstract class HttpClientModule {
  @lazySingleton
  Dio dio(Env env) => createHttpClient(env);
}

Dio createHttpClient(Env env) {
  final dio = Dio(
    BaseOptions(
      baseUrl: '${env.apiBaseUrl}/api/v1',
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      // The first request may have to wake a sleeping free-tier backend (D12).
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (line) => developer.log('$line', name: 'http'),
      ),
    );
  }
  return dio;
}
