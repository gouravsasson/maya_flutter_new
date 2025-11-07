import 'package:Maya/features/widgets/talk_to_maya.dart';
import 'package:Maya/utils/tab_layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import 'package:Maya/core/network/api_client.dart';
import 'package:Maya/core/services/navigation_service.dart';

import 'package:Maya/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:Maya/features/authentication/presentation/bloc/auth_state.dart';

import 'package:Maya/features/authentication/presentation/pages/splash_page.dart';
import 'package:Maya/features/authentication/presentation/pages/login_page.dart';
import 'package:Maya/features/authentication/presentation/pages/home_page.dart';
import 'package:Maya/features/authentication/presentation/pages/tasks_page.dart';
import 'package:Maya/features/authentication/presentation/pages/settings_page.dart';
import 'package:Maya/features/authentication/presentation/pages/other_page.dart';
import 'package:Maya/features/authentication/presentation/pages/profile_page.dart';
import 'package:Maya/features/authentication/presentation/pages/call_sessions.dart';
import 'package:Maya/features/authentication/presentation/pages/integration_page.dart';
import 'package:Maya/features/authentication/presentation/pages/generations_page.dart';
import 'package:Maya/features/authentication/presentation/pages/todos_page.dart';
import 'package:Maya/features/authentication/presentation/pages/reminders_page.dart';

import 'package:Maya/features/widgets/ghl.dart';
import 'package:Maya/features/widgets/task_detail.dart';

class AppRouter {
  static const splash = '/';
  static const login = '/login';

  static const home = '/home';
  static const tasks = '/tasks';
  static const maya = '/maya';
  static const settings = '/settings';
  static const other = '/other';

  static const profile = '/profile';
  static const integrations = '/integrations';
  static const callSessions = '/call_sessions';
  static const ghl = '/ghl';
  static const generations = '/generations';
  static const todos = '/todos';
  static const reminders = '/reminders';

  static const taskDetail = '/tasks/:taskId';

  static final ValueNotifier<AuthState> authStateNotifier =
      ValueNotifier<AuthState>(AuthInitial());

  /// ✅ Root navigator – all detail pages push here
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static GoRouter createRouter(AuthBloc authBloc) {
    authStateNotifier.value = authBloc.state;

    authBloc.stream.listen((state) {
      authStateNotifier.value = state;
    });

    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: splash,
      refreshListenable: authStateNotifier,
      debugLogDiagnostics: true,

      redirect: (context, state) {
        final authed = authStateNotifier.value is AuthAuthenticated;
        final loading =
            authStateNotifier.value is AuthLoading ||
            authStateNotifier.value is AuthInitial;

        final loc = state.uri.path;

        if (loading) {
          if (loc != splash) return splash;
          return null;
        }

        if (!authed) {
          if (loc == splash || _isProtected(loc)) {
            return login;
          }
          return null;
        }

        if (loc == splash || loc == login) {
          return home;
        }

        return null;
      },

      routes: [
        /// ✅ Splash + Login → on root navigator
        GoRoute(
          path: splash,
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, __) => const SplashPage(),
        ),
        GoRoute(
          path: login,
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, __) => const LoginPage(),
        ),

        /// ✅ Tabs → no parentNavigatorKey (each stays in tab navigator)
        GoRoute(
          path: home,
          builder: (_, __) =>
              const TabLayout(currentIndex: 0, child: HomePage()),
        ),
        GoRoute(
          path: tasks,
          builder: (_, __) =>
              const TabLayout(currentIndex: 1, child: TasksPage()),
        ),
        GoRoute(
          path: maya,
          builder: (_, __) =>
              const TabLayout(currentIndex: 2, child: TalkToMaya()),
        ),
        GoRoute(
          path: settings,
          builder: (_, __) =>
              const TabLayout(currentIndex: 3, child: SettingsPage()),
        ),
        GoRoute(
          path: other,
          builder: (_, __) =>
              const TabLayout(currentIndex: 4, child: OtherPage()),
        ),

        /// ✅ Task Detail → forced to root navigator
        GoRoute(
          path: taskDetail,
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, state) => TaskDetailPage(
            sessionId: state.pathParameters['taskId']!,
            apiClient: ApiClient(Dio(), Dio()),
            taskQuery: '',
          ),
        ),

        /// ✅ All non-tab pages — forced to root navigator
        GoRoute(
          path: profile,
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, __) => const ProfilePage(),
        ),
        GoRoute(
          path: callSessions,
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, __) => const CallSessionsPage(),
        ),
        GoRoute(
          path: integrations,
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, __) => const IntegrationsPage(),
        ),
        GoRoute(
          path: ghl,
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, __) => const GhlWebViewPage(),
        ),
        GoRoute(
          path: generations,
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, __) => const GenerationsPage(),
        ),
        GoRoute(
          path: todos,
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, __) => const TodosPage(),
        ),
        GoRoute(
          path: reminders,
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, __) => const RemindersPage(),
        ),
      ],
    );
  }

  static bool _isProtected(String loc) {
    const protectedFixed = <String>{
      home,
      tasks,
      maya,
      settings,
      other,
      profile,
      integrations,
      callSessions,
      ghl,
      generations,
      todos,
      reminders,
    };
    return protectedFixed.contains(loc) ||
        loc.startsWith('/tasks/') ||
        loc.startsWith('/ghl');
  }
}
