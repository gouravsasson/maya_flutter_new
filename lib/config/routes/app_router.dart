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
  final ValueNotifier<AuthState> authStateNotifier = ValueNotifier(AuthInitial());

  AppRouter({required this.navigationService});

  GoRouter createRouter(AuthBloc authBloc) {
    // keep auth notifier in sync
    authStateNotifier.value = authBloc.state;
    authBloc.stream.listen((s) => authStateNotifier.value = s);

    // shell keys for per-tab navigator stacks
    final homeKey = GlobalKey<NavigatorState>();
    final tasksKey = GlobalKey<NavigatorState>();
    final mayaKey = GlobalKey<NavigatorState>();
    final settingsKey = GlobalKey<NavigatorState>();
    final otherKey = GlobalKey<NavigatorState>();

    return GoRouter(
      navigatorKey: navigationService.navigatorKey, // == root key
      initialLocation: '/',
      refreshListenable: authStateNotifier,
      debugLogDiagnostics: true,
      routes: [
        // root-level auth routes
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

        // ShellRoutes for each tab (each tab has its own nested navigator key)
        ShellRoute(
          navigatorKey: homeKey,
          builder: (context, state, child) => TabLayout(currentIndex: 0, child: child),
          routes: [
            GoRoute(path: '/home', pageBuilder: (_, __) => const NoTransitionPage(child: HomePage())),
          ],
        ),

        ShellRoute(
          navigatorKey: tasksKey,
          builder: (context, state, child) => TabLayout(currentIndex: 1, child: child),
          routes: [
            GoRoute(path: '/tasks', pageBuilder: (_, __) => const NoTransitionPage(child: TasksPage())),
          ],
        ),

        ShellRoute(
          navigatorKey: mayaKey,
          builder: (context, state, child) => TabLayout(currentIndex: 2, child: child),
          routes: [
            GoRoute(path: '/maya', pageBuilder: (_, __) => const NoTransitionPage(child: TalkToMaya())),
          ],
        ),

        ShellRoute(
          navigatorKey: settingsKey,
          builder: (context, state, child) => TabLayout(currentIndex: 3, child: child),
          routes: [
            GoRoute(path: '/settings', pageBuilder: (_, __) => const NoTransitionPage(child: SettingsPage())),
          ],
        ),

        ShellRoute(
          navigatorKey: otherKey,
          builder: (context, state, child) => TabLayout(currentIndex: 4, child: child),
          routes: [
            GoRoute(path: '/other', pageBuilder: (_, __) => const NoTransitionPage(child: OtherPage())),
          ],
        ),

        // Root-level detail pages (displayed above shell)
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
      redirect: (context, state) {
        final authed = authStateNotifier.value is AuthAuthenticated;
        final loading = authStateNotifier.value is AuthLoading || authStateNotifier.value is AuthInitial;
        final loc = state.uri.path;

        if (loading) return loc == '/' ? null : '/';
        if (!authed && _isProtected(loc)) return '/login';
        if (authed && (loc == '/' || loc == '/login')) return '/home';
        return null;
      },
    );
  }

  static bool _isProtected(String loc) {
    const protectedRoutes = [
      '/home','/tasks','/maya','/settings','/other',
      '/profile','/integrations','/call_sessions','/ghl','/generations','/todos','/reminders'
    ];
    return protectedRoutes.any((r) => loc.startsWith(r));
  }
}
