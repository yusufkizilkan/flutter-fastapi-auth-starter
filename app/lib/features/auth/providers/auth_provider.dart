import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/secure_storage.dart';
import '../data/auth_api.dart';
import '../data/auth_repository.dart';
import '../data/models.dart';

/// Breaks the ApiClient ↔ AuthNotifier cycle: client calls [notify], notifier listens.
class SessionExpiredBridge {
  void Function()? _handler;

  void bind(void Function() handler) => _handler = handler;

  void notify() => _handler?.call();
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final sessionExpiredBridgeProvider = Provider<SessionExpiredBridge>((ref) {
  return SessionExpiredBridge();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final bridge = ref.watch(sessionExpiredBridgeProvider);
  return ApiClient(
    storage: ref.watch(tokenStorageProvider),
    onSessionExpired: bridge.notify,
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = AuthApi(ref.watch(apiClientProvider));
  return AuthRepository(
    api: api,
    storage: ref.watch(tokenStorageProvider),
  );
});

sealed class AuthState {
  const AuthState();
}

class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final AuthUser user;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.message});
  final String? message;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo, SessionExpiredBridge bridge) : super(const AuthUnknown()) {
    bridge.bind(forceLogout);
    _bootstrap();
  }

  final AuthRepository _repo;

  Future<void> _bootstrap() async {
    state = const AuthLoading();
    final user = await _repo.restoreSession();
    state = user == null
        ? const AuthUnauthenticated()
        : AuthAuthenticated(user);
  }

  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    try {
      final user = await _repo.login(email: email, password: password);
      state = AuthAuthenticated(user);
    } on AuthException catch (e) {
      state = AuthUnauthenticated(message: e.message);
    } catch (_) {
      state = const AuthUnauthenticated(message: 'Unexpected error');
    }
  }

  Future<void> register(String email, String password, {String? fullName}) async {
    state = const AuthLoading();
    try {
      final user = await _repo.register(
        email: email,
        password: password,
        fullName: fullName,
      );
      state = AuthAuthenticated(user);
    } on AuthException catch (e) {
      state = AuthUnauthenticated(message: e.message);
    } catch (_) {
      state = const AuthUnauthenticated(message: 'Unexpected error');
    }
  }

  Future<void> google() async {
    state = const AuthLoading();
    try {
      final user = await _repo.signInWithGoogle();
      state = AuthAuthenticated(user);
    } on AuthException catch (e) {
      state = AuthUnauthenticated(message: e.message);
    } catch (_) {
      state = const AuthUnauthenticated(message: 'Unexpected error');
    }
  }

  Future<String?> forgotPassword(String email) async {
    try {
      await _repo.forgotPassword(email);
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthUnauthenticated();
  }

  void forceLogout() {
    state = const AuthUnauthenticated(
      message: 'Session expired. Please sign in again.',
    );
  }

  void clearMessage() {
    if (state is AuthUnauthenticated) {
      state = const AuthUnauthenticated();
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(sessionExpiredBridgeProvider),
  );
});
