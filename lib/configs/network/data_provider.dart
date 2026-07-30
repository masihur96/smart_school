import 'dart:developer';

import 'package:dio/dio.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smart_school/core/utils/storage_service.dart';
import 'package:smart_school/main.dart';
import 'package:smart_school/configs/route_generator.dart';
import 'package:smart_school/features/auth/presentation/screens/login_screen.dart' as import_login;

class DataProvider {
  static final BaseOptions _options = BaseOptions(
    // baseUrl: APIPath.baseUrl, // Replace with your actual base URL
    // headers: {
    //   'apikey': SecretFile.secretKey,
    //   'Authorization': 'Bearer ${SecretFile.apiAuthorizationKey}', // Replace with your actual authorization key
    // },
    sendTimeout: const Duration(milliseconds: 30000),
    receiveTimeout: const Duration(milliseconds: 30000),
  );

  final Dio _dio;

  DataProvider() : _dio = Dio(_options) {
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            // Check if we have a refresh token
            final refreshToken = await StorageService.getRefreshToken();
            if (refreshToken != null) {
              try {
                // Use a new Dio instance to avoid interceptor loops
                final refreshDio = Dio();
                final response = await refreshDio.post(
                  'https://smart-school-backend-production.up.railway.app/auth/refresh',
                  data: {'refreshToken': refreshToken},
                  options: Options(
                    headers: {
                      'accept': '*/*',
                      'Content-Type': 'application/json',
                    },
                  ),
                );

                if (response.statusCode == 200 || response.statusCode == 201) {
                  final data = response.data['data'];
                  final newAccessToken = data['accessToken'];
                  final newRefreshToken = data['refreshToken'];

                  if (newAccessToken != null) {
                    await StorageService.saveToken(newAccessToken);
                  }
                  if (newRefreshToken != null) {
                    await StorageService.saveRefreshToken(newRefreshToken);
                  }

                  // Retry the original request with the new token
                  final requestOptions = e.requestOptions;
                  if (requestOptions.headers.containsKey('Authorization')) {
                    requestOptions.headers['Authorization'] =
                        'Bearer $newAccessToken';
                  }

                  try {
                    // Use a new Dio instance to repeat the request
                    // Or use the original dio (since we are in QueuedInterceptorsWrapper, it's safe)
                    final retryResponse = await _dio.fetch(requestOptions);
                    return handler.resolve(retryResponse);
                  } catch (retryError) {
                    return handler.next(
                      retryError is DioException ? retryError : e,
                    );
                  }
                }
              } catch (refreshError) {
                log("Refresh token failed: $refreshError");
                await _handleSessionExpired();
                return handler.next(e);
              }
            } else {
              await _handleSessionExpired();
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<void> _handleSessionExpired() async {
    await StorageService.clear();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const import_login.LoginScreen(),
      ),
      (route) => false,
    );
  }

  Future<Response<dynamic>?> performRequest(
    String method,
    String url, {
    dynamic data,
    dynamic query,
    dynamic header,
  }) async {
    try {
      DateTime startTime = DateTime.now();

      Response response = await _dio.request(
        url,
        data: data,
        queryParameters: query,
        options: Options(headers: header, method: method.toUpperCase()),
      );
      DateTime endTime = DateTime.now();
      Duration diff = endTime.difference(startTime);

      if (kDebugMode) {
        log("$url: ${diff.inMilliseconds} Milliseconds");
      }

      return response;
    } on DioException catch (exception) {
      if (kDebugMode) {
        log("DioException: $exception");
        log("Dio Url: ${url}");
        log("Dio query: ${query}");
        log("Dio data: ${data}");
        log("Dio header: ${header}");
      }
      return exception.response;
    }
  }
}
