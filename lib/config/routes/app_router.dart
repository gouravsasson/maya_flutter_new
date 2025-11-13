import 'package:Maya/core/services/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../features/authentication/presentation/bloc/auth_bloc.dart';
import '../../features/authentication/presentation/bloc/auth_state.dart';
import '../../features/authentication/presentation/pages/splash_page.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/home_page.dart';
import '../../features/authentication/presentation/pages/tasks_page.dart';
import '../../features/authentication/presentation/pages/settings_page.dart';
import '../../features/authentication/presentation/pages/other_page.dart';
import '../../features/authentication/presentation/pages/profile_page.dart';
import '../../features/authentication/presentation/pages/call_sessions.dart';
import '../../features/authentication/presentation/pages/integration_page.dart';
import '../../features/authentication/presentation/pages/generations_page.dart';
import '../../features/authentication/presentation/pages/todos_page.dart';
import '../../features/authentication/presentation/pages/reminders_page.dart';
import '../../features/widgets/talk_to_maya.dart';
import '../../features/widgets/ghl.dart';
import '../../features/widgets/task_detail.dart';
import '../../utils/tab_layout.dart';
import '../../core/network/api_client.dart';

class AppRouter {
  final NavigationService navigationService;
  final ValueNotifier<AuthState> authStateNotifier = ValueNotifier(
    AuthInitial(),
  );

  AppRouter({required this.navigationService});

  GoRouter createRouter(AuthBloc authBloc) {
    // keep auth notifier in sync
    authStateNotifier.value = authBloc.state;
    authBloc.stream.listen((s) {
      authStateNotifier.value = s;
    });

    // per-tab navigators
    final homeKey = GlobalKey<NavigatorState>();
    final tasksKey = GlobalKey<NavigatorState>();
    final mayaKey = GlobalKey<NavigatorState>();
    final settingsKey = GlobalKey<NavigatorState>();
    final otherKey = GlobalKey<NavigatorState>();

    return GoRouter(
      navigatorKey: navigationService.navigatorKey,
      initialLocation: '/',
      refreshListenable: authStateNotifier,
      debugLogDiagnostics: true,
      routes: [
        // Root-level auth routes
        GoRoute(
          path: '/',
          parentNavigatorKey: navigationService.navigatorKey,
          builder: (_, __) => const SplashPage(),
        ),
        GoRoute(
          path: '/login',
          parentNavigatorKey: navigationService.navigatorKey,
          builder: (_, __) => const LoginPage(),
        ),

        // Tabs
        ShellRoute(
          navigatorKey: homeKey,
          builder: (_, __, child) => TabLayout(currentIndex: 0, child: child),
          routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (_, __) => const NoTransitionPage(child: HomePage()),
            ),
          ],
        ),
        ShellRoute(
          navigatorKey: tasksKey,
          builder: (_, __, child) => TabLayout(currentIndex: 1, child: child),
          routes: [
            GoRoute(
              path: '/tasks',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: TasksPage()),
            ),
          ],
        ),
        ShellRoute(
          navigatorKey: mayaKey,
          builder: (_, __, child) => TabLayout(currentIndex: 2, child: child),
          routes: [
            GoRoute(
              path: '/maya',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: TalkToMaya()),
            ),
          ],
        ),
        ShellRoute(
          navigatorKey: settingsKey,
          builder: (_, __, child) => TabLayout(currentIndex: 3, child: child),
          routes: [
            GoRoute(
              path: '/settings',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: SettingsPage()),
            ),
          ],
        ),
        ShellRoute(
          navigatorKey: otherKey,
          builder: (_, __, child) => TabLayout(currentIndex: 4, child: child),
          routes: [
            GoRoute(
              path: '/other',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: OtherPage()),
            ),
          ],
        ),

        // Standalone pages (above shell)
        GoRoute(
          path: '/tasks/:taskId',
          parentNavigatorKey: navigationService.navigatorKey,
          builder: (_, state) => TaskDetailPage(
            sessionId: state.pathParameters['taskId']!,
            apiClient: ApiClient(Dio(), Dio()),
            taskQuery: '',
          ),
        ),
        GoRoute(
          path: '/profile',
          parentNavigatorKey: navigationService.navigatorKey,
          builder: (_, __) => const ProfilePage(),
        ),
        GoRoute(
          path: '/integrations',
          parentNavigatorKey: navigationService.navigatorKey,
          builder: (_, __) => const IntegrationsPage(),
        ),
        GoRoute(
          path: '/call_sessions',
          parentNavigatorKey: navigationService.navigatorKey,
          builder: (_, __) => const CallSessionsPage(),
        ),
        GoRoute(
          path: '/ghl',
          parentNavigatorKey: navigationService.navigatorKey,
          builder: (_, __) => const GhlWebViewPage(),
        ),
        GoRoute(
          path: '/generations',
          parentNavigatorKey: navigationService.navigatorKey,
          builder: (_, __) => const GenerationsPage(),
        ),
        GoRoute(
          path: '/todos',
          parentNavigatorKey: navigationService.navigatorKey,
          builder: (_, __) => const TodosPage(),
        ),
        GoRoute(
          path: '/reminders',
          parentNavigatorKey: navigationService.navigatorKey,
          builder: (_, __) => const RemindersPage(),
        ),
      ],

      // 🔥 Smart redirect logic
      redirect: (context, state) {
        final auth = authStateNotifier.value;
        final loc = state.uri.path;

        final isAuthed = auth is AuthAuthenticated;
        final isLoading = auth is AuthLoading || auth is AuthInitial;

        // 1) While loading: stay only on splash
        if (isLoading) {
          return loc == '/' ? null : '/';
        }

        // 2) Unauthenticated users:
        if (!isAuthed) {
          // allow login
          if (loc == '/login') return null;

          // force login for everything else
          return '/login';
        }

        // 3) Authenticated users:
        // block splash and login
        if (loc == '/' || loc == '/login') {
          return '/home';
        }

        // 4) Authenticated fallback:
        // if user somehow reaches an unknown route → go home (NOT login)
        return null;
      },
    );
  }

  static bool _isProtected(String loc) {
    const protectedRoutes = [
      '/home',
      '/tasks',
      '/maya',
      '/settings',
      '/other',
      '/profile',
      '/integrations',
      '/call_sessions',
      '/ghl',
      '/generations',
      '/todos',
      '/reminders',
    ];
    return protectedRoutes.any((r) => loc.startsWith(r));
  }
}
