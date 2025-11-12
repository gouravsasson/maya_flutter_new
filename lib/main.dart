import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_it/get_it.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/authentication/presentation/bloc/auth_event.dart';
import 'injection_container.dart' as di;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("🔔 Handling background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthBloc _authBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final sl = GetIt.instance;
    _authBloc = sl<AuthBloc>();
    _router = sl<GoRouter>(); // ✅ uses the DI router
    _setupFirebaseMessaging();
    _authBloc.add(AppStarted());
  }

  void _setupFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((message) {
      if (!mounted) return;
      final notif = message.notification;
      if (notif != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${notif.title ?? ''}: ${notif.body ?? ''}')),
        );
      }
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null && message.data.containsKey('route')) {
        context.go(message.data['route']);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (message.data.containsKey('route')) {
        context.go(message.data['route']);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: MaterialApp.router(
        title: 'Maya',
        theme: AppTheme.theme,
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
