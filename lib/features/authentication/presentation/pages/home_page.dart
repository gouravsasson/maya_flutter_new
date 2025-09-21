// lib/features/home/presentation/pages/home_page.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:Maya/core/network/api_client.dart';
import 'package:Maya/features/widgets/features_section.dart';
import 'package:Maya/features/widgets/go_router_demo.dart';
import 'package:Maya/features/widgets/talk_to_maya.dart';
import 'package:Maya/features/widgets/todo_list.dart';
import 'package:Maya/features/widgets/welcome_card.dart';

import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_event.dart';
import '../../../authentication/presentation/bloc/auth_state.dart';
import 'package:Maya/core/services/notification_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> todos = [];
  bool isLoadingTodos = false;
  NotificationServices notificationServices = NotificationServices();

  @override
  void initState() {
    super.initState();
    notificationServices.requestNotificationPermission();
    notificationServices.forgroundMessage();
    notificationServices.firebaseInit(context);
    notificationServices.setupInteractMessage(context);
    notificationServices.isTokenRefresh();

    notificationServices.getDeviceToken().then((value) {
      if (kDebugMode) {
        print('device token');
        print(value);
      }
    });
    fetchToDos();
  }

  // ✅ Fetch ToDos using ApiClient
  Future<void> fetchToDos() async {
    setState(() => isLoadingTodos = true);

    final response = await getIt<ApiClient>().getToDo();
    if (response['statusCode'] == 200) {
      setState(() {
        todos = List<Map<String, dynamic>>.from(response['data']['data']);
      });
    }

    setState(() => isLoadingTodos = false);
  }

  // ✅ Add ToDo
  Future<void> addToDo(
    String title,
    String description, {
    String? reminder,
  }) async {
    final payload = getIt<ApiClient>().prepareCreateToDoPayload(
      title,
      description,
      reminder,
    );
    final response = await getIt<ApiClient>().createToDo(payload);
    if (response['statusCode'] == 200) {
      fetchToDos();
    }
  }

  // ✅ Update ToDo
  Future<void> updateToDo(Map<String, dynamic> todo) async {
    final payload = getIt<ApiClient>().prepareUpdateToDoPayload(
      todo['ID'],
      title: todo['title'],
      description: todo['description'],
      status: todo['status'],
      reminder: todo['reminder'] ?? false,
      reminder_time: todo['reminder_time'],
    );
    final response = await getIt<ApiClient>().updateToDo(payload);
    if (response['statusCode'] == 200) {
      fetchToDos();
    }
  }

  // ✅ Delete ToDo
  Future<void> deleteToDo(int id) async {
    final response = await getIt<ApiClient>().deleteToDo(id);
    if (response['statusCode'] == 200) {
      fetchToDos();
    }
  }

  Future<void> sendNotification() async {
    final token = await notificationServices.getDeviceToken();

    if (token == null) {
      if (kDebugMode) print("No device token found");
      return;
    }

    var data = {
      'to': token,
      'notification': {
        'title': 'Maya App',
        'body': 'This is a test notification',
        'sound': 'jetsons_doorbell.mp3',
      },
      'android': {
        'notification': {'notification_count': 1},
      },
      'data': {'type': 'custom', 'id': '12345'},
    };

    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        body: jsonEncode(data),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization':
              'key=YOUR_SERVER_KEY_HERE', // 🔑 Replace with your FCM server key
        },
      );

      if (kDebugMode) {
        print("Notification response: ${response.body}");
      }
    } catch (e) {
      if (kDebugMode) print("Error sending notification: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Colors.white,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const WelcomeCard(),
                    const SizedBox(height: 32),
                    const TalkToMaya(),
                    const SizedBox(height: 16),

                    // ✅ Hooked ToDoList with ApiClient
                    ToDoList(
                      todos: todos,
                      isLoading: isLoadingTodos,
                      onAdd: fetchToDos,
                      onUpdate: fetchToDos,
                      onDelete: fetchToDos,
                    ),

                    const SizedBox(height: 16),
                    const FeaturesSection(),
                    const SizedBox(height: 32),
                    const GoRouterDemo(),
                    const SizedBox(height: 32),

                    // ✅ Button for sending notifications
                    Center(
                      child: ElevatedButton(
                        onPressed: sendNotification,
                        child: const Text("Send Test Notification"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.orange),
            SizedBox(width: 8),
            Text('Logout'),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout?\n\nGoRouter will automatically redirect you to the login page.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthBloc>().add(LogoutRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
