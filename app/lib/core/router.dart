import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/ui/auth_gate.dart';
import '../features/auth/ui/forgot_password_screen.dart';
import '../features/auth/ui/login_screen.dart';
import '../features/auth/ui/register_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authNotifierProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot';

      if (auth is AuthUnknown || auth is AuthLoading) return null;

      final signedIn = auth is AuthAuthenticated;
      if (!signedIn && !loggingIn && state.matchedLocation != '/') {
        return '/login';
      }
      if (signedIn && loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const AuthGate()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot', builder: (_, __) => const ForgotPasswordScreen()),
    ],
  );
});

/// Bridges Riverpod auth changes into go_router refresh.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    _ref.listen(authNotifierProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}
