import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_service.dart';
import '../core/providers/providers.dart';
import '../features/admin/admin_shell.dart';
import '../features/login/login_screen.dart';
import '../features/parent/parent_shell.dart';
import '../features/role_select/role_select_screen.dart';
import '../features/splash/splash_screen.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/role-select', builder: (_, __) => const RoleSelectScreen()),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final role = state.uri.queryParameters['role'] ?? 'admin';
          return LoginScreen(role: role);
        },
      ),
      GoRoute(path: '/admin', builder: (_, __) => const AdminShell()),
      GoRoute(path: '/parent', builder: (_, __) => const ParentShell()),
    ],
    redirect: (context, state) => null,
  );
}

class AuthGuard {
  static Future<String?> check(GoRouterState state, AuthService auth) async {
    final session = await auth.loadSession();
    final loc = state.matchedLocation;
    final public = {'/', '/role-select', '/login'};

    if (public.contains(loc)) return null;

    if (!session.isAuthenticated) {
      return '/role-select';
    }

    if (loc.startsWith('/admin') && session.role != UserRole.admin) {
      return '/parent';
    }
    if (loc.startsWith('/parent') && session.role != UserRole.parent) {
      return '/admin';
    }
    return null;
  }
}
