// lib/main.dart - WORKING VERSION
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'config/routes/app_router.dart';
import 'core/services/navigation_service.dart';
import 'core/theme/app_theme.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/authentication/presentation/bloc/auth_event.dart';
import 'features/authentication/presentation/bloc/auth_state.dart';
import 'injection_container.dart' as di;

class AuthDebugService {
  static StreamSubscription? _subscription;

  static void startDebugging(AuthBloc authBloc) {
    print('🔍 Starting AuthBloc debugging...');

    _subscription = authBloc.stream.listen(
      (state) {
        final timestamp = DateTime.now().toString().substring(11, 19);
        print('🎯 AUTH STATE CHANGE [$timestamp]: ${state.runtimeType}');

        if (state is AuthAuthenticated) {
          print('   👤 User: ${state.user.firstName} ${state.user.lastName}');
          print('   📧 Email: ${state.user.email}');
        } else if (state is AuthError) {
          print('   ❌ Error: ${state.message}');
        }

        print(
          '   📍 Current location: ${GoRouter.of(NavigationService.navigatorKey.currentContext!).routerDelegate.currentConfiguration.uri.path}',
        );
      },
      onError: (error) {
        print('❌ AUTH STREAM ERROR: $error');
      },
      onDone: () {
        print('✅ AUTH STREAM DONE');
      },
    );
  }

  static void stopDebugging() {
    _subscription?.cancel();
    _subscription = null;
    print('🛑 AuthBloc debugging stopped');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthBloc _authBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = di.sl<AuthBloc>();
    AuthDebugService.startDebugging(_authBloc);
    // Create router with the auth bloc
    _router = AppRouter.createRouter(_authBloc);

    // Initialize auth state after router is created
    _authBloc.add(AppStarted());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: _authBloc,
      child: MaterialApp.router(
        title: 'Flutter Auth with GoRouter',
        theme: AppTheme.lightTheme,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }
}
