import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationService {
  // Get current context from GoRouter

  static BuildContext get context => GoRouter.of(
    navigatorKey.currentContext!,
  ).routerDelegate.navigatorKey.currentContext!;

  // Navigator key for global access
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Navigation methods using GoRouter
  static void go(String location) {
    final currentContext = navigatorKey.currentContext;
    print('🔑 NavigationService: go: $location');
    if (currentContext != null) {
      currentContext.go(location);
    }
  }

  static void push(String location) {
    final currentContext = navigatorKey.currentContext;
    if (currentContext != null) {
      currentContext.push(location);
    }
  }

  static void pushReplacement(String location) {
    final currentContext = navigatorKey.currentContext;
    if (currentContext != null) {
      currentContext.pushReplacement(location);
    }
  }

  static void pop() {
    final currentContext = navigatorKey.currentContext;
    if (currentContext != null) {
      currentContext.pop();
    }
  }

  // Utility methods
  static void showSnackBar(String message, {bool isError = false}) {
    final currentContext = navigatorKey.currentContext;
    print('🔑 NavigationService: context: $currentContext');
    if (currentContext != null) {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  static void showSessionExpiredDialog() {
    final currentContext = navigatorKey.currentContext;
    if (currentContext != null) {
      showDialog(
        context: currentContext,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Session Expired'),
            ],
          ),
          content: Text(
            'Your session has expired. Please login again to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/login');
              },
              child: Text('Login Again'),
            ),
          ],
        ),
      );
    }
  }
}
