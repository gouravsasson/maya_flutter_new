import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:Maya/core/network/api_client.dart';
import 'package:Maya/core/services/navigation_service.dart';
import 'package:Maya/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:Maya/features/authentication/presentation/bloc/auth_state.dart';
import 'package:Maya/features/authentication/presentation/pages/call_sessions.dart';
import 'package:Maya/features/authentication/presentation/pages/generations_page.dart';
import 'package:Maya/features/authentication/presentation/pages/home_page.dart';
import 'package:Maya/features/authentication/presentation/pages/integration_page.dart';
import 'package:Maya/features/authentication/presentation/pages/login_page.dart';
import 'package:Maya/features/authentication/presentation/pages/other_page.dart';
import 'package:Maya/features/authentication/presentation/pages/profile_page.dart';
import 'package:Maya/features/authentication/presentation/pages/reminders_page.dart';
import 'package:Maya/features/authentication/presentation/pages/settings_page.dart';
import 'package:Maya/features/authentication/presentation/pages/splash_page.dart';
import 'package:Maya/features/authentication/presentation/pages/tasks_page.dart';
import 'package:Maya/features/authentication/presentation/pages/todos_page.dart';
import 'package:Maya/features/widgets/ghl.dart';
import 'package:Maya/features/widgets/talk_to_maya.dart';
import 'package:Maya/features/widgets/task_detail.dart';
import 'package:Maya/utils/tab_layout.dart';
import 'package:dio/dio.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String tasks = '/tasks';
  static const String taskDetail = '/tasks/:taskId';
  static const String integrations = '/integrations';
  static const String settings = '/settings';
  static const String callSessions = '/call_sessions';
  static const String maya = '/maya';
  static const String other = '/other';
  static const String generations = '/generations';
  static const String todos = '/todos';
  static const String reminders = '/reminders';
  static const String ghl = '/ghl';

  static final ValueNotifier<AuthState> authStateNotifier =
      ValueNotifier(AuthInitial());

  static GoRouter createRouter(AuthBloc authBloc) {
    print('AppRouter: Using AuthBloc instance: ${authBloc.hashCode}');

    authStateNotifier.value = authBloc.state;

    authBloc.stream.listen((state) {
      print('AppRouter: Auth state stream update: ${state.runtimeType}');
      authStateNotifier.value = state;

      // Handle session expiration
      if (state is AuthUnauthenticated) {
        print('AppRouter: Session expired, showing dialog');
        NavigationService.showSessionExpiredDialog();
      }
    });

    return GoRouter(
      navigatorKey: NavigationService.navigatorKey,
      initialLocation: splash,
      debugLogDiagnostics: true,
      refreshListenable: authStateNotifier,
      redirect: (BuildContext context, GoRouterState state) async {
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
        GoRoute(
          path: splash,
          name: 'splash',
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: login,
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: profile,
          name: 'profile',
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: callSessions,
          name: 'call_sessions',
          builder: (context, state) => const CallSessionsPage(),
        ),
        GoRoute(
          path: ghl,
          name: 'ghl',
          builder: (context, state) => const GhlWebViewPage(),
        ),
        ShellRoute(
          builder: (context, state, child) => TabLayout(child: child),
          routes: [
            GoRoute(
              path: home,
              name: 'home',
              builder: (context, state) => const HomePage(),
            ),
            GoRoute(
              path: tasks,
              name: 'tasks',
              builder: (context, state) => const TasksPage(),
              routes: [
                GoRoute(
                  path: ':taskId',
                  name: 'task_detail',
                  builder: (context, state) {
                    final taskId = state.pathParameters['taskId']!;
                    return TaskDetailPage(
                      sessionId: taskId,
                      apiClient: ApiClient(Dio(), Dio()),
                      taskQuery: '',
                    );
                  },
                ),
              ],
            ),
            GoRoute(
              path: integrations,
              name: 'integrations',
              builder: (context, state) => const IntegrationsPage(),
            ),
            GoRoute(
              path: settings,
              name: 'settings',
              builder: (context, state) => const SettingsPage(),
            ),
            GoRoute(
              path: maya,
              name: 'maya',
              builder: (context, state) => const TalkToMaya(),
            ),
            GoRoute(
              path: other,
              name: 'other',
              builder: (context, state) => const OtherPage(),
            ),
            GoRoute(
              path: generations,
              name: 'generations',
              builder: (context, state) => const GenerationsPage(),
            ),
            GoRoute(
              path: todos,
              name: 'todos',
              builder: (context, state) => const TodosPage(),
            ),
            GoRoute(
              path: reminders,
              name: 'reminders',
              builder: (context, state) => const RemindersPage(),
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
      integrations,
      settings,
      callSessions,
      maya,
      other,
      generations,
      todos,
      reminders,
    ];
    return protectedRoutes.contains(location) || location.startsWith('/tasks/');
  }
}