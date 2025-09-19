// lib/features/home/presentation/pages/home_page.dart
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> todos = [];
  bool isLoadingTodos = false;

  @override
  void initState() {
    super.initState();
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
