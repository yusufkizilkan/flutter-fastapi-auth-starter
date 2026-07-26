import 'package:dio/dio.dart';

import 'app_config.dart';
import 'secure_storage.dart';

/// Dio client with Authorization header + one-shot refresh on 401.
class ApiClient {
  ApiClient({
    required TokenStorage storage,
    void Function()? onSessionExpired,
    Dio? dio,
  })  : _storage = storage,
        _onSessionExpired = onSessionExpired {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBase,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 20),
            headers: {
              Headers.contentTypeHeader: Headers.jsonContentType,
              Headers.acceptHeader: Headers.jsonContentType,
            },
          ),
        );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode != 401 ||
              error.requestOptions.extra['retried'] == true) {
            return handler.next(error);
          }
          final refreshed = await _tryRefresh();
          if (!refreshed) {
            _onSessionExpired?.call();
            return handler.next(error);
          }
          final req = error.requestOptions;
          req.extra['retried'] = true;
          final token = await _storage.readAccessToken();
          req.headers['Authorization'] = 'Bearer $token';
          try {
            final response = await _dio.fetch(req);
            return handler.resolve(response);
          } on DioException catch (e) {
            return handler.next(e);
          }
        },
      ),
    );
  }

  late final Dio _dio;
  final TokenStorage _storage;
  final void Function()? _onSessionExpired;
  bool _refreshing = false;

  Dio get dio => _dio;

  /// Public Dio without auth interceptor side-effects for login/register.
  Dio bare() => Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBase,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          headers: {
            Headers.contentTypeHeader: Headers.jsonContentType,
            Headers.acceptHeader: Headers.jsonContentType,
          },
        ),
      );

  Future<bool> _tryRefresh() async {
    if (_refreshing) return false;
    _refreshing = true;
    try {
      final refresh = await _storage.readRefreshToken();
      if (refresh == null || refresh.isEmpty) return false;
      final resp = await bare().post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refresh},
      );
      final data = resp.data;
      if (data == null) return false;
      await _storage.saveTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
      );
      return true;
    } catch (_) {
      await _storage.clear();
      return false;
    } finally {
      _refreshing = false;
    }
  }
}
