import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/authentication/presentation/bloc/auth_bloc.dart';
import '../../features/authentication/presentation/bloc/auth_event.dart';

/// Instance-based NavigationService intended to be registered in GetIt.
/// Use sl<NavigationService>() to access it from anywhere.
class NavigationService {
  /// Root navigator key (shared with GoRouter)
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  NavigationService();

  /// Get router by resolving it from the current context (root key must be assigned to GoRouter).
  GoRouter? _routerFromContext() {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return null;
    return GoRouter.of(ctx);
  }

  // ----------------- Navigation API (instance methods) ----------------- //

  void go(String location, {Object? extra}) {
    try {
      final router = _routerFromContext();
      if (router == null) {
        debugPrint('NavigationService.go: router not ready yet');
        return;
      }
      router.go(location, extra: extra);
    } catch (e, st) {
      debugPrint('NavigationService.go failed: $e\n$st');
    }
  }

  void push(String location, {Object? extra}) {
    try {
      final router = _routerFromContext();
      if (router == null) {
        debugPrint('NavigationService.push: router not ready yet');
        return;
      }
      router.push(location, extra: extra);
    } catch (e, st) {
      debugPrint('NavigationService.push failed: $e\n$st');
    }
  }

  void pushReplacement(String location, {Object? extra}) {
    try {
      final router = _routerFromContext();
      if (router == null) {
        debugPrint('NavigationService.pushReplacement: router not ready yet');
        return;
      }
      router.pushReplacement(location, extra: extra);
    } catch (e, st) {
      debugPrint('NavigationService.pushReplacement failed: $e\n$st');
    }
  }

  /// Shell-aware pop. If a local nested navigator can pop, it will.
  /// If nothing to pop, fallback goes to '/home'.
  void pop([BuildContext? context]) {
    try {
      final ctx = context ?? navigatorKey.currentContext;
      if (ctx == null) {
        debugPrint('NavigationService.pop: no context available');
        return;
      }

      final router = GoRouter.of(ctx);
      if (router.canPop()) {
        router.pop();
      } else {
        router.go('/home');
      }
    } catch (e, st) {
      debugPrint('NavigationService.pop failed: $e\n$st');
    }
  }

  // ----------------- Utilities ----------------- //

  void showSnackBar(String message, {bool isError = false}) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) {
      debugPrint('NavigationService.showSnackBar: no context');
      return;
    }
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void showSessionExpiredDialog() {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) {
      debugPrint('NavigationService.showSessionExpiredDialog: no context');
      return;
    }

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Session Expired'),
          ],
        ),
        content: const Text('Your session has expired. Please login again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              // use Bloc from dialog context to trigger logout
              dialogCtx.read<AuthBloc>().add(LogoutRequested());
            },
            child: const Text('Login Again'),
          ),
        ],
      ),
    );
  }
}
