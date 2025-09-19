import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:Maya/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/authentication/presentation/bloc/auth_event.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // final StorageService _storageService = sl<StorageService>();

  static BuildContext get context => GoRouter.of(
    navigatorKey.currentContext!,
  ).routerDelegate.navigatorKey.currentContext!;

  static void go(String location) {
    final currentContext = navigatorKey.currentContext;
    print('🔑 NavigationService: go (replace): $location');
    if (currentContext != null) {
      currentContext.go(location);
    }
  }

  static void push(String location) {
    final currentContext = navigatorKey.currentContext;
    print('🔑 NavigationService: push (stack): $location');
    if (currentContext != null) {
      currentContext.push(location);
    }
  }

  static void pushReplacement(String location) {
    final currentContext = navigatorKey.currentContext;
    print('🔑 NavigationService: pushReplacement: $location');
    if (currentContext != null) {
      currentContext.pushReplacement(location);
    }
  }

  static void pop() {
    final currentContext = navigatorKey.currentContext;
    print('🔑 NavigationService: pop');
    if (currentContext != null) {
      currentContext.pop();
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
          duration: Duration(seconds: 3),
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
                NavigationService.pop(); // Close dialog

                context.read<AuthBloc>().add(LogoutRequested());
              },
              child: Text('Login Again'),
            ),
          ],
        ),
      );
    }
  }
}
