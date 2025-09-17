import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:my_flutter_app/core/network/api_client.dart';
import '../../../tasks/task_detail.dart';
import 'package:intl/intl.dart'; 

class TaskDetail {
  final String id;
  final String query;
  final String status;
  final String error;
  final String timestamp;

  TaskDetail({
    required this.id,
    required this.query,
    required this.status,
    required this.error,
    required this.timestamp,
  });

  factory TaskDetail.fromJson(Map<String, dynamic> json) {
    final toolCall = json['current_tool_call'] as Map<String, dynamic>? ?? {};
    final status = toolCall['status']?.toString() ?? '';
    final success = toolCall['success'] as bool? ?? false;
    final error = toolCall['error']?.toString() ?? '';

    // Format timestamp
    String formattedTimestamp = 'No timestamp';
    try {
      final createdAt = DateTime.parse(json['created_at']?.toString() ?? '');
      formattedTimestamp = DateFormat('MMM dd, yyyy HH:mm').format(createdAt);
    } catch (e) {
      // Keep default if parsing fails
    }

    return TaskDetail(
      id: json['id']?.toString() ?? 'Unknown',
      query: json['query']?.toString() ?? 'No query',
      status: status.isNotEmpty
          ? status
          : (success ? 'Completed' : (error.isNotEmpty ? 'Failed' : 'Pending')),
      error: error.isNotEmpty ? error : 'None',
      timestamp: formattedTimestamp,
    );
  }
}

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  _TasksPageState createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  String selectedFilter = 'all';
  List<TaskDetail> tasks = [];
  bool isLoading = true;
  String? errorMessage;
  late ApiClient apiClient; // Declare ApiClient

  @override
  void initState() {
    super.initState();
    // Initialize Dio instances and ApiClient
    final publicDio = Dio();
    final protectedDio = Dio();
    apiClient = ApiClient(publicDio, protectedDio);
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await apiClient.fetchTasks(); // Use ApiClient
      final data = response['data'];
      if (response['statusCode'] == 200 && data['success'] == true) {
        final List<dynamic> taskList =
            data['data']['sessions'] as List<dynamic>? ?? [];
        setState(() {
          tasks = taskList.map((json) => TaskDetail.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load tasks: ${data['message'] ?? 'Unknown error'}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching tasks: $e';
      });
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'succeeded':
      case 'completed':
        return const Color(0xFF10B981);
      case 'failed':
        return const Color(0xFFEF4444);
      case 'pending':
      default:
        return const Color(0xFF6B7280);
    }
  }

  Widget getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'succeeded':
      case 'completed':
        return Icon(
          Icons.check_circle,
          size: 18,
          color: getStatusColor(status),
        );
      case 'failed':
        return Icon(
          Icons.error_outline,
          size: 18,
          color: getStatusColor(status),
        );
      case 'pending':
      default:
        return Icon(Icons.access_time, size: 18, color: getStatusColor(status));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = tasks.where((task) {
      if (selectedFilter == 'all') return true;
      return task.status.toLowerCase() == selectedFilter;
    }).toList();

    final filterButtons = [
      {'key': 'all', 'label': 'All'},
      {'key': 'pending', 'label': 'Pending'},
      {'key': 'failed', 'label': 'Failed'},
      {'key': 'succeeded', 'label': 'Completed'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Tasks',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF6366F1)),
            onPressed: fetchTasks,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filterButtons.map((filter) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(
                        filter['label']!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: selectedFilter == filter['key']
                              ? Colors.white
                              : const Color(0xFF6B7280),
                        ),
                      ),
                      selected: selectedFilter == filter['key'],
                      selectedColor: const Color(0xFF6366F1),
                      backgroundColor: const Color(0xFFF3F4F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          selectedFilter = filter['key']!;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Tasks List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: fetchTasks,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : filteredTasks.isEmpty
                ? const Center(
                    child: Text(
                      'No tasks available',
                      style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Task Header
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      getStatusIcon(task.status),
                                      const SizedBox(width: 6),
                                      Text(
                                        task.status[0].toUpperCase() +
                                            task.status
                                                .substring(1)
                                                .replaceAll('-', ' '),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: getStatusColor(task.status),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F4FF),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Task Query
                              Text(
                                task.query.isNotEmpty
                                    ? task.query
                                    : 'No query provided',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Task Error (if any)
                              if (task.error != 'None')
                                Text(
                                  'Error: ${task.error}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFEF4444),
                                    height: 1.43,
                                  ),
                                ),
                              if (task.error != 'None')
                                const SizedBox(height: 6),

                              // Task Meta
                              Column(
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(
                                        width: 80,
                                        child: Text(
                                          'Created:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF9CA3AF),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          task.timestamp,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF374151),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Task Footer
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TaskDetailPage(
                                          sessionId: task.id,
                                          apiClient: apiClient, // Pass ApiClient
                                        ),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Text(
                                        'View Details',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF6366F1),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.chevron_right,
                                        size: 16,
                                        color: Color(0xFF6366F1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}