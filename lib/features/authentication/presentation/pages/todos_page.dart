import 'package:Maya/core/network/api_client.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

class TodosPage extends StatefulWidget {
  const TodosPage({super.key});

  @override
  _TodosPageState createState() => _TodosPageState();
}

class _TodosPageState extends State<TodosPage> {
  List<Map<String, dynamic>> todos = [];
  bool isLoadingTodos = false;
  bool isLoadingMore = false;
  int currentPage = 1;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchToDos();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchToDos({int page = 1}) async {
    if (page == 1) {
      setState(() => isLoadingTodos = true);
    } else {
      setState(() => isLoadingMore = true);
    }

    try {
      final response = await GetIt.I<ApiClient>().getToDo(page: page);
      if (response['statusCode'] == 200) {
        final newTodos = List<Map<String, dynamic>>.from(response['data']['data']);
        setState(() {
          if (page == 1) {
            todos = newTodos;
          } else {
            todos.addAll(newTodos);
          }
          hasMore = newTodos.isNotEmpty; // Assuming API returns empty list when no more data
          currentPage = page;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch todos: ${response['message'] ?? 'Unknown error'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching todos: $e')),
      );
    } finally {
      setState(() {
        isLoadingTodos = false;
        isLoadingMore = false;
      });
    }
  }

  Future<void> updateToDo(Map<String, dynamic> todo) async {
    try {
      final payload = GetIt.I<ApiClient>().prepareUpdateToDoPayload(
        todo['ID'],
        title: todo['title'],
        description: todo['description'],
        status: todo['status'] == 'completed' ? 'pending' : 'completed',
        reminder: todo['reminder'] ?? false,
        reminder_time: todo['reminder_time'],
      );
      final response = await GetIt.I<ApiClient>().updateToDo(payload);
      if (response['statusCode'] == 200) {
        await fetchToDos(page: 1); // Refresh from first page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('To-Do updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update To-Do: ${response['message'] ?? 'Unknown error'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating To-Do: $e')),
      );
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        hasMore) {
      fetchToDos(page: currentPage + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('To-Dos'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE3F2FD), // blue-100
                  Color(0xFFF3E8FF), // purple-100
                  Color(0xFFFDE2F3), // pink-100
                ],
              ),
            ),
          ),
          // Radial gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [
                  Color(0x66BBDEFB), // blue-200/40
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: isLoadingTodos
                ? const Center(child: CircularProgressIndicator())
                : todos.isEmpty
                    ? const Center(child: Text('No to-dos available', style: TextStyle(color: Colors.grey)))
                    : SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            const Text(
                              'To-Do List',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937), // gray-800
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Manage your personal to-do lists',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF4B5563), // gray-600
                              ),
                            ),
                            const SizedBox(height: 24),
                            // To-Do List
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: todos.length + (isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == todos.length) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withOpacity(0.4)),
                                    boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
                                  ),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: todos[index]['status'] == 'completed',
                                        activeColor: const Color(0xFF047857), // green-700
                                        onChanged: (value) => updateToDo(todos[index]),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              todos[index]['title'],
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: const Color(0xFF1F2937),
                                                decoration: todos[index]['status'] == 'completed'
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              todos[index]['description'],
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF4B5563),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}