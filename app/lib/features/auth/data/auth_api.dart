import 'package:dio/dio.dart';

import '../../../core/api_client.dart';
import 'models.dart';

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<AuthTokens> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    return _postTokens(
      '/auth/register',
      {
        'email': email,
        'password': password,
        if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
      },
    );
  }

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    return _postTokens('/auth/login', {
      'email': email,
      'password': password,
    });
  }

  Future<AuthTokens> google({required String idToken}) async {
    return _postTokens('/auth/google', {'id_token': idToken});
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _client.bare().post('/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<AuthUser> me() async {
    try {
      final resp = await _client.dio.get<Map<String, dynamic>>('/auth/me');
      return AuthUser.fromJson(resp.data!);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<AuthTokens> _postTokens(String path, Map<String, dynamic> body) async {
    try {
      final resp = await _client.bare().post<Map<String, dynamic>>(path, data: body);
      return AuthTokens.fromJson(resp.data!);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  AuthException _mapError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return AuthException('Could not reach the server. Is the API running?');
    }
    final data = e.response?.data;
    String message = 'Something went wrong';
    if (data is Map && data['detail'] != null) {
      final detail = data['detail'];
      if (detail is String) {
        message = detail;
      } else if (detail is List && detail.isNotEmpty) {
        message = detail.first.toString();
      }
    }
    return AuthException(message, statusCode: e.response?.statusCode);
  }
}
