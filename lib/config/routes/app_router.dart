// lib/core/routing/app_router.dart - No New Instances
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/bloc/auth_bloc.dart';
import '../../features/authentication/presentation/bloc/auth_state.dart';
import '../../features/authentication/presentation/pages/splash_page.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/home_page.dart';
import '../../features/authentication/presentation/pages/profile_page.dart';
import '../../core/services/navigation_service.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String profile = '/profile';

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
        GoRoute(
          path: splash,
          name: 'splash',
          builder: (BuildContext context, GoRouterState state) {
            // DON'T create new instance - use existing from BlocProvider
            return SplashPage();
          },
        ),
        GoRoute(
          path: login,
          name: 'login',
          builder: (BuildContext context, GoRouterState state) {
            // DON'T create new instance - use existing from BlocProvider
            return LoginPage();
          },
        ),
        GoRoute(
          path: home,
          name: 'home',
          builder: (BuildContext context, GoRouterState state) {
            // DON'T create new instance - use existing from BlocProvider
            return HomePage();
          },
        ),
        GoRoute(
          path: profile,
          name: 'profile',
          builder: (BuildContext context, GoRouterState state) {
            // DON'T create new instance - use existing from BlocProvider
            return ProfilePage();
          },
        ),
      ],
    );
  }

  static bool _isProtectedRoute(String location) {
    const protectedRoutes = [home, profile];
    return protectedRoutes.contains(location);
  }
}
