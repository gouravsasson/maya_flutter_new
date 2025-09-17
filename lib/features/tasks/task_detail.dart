import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_flutter_app/core/network/api_client.dart'; // Import the ApiClient

class TaskDetailPage extends StatefulWidget {
  final String sessionId;
  final ApiClient apiClient; // ApiClient passed from TasksPage

  const TaskDetailPage({
    super.key,
    required this.sessionId,
    required this.apiClient,
  });

  @override
  _TaskDetailPageState createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  Map<String, dynamic>? task;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchTaskDetail();
  }

  Future<void> fetchTaskDetail() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Use ApiClient to fetch task details
      final response = await widget.apiClient.fetchTasksDetail(
        sessionId: widget.sessionId,
      );
      final data = response['data'] as Map<String, dynamic>? ?? {};
      print(data);
      if (response['statusCode'] == 200 && (data['success'] as bool? ?? false)) {
        final taskList = (data['data'] as List<dynamic>?) ?? [];
        if (taskList.isNotEmpty) {
          setState(() {
            task = taskList[0] as Map<String, dynamic>? ?? {};
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            errorMessage = 'No task details found for session ${widget.sessionId}';
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage =
              'Failed to load task details: ${data['message']?.toString() ?? 'Unknown error'}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching task details: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Session ${widget.sessionId}'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                          onPressed: fetchTaskDetail,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    children: [
                      const Text(
                        'Task Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Query',
                        (task?['user_payload']?['task'] as String?)?.isNotEmpty == true
                            ? task!['user_payload']['task'] as String
                            : 'No query provided',
                      ),
                      _buildDetailRow(
                        'User Payload',
                        _formatUserPayload(task?['user_payload'] as Map<String, dynamic>? ?? {}),
                      ),
                      _buildDetailRow(
                        'Status',
                        (task?['status'] as String?)?.isNotEmpty == true
                            ? task!['status'][0].toUpperCase() + task!['status'].substring(1)
                            : 'Unknown',
                      ),
                      if ((task?['error'] as String?)?.isNotEmpty == true)
                        _buildDetailRow(
                          'Error',
                          task!['error'] as String,
                        ),
                      _buildDetailRow(
                        'Scheduled At',
                        _formatTimestamp(task?['scheduled_at'] as String? ?? ''),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String? timestamp) {
    try {
      if (timestamp == null || timestamp.isEmpty) return 'N/A';
      final dateTime = DateTime.parse(timestamp).toLocal();
      return DateFormat('MMM d, yyyy h:mm a').format(dateTime);
    } catch (e) {
      return timestamp ?? 'N/A';
    }
  }

  String _formatUserPayload(Map<String, dynamic>? payload) {
    if (payload == null || payload.isEmpty) {
      return 'No payload data';
    }
    // Dynamically format all key-value pairs in the payload
    return payload.entries.map((entry) {
      // Capitalize the first letter of the key and replace underscores with spaces
      String formattedKey = entry.key
          .split('_')
          .map((word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '')
          .join(' ');
      // Handle null or empty values
      String value = entry.value?.toString() ?? 'N/A';
      return '$formattedKey: $value';
    }).join('\n');
  }
}