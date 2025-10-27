import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/authentication/presentation/bloc/auth_bloc.dart';
import '../../../features/authentication/presentation/bloc/auth_event.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static BuildContext get context {
    final currentContext = navigatorKey.currentContext;
    if (currentContext == null) {
      throw StateError('Navigator context is null');
    }
    return GoRouter.of(currentContext).routerDelegate.navigatorKey.currentContext!;
  }

  static void go(String location) {
    final currentContext = navigatorKey.currentContext;
    print('🔑 NavigationService: go (replace): $location');
    if (currentContext != null) {
      GoRouter.of(currentContext).go(location);
    }
  }

  static void push(String location) {
    final currentContext = navigatorKey.currentContext;
    print('🔑 NavigationService: push (stack): $location');
    if (currentContext != null) {
      GoRouter.of(currentContext).push(location);
    }
  }

  static void pushReplacement(String location) {
    final currentContext = navigatorKey.currentContext;
    print('🔑 NavigationService: pushReplacement: $location');
    if (currentContext != null) {
      GoRouter.of(currentContext).pushReplacement(location);
    }
  }

  static void pop() {
    final currentContext = navigatorKey.currentContext;
    print('🔑 NavigationService: pop');
    if (currentContext != null && GoRouter.of(currentContext).canPop()) {
      GoRouter.of(currentContext).pop();
    } else if (currentContext != null) {
      final currentPath = GoRouterState.of(currentContext).uri.path;
      if (currentPath != '/home') {
        GoRouter.of(currentContext).go('/home');
      } else {
        Navigator.of(currentContext).maybePop();
      }
    }
  }

  static void showSnackBar(String message, {bool isError = false}) {
    final currentContext = navigatorKey.currentContext;
    print('🔑 NavigationService: showSnackBar: $message');
    if (currentContext != null) {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  static void showSessionExpiredDialog() {
    final currentContext = navigatorKey.currentContext;
    print('🔑 NavigationService: showSessionExpiredDialog');
    if (currentContext != null) {
      showDialog(
        context: currentContext,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Session Expired'),
            ],
          ),
          content: const Text(
            'Your session has expired. Please login again to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthBloc>().add(LogoutRequested());
              },
              child: const Text('Login Again'),
            ),
          ],
        ),
      );
    }
  }
}