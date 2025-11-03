import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:Maya/core/network/api_client.dart';

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
    final status =
        toolCall['status']?.toString() ?? json['status']?.toString() ?? '';
    final success =
        json['success'] as bool? ?? toolCall['success'] as bool? ?? false;
    final error =
        json['error']?.toString() ?? toolCall['error']?.toString() ?? '';

    String formattedTimestamp = 'No timestamp';
    try {
      final createdAt = DateTime.parse(json['created_at']?.toString() ?? '');
      formattedTimestamp = DateFormat('MMM dd, yyyy HH:mm').format(createdAt);
    } catch (e) {
      // Keep default if parsing fails
    }

    return TaskDetail(
      id: json['id']?.toString() ?? 'Unknown',
      query:
          json['user_payload']?['task']?.toString() ??
          json['query']?.toString() ??
          'No query',
      status: status.isNotEmpty
          ? status
          : (success ? 'completed' : (error.isNotEmpty ? 'failed' : 'pending')),
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
  bool isLoadingMore = false;
  String? errorMessage;
  late ApiClient apiClient;
  int currentPage = 1;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final publicDio = Dio();
    final protectedDio = Dio();
    apiClient = ApiClient(publicDio, protectedDio);
    fetchTasks();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchTasks({int page = 1}) async {
    if (page == 1) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    } else {
      setState(() {
        isLoadingMore = true;
      });
    }

    try {
      final response = await apiClient.fetchTasks(page: page);
      final data = response['data'];
      if (response['statusCode'] == 200 && data['success'] == true) {
        final List<dynamic> taskList =
            data['data']?['sessions'] as List<dynamic>? ?? [];
        setState(() {
          final newTasks =
              taskList.map((json) => TaskDetail.fromJson(json)).toList();
          if (page == 1) {
            tasks = newTasks;
          } else {
            tasks.addAll(newTasks);
          }
          hasMore = newTasks.isNotEmpty;
          currentPage = page;
          isLoading = false;
          isLoadingMore = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
          errorMessage =
              'Failed to load tasks: ${data['message'] ?? 'Unknown error'}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
        errorMessage = 'Error fetching tasks: $e';
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        hasMore) {
      fetchTasks(page: currentPage + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = tasks.where((task) {
      if (selectedFilter == 'all') return true;
      return task.status.toLowerCase() == selectedFilter;
    }).toList();

    return Scaffold(
      body: Stack(
        children: [
          // Background matching splash page
          Container(color: const Color(0xFF111827)),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x992A57E8), // #2A57E8 at 60%
                  Colors.transparent,
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Top blue card section
                // Container(
                //   margin: const EdgeInsets.all(16),
                //   padding: const EdgeInsets.all(20),
                //   decoration: BoxDecoration(
                //     gradient: const LinearGradient(
                //       begin: Alignment.topLeft,
                //       end: Alignment.bottomRight,
                //       colors: [
                //         Color(0xFF3B82F6),
                //         Color(0xFF2563EB),
                //       ],
                //     ),
                //     borderRadius: BorderRadius.circular(16),
                //     boxShadow: [
                //       BoxShadow(
                //         color: const Color(0xFF2563EB).withOpacity(0.3),
                //         blurRadius: 20,
                //         offset: const Offset(0, 8),
                //       ),
                //     ],
                //   ),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       const Text(
                //         'Maximize your productivity with Maya AI',
                //         style: TextStyle(
                //           fontSize: 16,
                //           fontWeight: FontWeight.w600,
                //           color: Colors.white,
                //           height: 1.3,
                //         ),
                //       ),
                //       const SizedBox(height: 4),
                //       Text(
                //         'Stay on top of tasks without the fuss.',
                //         style: TextStyle(
                //           fontSize: 13,
                //           color: Colors.white.withOpacity(0.8),
                //         ),
                //       ),
                //       const SizedBox(height: 16),
                //       Container(
                //         padding: const EdgeInsets.symmetric(
                //           horizontal: 16,
                //           vertical: 10,
                //         ),
                //         decoration: BoxDecoration(
                //           color: Colors.white.withOpacity(0.25),
                //           borderRadius: BorderRadius.circular(8),
                //         ),
                //         child: Row(
                //           mainAxisSize: MainAxisSize.min,
                //           children: [
                //             const Text(
                //               'Create a Task',
                //               style: TextStyle(
                //                 fontSize: 13,
                //                 fontWeight: FontWeight.w600,
                //                 color: Colors.white,
                //               ),
                //             ),
                //             const SizedBox(width: 8),
                //             Icon(
                //               LucideIcons.arrowRight,
                //               size: 16,
                //               color: Colors.white,
                //             ),
                //           ],
                //         ),
                //       ),
                //     ],
                //   ),
                // ),

                // "Over time" section header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Over time',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          _buildFilterChip('Pending'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Completed'),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tasks section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tasks',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => fetchTasks(page: 1),
                        child: const Text(
                          'View all',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Tasks list
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        )
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
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => fetchTasks(page: 1),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3B82F6),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : filteredTasks.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No tasks found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white60,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                                  itemCount: filteredTasks.length +
                                      (isLoadingMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == filteredTasks.length) {
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        ),
                                      );
                                    }
                                    final task = filteredTasks[index];
                                    return _buildTaskCard(task);
                                  },
                                ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.white.withOpacity(0.8),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTaskCard(TaskDetail task) {
    // Determine status color and icon
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (task.status.toLowerCase()) {
      case 'succeeded':
      case 'completed':
        statusColor = const Color(0xFF10B981);
        statusLabel = 'Completed';
        statusIcon = LucideIcons.checkCircle2;
        break;
      case 'failed':
        statusColor = const Color(0xFFEF4444);
        statusLabel = 'Failed';
        statusIcon = LucideIcons.xCircle;
        break;
      case 'approval_pending':
        statusColor = const Color(0xFF3B82F6);
        statusLabel = 'In Progress';
        statusIcon = LucideIcons.clock;
        break;
      default:
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'Pending';
        statusIcon = LucideIcons.clock;
    }

    return GestureDetector(
      onTap: () {
        context.go(
          '/tasks/${task.id}',
          extra: {'query': task.query},
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A5F).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge with checkbox
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Checkbox
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Task title
            Text(
              task.query.isNotEmpty ? task.query : 'No query provided',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Subtitle
            Text(
              'UX and Research Discussion',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 12),

            // Footer with timestamp and priority badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.clock,
                      size: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      task.timestamp,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                // Priority badge (optional - can be conditional)
                if (task.status.toLowerCase() == 'approval_pending')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.star,
                          size: 10,
                          color: const Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Priority',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}