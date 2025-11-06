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

/// Navigation History Manager
/// Production-grade navigation tracking with proper state management
class NavigationHistory extends ChangeNotifier {
  static final NavigationHistory _instance = NavigationHistory._internal();
  factory NavigationHistory() => _instance;
  NavigationHistory._internal();

  final List<String> _history = [];
  String? _currentRoute;
  static const int maxHistorySize = 100;

  /// Main tab routes that shouldn't create back stack entries
  static const List<String> mainTabs = [
    '/home',
    '/tasks',
    '/maya',
    '/settings',
    '/other',
  ];

  /// Add a route to history with intelligent duplicate handling
  void push(String route) {
    final cleanRoute = _cleanRoute(route);
    
    // Skip if same as current route (e.g., tab re-tap)
    if (_currentRoute == cleanRoute) {
      debugPrint('📍 NavigationHistory: Skipping duplicate route "$cleanRoute"');
      return;
    }

    // Check if this is a main tab navigation
    final isMainTab = mainTabs.contains(cleanRoute);
    final wasOnMainTab = _currentRoute != null && mainTabs.contains(_currentRoute!);

    if (isMainTab) {
      if (wasOnMainTab) {
        // Tab to tab: Replace current with new tab (lateral navigation)
        if (_history.isNotEmpty) {
          _history.removeLast();
        }
        _history.add(cleanRoute);
        debugPrint('🔄 NavigationHistory: Tab switch "$_currentRoute" -> "$cleanRoute" | Stack: ${_getHistoryPreview()}');
      } else {
        // Detail to tab: Just add it (going back from detail to tab)
        _history.add(cleanRoute);
        debugPrint('⬅️ NavigationHistory: Back to tab "$cleanRoute" | Stack: ${_getHistoryPreview()}');
      }
    } else {
      // Detail/nested route: Always add
      _history.add(cleanRoute);
      debugPrint('➡️ NavigationHistory: Push detail "$cleanRoute" | Stack: ${_getHistoryPreview()}');
    }

    _currentRoute = cleanRoute;

    // Limit history size
    if (_history.length > maxHistorySize) {
      _history.removeAt(0);
    }

    notifyListeners();
  }

  /// Pop current route and return previous
  String? pop() {
    if (_history.length <= 1) {
      debugPrint('🚫 NavigationHistory: Cannot pop - only one or zero routes in stack');
      return null;
    }

    final current = _history.removeLast();
    final previous = _history.last;
    _currentRoute = previous;
    
    debugPrint('⬅️ NavigationHistory: Pop "$current" -> "$previous" | Stack: ${_getHistoryPreview()}');
    notifyListeners();
    
    return previous;
  }

  /// Check if we can navigate back
  bool canGoBack() {
    return _history.length > 1;
  }

  /// Get current route
  String? get current => _currentRoute ?? (_history.isNotEmpty ? _history.last : null);

  /// Get history count
  int get count => _history.length;

  /// Clear all history
  void clear() {
    _history.clear();
    _currentRoute = null;
    debugPrint('🗑️ NavigationHistory: Cleared');
    notifyListeners();
  }

  /// Get full history for debugging
  List<String> get fullHistory => List.unmodifiable(_history);

  /// Reset to specific route
  void resetTo(String route) {
    final cleanRoute = _cleanRoute(route);
    _history.clear();
    _history.add(cleanRoute);
    _currentRoute = cleanRoute;
    debugPrint('🔄 NavigationHistory: Reset to "$cleanRoute"');
    notifyListeners();
  }

  /// Remove specific route from history
  void remove(String route) {
    final cleanRoute = _cleanRoute(route);
    _history.remove(cleanRoute);
    if (_history.isNotEmpty) {
      _currentRoute = _history.last;
    } else {
      _currentRoute = null;
    }
    notifyListeners();
  }

  /// Clean route string
  String _cleanRoute(String route) {
    if (route.endsWith('/') && route.length > 1) {
      return route.substring(0, route.length - 1);
    }
    return route;
  }

  /// Get preview of last N routes
  String _getHistoryPreview({int count = 5}) {
    if (_history.isEmpty) return '[]';
    final preview = _history.length > count 
        ? _history.sublist(_history.length - count)
        : _history;
    return '[${preview.join(' → ')}]';
  }

  /// Check if route is a main tab
  bool isMainTab(String route) {
    return mainTabs.contains(_cleanRoute(route));
  }
}

class AppRouter {
  // Route constants
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

  static final ValueNotifier<AuthState> authStateNotifier = ValueNotifier(AuthInitial());
  static final NavigationHistory navigationHistory = NavigationHistory();

  /// Main tab routes
  static const List<String> mainTabRoutes = [
    home,
    tasks,
    maya,
    settings,
    other,
  ];

  /// Check if route is a main tab
  static bool isMainTab(String route) {
    return mainTabRoutes.contains(route);
  }

  /// Protected routes requiring authentication
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
      ghl,
    ];
    return protectedRoutes.contains(location) || 
           location.startsWith('/tasks/') ||
           location.startsWith('/ghl');
  }

  static GoRouter createRouter(AuthBloc authBloc) {
    debugPrint('🚀 AppRouter: Initializing with AuthBloc: ${authBloc.hashCode}');

    authStateNotifier.value = authBloc.state;

    authBloc.stream.listen((state) {
      debugPrint('🔐 AppRouter: Auth state changed to ${state.runtimeType}');
      authStateNotifier.value = state;

      if (state is AuthUnauthenticated) {
        debugPrint('🔒 AppRouter: User logged out, clearing navigation history');
        navigationHistory.clear();
        NavigationService.showSessionExpiredDialog();
      }
    });

    return GoRouter(
      navigatorKey: NavigationService.navigatorKey,
      initialLocation: splash,
      debugLogDiagnostics: true,
      refreshListenable: authStateNotifier,
      
      // Navigation observer to track route changes
      observers: [
        NavigationObserver(),
      ],

      redirect: (BuildContext context, GoRouterState state) async {
        final authState = authStateNotifier.value;
        final isLoggedIn = authState is AuthAuthenticated;
        final isLoading = authState is AuthLoading || authState is AuthInitial;
        final currentLocation = state.uri.path;

        debugPrint('🔀 GoRouter Redirect:');
        debugPrint('   Auth: ${authState.runtimeType} | Logged in: $isLoggedIn');
        debugPrint('   Location: $currentLocation');

        // Show splash while loading
        if (isLoading) {
          return currentLocation == splash ? null : splash;
        }

        // Authenticated user redirects
        if (isLoggedIn) {
          if (currentLocation == login || currentLocation == splash) {
            debugPrint('   ✅ Redirect to HOME (authenticated)');
            navigationHistory.resetTo(home);
            return home;
          }
          return null;
        }

        // Unauthenticated user redirects
        if (!isLoggedIn && !isLoading) {
          if (_isProtectedRoute(currentLocation)) {
            debugPrint('   ❌ Redirect to LOGIN (protected route)');
            navigationHistory.clear();
            return login;
          }
          if (currentLocation == splash) {
            return login;
          }
        }

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
        
        // Main shell route with bottom navigation
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

  /// Navigate back intelligently
  static Future<bool> goBack(BuildContext context) async {
    final currentLocation = GoRouterState.of(context).uri.path;
    debugPrint('⬅️ AppRouter.goBack() called from: $currentLocation');
    debugPrint('📚 History: ${navigationHistory.fullHistory}');

    if (!navigationHistory.canGoBack()) {
      debugPrint('🚫 No history to go back to');
      return false;
    }

    final previousRoute = navigationHistory.pop();
    
    if (previousRoute != null && previousRoute != currentLocation) {
      debugPrint('✅ Navigating back to: $previousRoute');
      context.go(previousRoute);
      return true;
    }

    debugPrint('🚫 Previous route same as current or null');
    return false;
  }

  /// Navigate to a route
  static void navigateTo(BuildContext context, String route) {
    debugPrint('➡️ AppRouter.navigateTo: $route');
    context.go(route);
  }

  /// Replace current route
  static void replaceTo(BuildContext context, String route) {
    debugPrint('🔄 AppRouter.replaceTo: $route');
    if (navigationHistory.canGoBack()) {
      navigationHistory.pop();
    }
    context.go(route);
  }

  /// Clear history and navigate
  static void clearAndNavigateTo(BuildContext context, String route) {
    debugPrint('🗑️ AppRouter.clearAndNavigateTo: $route');
    navigationHistory.resetTo(route);
    context.go(route);
  }

  /// Push route (useful for detail pages)
  static void push(BuildContext context, String route) {
    debugPrint('📤 AppRouter.push: $route');
    context.push(route);
  }
}

/// Custom navigation observer to track route changes
class NavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _trackRoute(route);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _trackRoute(previousRoute);
    }
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _trackRoute(newRoute);
    }
  }

  void _trackRoute(Route route) {
    if (route.settings.name != null && route.settings.name!.isNotEmpty) {
      final routeName = route.settings.name!;
      
      // Only track if it's not a dialog or modal
      if (!routeName.startsWith('/')) return;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppRouter.navigationHistory.push(routeName);
      });
    }
  }
}