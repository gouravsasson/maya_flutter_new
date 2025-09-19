// lib/core/services/deep_link_service.dart
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DeepLinkService {
  static const platform = MethodChannel('maya.ravan.ai/deeplink');
  static bool _initialized = false;

  static Future<void> initialize(BuildContext context) async {
    if (_initialized) return;
    _initialized = true;

    print('🔗 Initializing Deep Link Service...');

    // Handle app launch from deep link
    try {
      final String? initialLink = await platform.invokeMethod('getInitialLink');
      if (initialLink != null) {
        print('🚀 App launched with deep link: $initialLink');
        _handleDeepLink(context, initialLink);
      }
    } catch (e) {
      print('❌ Error getting initial link: $e');
    }

    // Handle deep links while app is running
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLink') {
        final String link = call.arguments;
        print('🔗 New deep link received: $link');
        _handleDeepLink(context, link);
      }
    });
  }

  static void _handleDeepLink(BuildContext context, String link) {
    try {
      final uri = Uri.parse(link);
      final path = uri.path;
      final params = uri.queryParameters;

      print('🎯 Handling deep link:');
      print('   Path: $path');
      print('   Params: $params');

      // Use GoRouter for navigation
      final router = GoRouter.of(context);

      // Handle different deep link paths based on your actual routes
      switch (path) {
        case '/':
        case '':
          // Go to home (will redirect to login if not authenticated)
          router.go('/home');
          break;

        case '/home':
          router.go('/home');
          break;

        case '/profile':
          router.go('/profile');
          break;

        case '/tasks':
          router.go('/tasks');
          break;

        case '/integrations':
          router.go('/integrations');
          break;

        case '/settings':
          router.go('/settings');
          break;

        case '/call_sessions':
        case '/call-sessions':
          router.go('/call_sessions');
          break;

        case '/login':
          router.go('/login');
          break;

        case '/ghl':
          router.go('/ghl');
          break;

        // Handle parameterized routes
        default:
          // Check if it's a route with parameters
          if (path.startsWith('/profile/')) {
            // For future user profile with ID
            router.go('/profile');
          } else if (path.startsWith('/tasks/')) {
            // For future task with ID
            router.go('/tasks');
          } else {
            print('⚠️  Unknown deep link path: $path');
            // Fallback to home (will redirect appropriately based on auth)
            router.go('/home');
          }
      }
    } catch (e) {
      print('❌ Error handling deep link: $e');
      // Fallback navigation
      if (context.mounted) {
        GoRouter.of(context).go('/home');
      }
    }
  }

  // Optional: Method to programmatically trigger deep links (for testing)
  static void simulateDeepLink(BuildContext context, String link) {
    print('🧪 Simulating deep link: $link');
    _handleDeepLink(context, link);
  }

  // Optional: Method to share deep links
  static String createDeepLink({
    required String path,
    Map<String, String>? params,
  }) {
    final uri = Uri(
      scheme: 'https',
      host: 'maya.ravan.ai',
      path: path,
      queryParameters: params?.isNotEmpty == true ? params : null,
    );
    return uri.toString();
  }

  // Convenience methods for your specific app routes
  static String createHomeLink() => createDeepLink(path: '/home');
  static String createProfileLink() => createDeepLink(path: '/profile');
  static String createTasksLink() => createDeepLink(path: '/tasks');
  static String createIntegrationsLink() =>
      createDeepLink(path: '/integrations');
  static String createSettingsLink() => createDeepLink(path: '/settings');
  static String createCallSessionsLink() =>
      createDeepLink(path: '/call_sessions');

  // Example with parameters (for future use)
  static String createTaskLink(String taskId) =>
      createDeepLink(path: '/tasks', params: {'id': taskId});
}
