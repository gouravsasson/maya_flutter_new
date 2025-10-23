import 'package:Maya/core/services/navigation_service.dart';
import 'package:Maya/features/authentication/presentation/pages/other_page.dart';
import 'package:Maya/features/authentication/presentation/pages/settings_page.dart';
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
import 'package:Maya/features/authentication/presentation/pages/generations_page.dart';
import 'package:Maya/features/authentication/presentation/pages/todos_page.dart';
import 'package:Maya/features/authentication/presentation/pages/reminders_page.dart';
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
  static const String other = '/other';
  static const String generations = '/generations';
  static const String todos = '/todos';
  static const String reminders = '/reminders';

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
        // Profile route (stack navigation)
        GoRoute(
          path: profile,
          name: 'profile',
          builder: (BuildContext context, GoRouterState state) {
            return ProfilePage();
          },
        ),
        // Call Sessions route (stack navigation)
        GoRoute(
          path: call_sessions,
          name: 'call_sessions',
          builder: (BuildContext context, GoRouterState state) {
            return CallSessionsPage();
          },
        ),
        // Task Detail route (stack navigation)
        GoRoute(
          path: taskDetail,
          name: 'task_detail',
          builder: (BuildContext context, GoRouterState state) {
            final taskId = state.pathParameters['taskId']!;
            return TaskDetailPage(
              sessionId: taskId,
              apiClient: ApiClient(Dio(), Dio()),
              taskQuery: '',
            );
          },
        ),
        // GHL WebView route (stack navigation)
        GoRoute(
          path: '/ghl',
          builder: (context, state) => const GhlWebViewPage(),
        ),
        // Integrations route (stack navigation)
        GoRoute(
          path: integrations,
          name: 'integrations',
          builder: (BuildContext context, GoRouterState state) {
            return IntegrationsPage();
          },
        ),
        // Generations route (stack navigation)
        GoRoute(
          path: generations,
          name: 'generations',
          builder: (BuildContext context, GoRouterState state) {
            return GenerationsPage();
          },
        ),
        // Todos route (stack navigation)
        GoRoute(
          path: todos,
          name: 'todos',
          builder: (BuildContext context, GoRouterState state) {
            return TodosPage();
          },
        ),
        // Reminders route (stack navigation)
        GoRoute(
          path: reminders,
          name: 'reminders',
          builder: (BuildContext context, GoRouterState state) {
            return RemindersPage();
          },
        ),
        // Shell route for tabbed routes (home, tasks, maya, settings, other)
        ShellRoute(
          navigatorKey: GlobalKey<NavigatorState>(),
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
              path: settings,
              name: 'settings',
              builder: (BuildContext context, GoRouterState state) {
                return SettingsPage();
              },
            ),
            GoRoute(
              path: other,
              name: 'other',
              builder: (BuildContext context, GoRouterState state) {
                return OtherPage();
              },
            ),
          ],
          redirect: (BuildContext context, GoRouterState state) {
            final currentLocation = state.uri.path;
            final tabRoutes = [home, tasks, maya, settings, other];

            // If back button is pressed (popping from a tab route), redirect to home
            if (tabRoutes.contains(currentLocation) && currentLocation != home) {
              if (state.popped) {
                print('   Back button pressed in tab route, redirecting to HOME');
                return home;
              }
            }
            return null;
          },
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
      maya,
      other,
      generations,
      todos,
      reminders,
    ];
    return protectedRoutes.contains(location) || location.startsWith('/tasks/');
  }
}