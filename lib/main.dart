// lib/main.dart - FIXED VERSION
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'config/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/authentication/presentation/bloc/auth_event.dart';
import 'features/authentication/presentation/bloc/auth_state.dart';
import 'injection_container.dart' as di;

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

  @override
  void initState() {
    super.initState();
    _authBloc = di.sl<AuthBloc>()..add(AppStarted());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: _authBloc,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          print('🎭 Main: Auth state changed to ${state.runtimeType}');
          // Force rebuild when state changes
          setState(() {});
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          bloc: _authBloc, // Explicitly specify the bloc
          builder: (context, authState) {
            print('🔄 Main: Building app with state: ${authState.runtimeType}');

            return MaterialApp.router(
              title: 'Flutter Auth with GoRouter',
              theme: AppTheme.lightTheme,
              routerConfig: AppRouter.createRouter(authState),
              debugShowCheckedModeBanner: false,
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }
}
