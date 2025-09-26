import 'dart:convert'; // Added for JSON parsing
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Maya/core/network/api_client.dart'; // Import the ApiClient

class TaskDetailPage extends StatefulWidget {
  final String sessionId;
  final ApiClient apiClient;

  const TaskDetailPage({
    super.key,
    required this.sessionId,
    required this.apiClient,
  });

  @override
  _TaskDetailPageState createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  List<Map<String, dynamic>> tasks = []; // Changed to handle multiple tasks
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
      final response = await widget.apiClient.fetchTasksDetail(
        sessionId: widget.sessionId,
      );
      final data = response['data']['data'];
      print(data);
      if (response['statusCode'] == 200 &&
          (response['data']['success'] as bool? ?? false)) {
        if (data == null || (data is List && data.isEmpty)) {
          setState(() {
            isLoading = false;
            errorMessage =
                'No task details found for session ${widget.sessionId}';
          });
        } else {
          setState(() {
            tasks = (data is List)
                ? List<Map<String, dynamic>>.from(data)
                : [data as Map<String, dynamic>]; // Handle single object case
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage =
              'Failed to load task details: ${response['message']?.toString() ?? 'Unknown error'}';
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
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : tasks.isEmpty
            ? const Center(
                child: Text(
                  'No tasks available',
                  style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                ),
              )
            : ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Task ${index + 1}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Query',
                        (task['user_payload']?['task'] as String?)
                                    ?.isNotEmpty ==
                                true
                            ? task['user_payload']['task'] as String
                            : 'No query provided',
                      ),
                      _buildDetailRow(
                        'User Payload',
                        _formatUserPayload(
                          task['user_payload'] as Map<String, dynamic>? ?? {},
                        ),
                      ),
                      _buildDetailRow(
                        'Status',
                        (task['status'] as String?)?.isNotEmpty == true
                            ? task['status'][0].toUpperCase() +
                                  task['status'].substring(1)
                            : 'Unknown',
                      ),
                      if ((task['error'] as String?)?.isNotEmpty == true)
                        _buildDetailRow('Error', task['error'] as String),
                      _buildDetailRow(
                        'Scheduled At',
                        _formatTimestamp(task['scheduled_at'] as String? ?? ''),
                      ),
                      _buildDetailRow(
                        'Response',
                        _formatResponse(
                          task['response'] as Map<String, dynamic>? ?? {},
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
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
    return payload.entries
        .map((entry) {
          String formattedKey = entry.key
              .split('_')
              .map(
                (word) => word.isNotEmpty
                    ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                    : '',
              )
              .join(' ');
          String value = entry.value?.toString() ?? 'N/A';
          return '$formattedKey: $value';
        })
        .join('\n');
  }

  String _formatResponse(Map<String, dynamic>? response) {
    if (response == null || response.isEmpty) {
      return 'No response data';
    }
    // Initialize the result with message and success fields
    final List<String> formattedEntries = [];
    if (response['message']?.toString().isNotEmpty == true) {
      formattedEntries.add('Message: ${response['message']}');
    }
    if (response['success'] != null) {
      formattedEntries.add('Success: ${response['success']}');
    }

    // Parse and format the data field if it exists
    if (response['data']?.toString().isNotEmpty == true) {
      try {
        final data = jsonDecode(response['data'] as String) as Map<String, dynamic>;
        // Exclude specific fields
        final filteredData = data.entries.where((entry) {
          return ![
            'id',
            'CreatedAt',
            'UpdatedAt',
            'DeletedAt',
          ].contains(entry.key.toLowerCase());
        });
        final dataFormatted = filteredData.map((entry) {
          String formattedKey = entry.key
              .split('_')
              .map(
                (word) => word.isNotEmpty
                    ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                    : '',
              )
              .join(' ');
          String value = entry.value?.toString() ?? 'N/A';
          // Check if the value is a date-time string
          if (value != 'N/A' && _isDateTime(value)) {
            try {
              final dateTime = DateTime.parse(value).toLocal();
              value = DateFormat('MMM d, yyyy h:mm a').format(dateTime);
            } catch (e) {
              // If parsing fails, keep the original value
            }
          }
          return '$formattedKey: $value';
        }).join('\n');
        if (dataFormatted.isNotEmpty) {
          formattedEntries.add('Data:\n$dataFormatted');
        }
      } catch (e) {
        formattedEntries.add('Data: ${response['data']}');
      }
    }

    return formattedEntries.isEmpty
        ? 'No response data'
        : formattedEntries.join('\n');
  }

  bool _isDateTime(String value) {
    // Basic check for ISO 8601 or similar date-time format
    final dateTimePattern = RegExp(
        r'^\d{4}-\d{2}-\d{2}(T|\s)\d{2}:\d{2}:\d{2}(\.\d+)?([Z+|-]\d{2}:\d{2})?$');
    return dateTimePattern.hasMatch(value);
  }
}