import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/app_config.dart';
import '../../../core/secure_storage.dart';
import 'auth_api.dart';
import 'models.dart';

class AuthRepository {
  AuthRepository({
    required AuthApi api,
    required TokenStorage storage,
    GoogleSignIn? googleSignIn,
  })  : _api = api,
        _storage = storage,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email', 'profile'],
              serverClientId: AppConfig.googleClientId.isEmpty
                  ? null
                  : AppConfig.googleClientId,
            );

  final AuthApi _api;
  final TokenStorage _storage;
  final GoogleSignIn _googleSignIn;

  Future<AuthUser?> restoreSession() async {
    final access = await _storage.readAccessToken();
    if (access == null) return null;
    try {
      return await _api.me();
    } catch (_) {
      await _storage.clear();
      return null;
    }
  }

  Future<AuthUser> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final tokens = await _api.register(
      email: email,
      password: password,
      fullName: fullName,
    );
    await _storage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    return _api.me();
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final tokens = await _api.login(email: email, password: password);
    await _storage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    return _api.me();
  }

  Future<AuthUser> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw AuthException('Google sign-in cancelled');
    }
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw AuthException(
        'Missing Google ID token. Check GOOGLE_CLIENT_ID / SHA-1 setup.',
      );
    }
    final tokens = await _api.google(idToken: idToken);
    await _storage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    return _api.me();
  }

  Future<void> forgotPassword(String email) => _api.forgotPassword(email);

  Future<void> logout() async {
    await _storage.clear();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
