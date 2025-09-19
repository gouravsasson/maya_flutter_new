import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:Maya/firebase_options.dart';

import 'config/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/authentication/presentation/bloc/auth_event.dart';
import 'injection_container.dart' as di;
import 'core/services/storage_service.dart';
// import 'core/services/deep_link_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthBloc _authBloc;
  late final GoRouter _router;
  
  // bool _deepLinkInitialized = false;

  @override
  void initState() {
    super.initState();
    _authBloc = di.sl<AuthBloc>();
    _router = AppRouter.createRouter(_authBloc);

    _authBloc.add(AppStarted());
  }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();

  //   // ✅ Initialize deep linking here where context is available
  //   if (!_deepLinkInitialized && mounted) {
  //     _deepLinkInitialized = true;
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       if (mounted) {
  //         print('🔗 Initializing deep linking...');
  //         DeepLinkService.initialize(context);
  //       }
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: _authBloc,
      child: MaterialApp.router(
        title: 'Maya App', // Updated to match your domain
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
