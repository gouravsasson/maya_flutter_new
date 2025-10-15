import 'package:Maya/core/services/navigation_service.dart';
import 'package:Maya/features/widgets/talk_to_maya.dart';
import 'package:Maya/features/widgets/task_detail.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:Maya/features/authentication/presentation/pages/call_sessions.dart';
import 'package:Maya/features/authentication/presentation/pages/integration_page.dart';
import 'package:Maya/features/authentication/presentation/pages/tasks_page.dart';
import 'package:Maya/features/widgets/ghl.dart';
import 'package:Maya/utils/tab_layout.dart';
import '../../features/authentication/presentation/bloc/auth_bloc.dart';
import '../../features/authentication/presentation/bloc/auth_state.dart';
import '../../features/authentication/presentation/pages/splash_page.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/home_page.dart';
import '../../features/authentication/presentation/pages/profile_page.dart';
import '../../core/network/api_client.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String tasks = '/tasks';
  static const String taskDetail = '/tasks/:taskId';
  static const String integrations = '/integrations';
  static const String settings = '/settings';
  static const String call_sessions = '/call_sessions';
  static const String maya = '/maya';

  static final ValueNotifier<AuthState> authStateNotifier = ValueNotifier(
    AuthInitial(),
  );

  static GoRouter createRouter(AuthBloc authBloc) {
    print('AppRouter: Using AuthBloc instance: ${authBloc.hashCode}');

    // Set initial state
    authStateNotifier.value = authBloc.state;

    // Listen to auth bloc changes and update the notifier
    authBloc.stream.listen((state) {
      print('AppRouter: Auth state stream update: ${state.runtimeType}');
      authStateNotifier.value = state;
    });

    return GoRouter(
      navigatorKey: NavigationService.navigatorKey,
      initialLocation: splash,
      debugLogDiagnostics: true,
      refreshListenable: authStateNotifier,
      redirect: (BuildContext context, GoRouterState state) {
        final authState = authStateNotifier.value;
        final isLoggedIn = authState is AuthAuthenticated;
        final isLoading = authState is AuthLoading || authState is AuthInitial;
        final currentLocation = state.uri.path;

        print('GoRouter Redirect:');
        print('   Current State: ${authState.runtimeType}');
        print('   Current Location: $currentLocation');
        print('   Is Logged In: $isLoggedIn');
        print('   Is Loading: $isLoading');

        if (isLoading) {
          print('   Staying on splash (loading)');
          return currentLocation == splash ? null : splash;
        }

        if (isLoggedIn) {
          if (currentLocation == login || currentLocation == splash) {
            print('   Redirecting to HOME (authenticated)');
            return home;
          }
          print('   Staying on current protected route');
          return null;
        }

        if (!isLoggedIn && !isLoading) {
          if (_isProtectedRoute(currentLocation)) {
            print('   Redirecting to LOGIN (unauthenticated)');
            return login;
          }
          if (currentLocation == splash) {
            print('   Redirecting to LOGIN from splash');
            return login;
          }
        }

        print('   No redirect needed');
        return null;
      },
      routes: [
        // Authentication routes (no persistent navigation)
        GoRoute(
          path: splash,
          name: 'splash',
          builder: (BuildContext context, GoRouterState state) {
            return SplashPage();
          },
        ),
        GoRoute(
          path: login,
          name: 'login',
          builder: (BuildContext context, GoRouterState state) {
            return LoginPage();
          },
        ),
        // Profile route (outside ShellRoute for stack navigation)
        GoRoute(
          path: profile,
          name: 'profile',
          builder: (BuildContext context, GoRouterState state) {
            return ProfilePage();
          },
        ),
        // Call Sessions route (outside ShellRoute for stack navigation)
        GoRoute(
          path: call_sessions,
          name: 'call_sessions',
          builder: (BuildContext context, GoRouterState state) {
            return CallSessionsPage();
          },
        ),
        // Task Detail route
        GoRoute(
          path: taskDetail,
          name: 'task_detail',
          builder: (BuildContext context, GoRouterState state) {
            final taskId = state.pathParameters['taskId']!;
            return TaskDetailPage(
              sessionId: taskId,
              apiClient: ApiClient(Dio(), Dio()),
            );
          },
        ),
        // GHL WebView route
        GoRoute(
          path: '/ghl',
          builder: (context, state) => const GhlWebViewPage(),
        ),
        // Shell route for main app (with persistent navigation)
        ShellRoute(
          builder: (context, state, child) {
            return TabLayout(child: child);
          },
          routes: [
            GoRoute(
              path: home,
              name: 'home',
              builder: (BuildContext context, GoRouterState state) {
                return HomePage();
              },
            ),
            GoRoute(
              path: tasks,
              name: 'tasks',
              builder: (BuildContext context, GoRouterState state) {
                return TasksPage();
              },
            ),
            GoRoute(
              path: maya,
              name: 'maya',
              builder: (BuildContext context, GoRouterState state) {
                return TalkToMaya();
              },
            ),
            GoRoute(
              path: integrations,
              name: 'integrations',
              builder: (BuildContext context, GoRouterState state) {
                return IntegrationsPage();
              },
            ),
            GoRoute(
              path: settings,
              name: 'settings',
              builder: (BuildContext context, GoRouterState state) {
                return Scaffold(
                  body: Center(child: Text('Settings Page')),
                ); // Replace with actual SettingsPage
              },
            ),
          ],
        ),
      ],
    );
  }

  static bool _isProtectedRoute(String location) {
    final protectedRoutes = [
      home,
      profile,
      tasks,
      taskDetail,
      integrations,
      settings,
      call_sessions,
    ];
    return protectedRoutes.contains(location) || location.startsWith('/tasks/');
  }
}