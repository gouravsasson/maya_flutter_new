import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:Maya/core/network/api_client.dart';

class TaskDetailPage extends StatefulWidget {
  final String sessionId;
  final String taskQuery;
  final ApiClient apiClient;

  const TaskDetailPage({
    super.key,
    required this.sessionId,
    required this.taskQuery,
    required this.apiClient,
  });

  @override
  _TaskDetailPageState createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  Map<String, dynamic>? task;
  List<Map<String, dynamic>> subtasks = [];
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
            task = (data is List ? data.first : data) as Map<String, dynamic>;
            // If no subtasks, treat the task itself as a subtask
            subtasks = (task?['subtasks'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
                       [task!]; // Add task as a single subtask
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

  Widget getStatusBadge(String status) {
    final statusConfig = {
      'succeeded': {
        'label': 'Completed',
        'icon': Icons.check_circle,
        'bgColor': const Color(0xFF10B981).withOpacity(0.6),
        'borderColor': const Color(0xFF10B981).withOpacity(0.3),
        'textColor': const Color(0xFF10B981),
      },
      'completed': {
        'label': 'Completed',
        'icon': Icons.check_circle,
        'bgColor': const Color(0xFF10B981).withOpacity(0.6),
        'borderColor': const Color(0xFF10B981).withOpacity(0.3),
        'textColor': const Color(0xFF10B981),
      },
      'pending': {
        'label': 'In Progress',
        'icon': Icons.access_time,
        'bgColor': const Color(0xFFF59E0B).withOpacity(0.6),
        'borderColor': const Color(0xFFF59E0B).withOpacity(0.3),
        'textColor': const Color(0xFFF59E0B),
      },
      'failed': {
        'label': 'Failed',
        'icon': Icons.error_outline,
        'bgColor': const Color(0xFFEF4444).withOpacity(0.6),
        'borderColor': const Color(0xFFEF4444).withOpacity(0.3),
        'textColor': const Color(0xFFEF4444),
      },
      'approval_pending': {
        'label': 'Approval Pending',
        'icon': Icons.warning_amber,
        'bgColor': const Color(0xFF3B82F6).withOpacity(0.6),
        'borderColor': const Color(0xFF3B82F6).withOpacity(0.3),
        'textColor': const Color(0xFF3B82F6),
      },
    };

    final config = statusConfig[status.toLowerCase()] ?? statusConfig['pending']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config['bgColor'] as Color,
        border: Border.all(color: config['borderColor'] as Color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config['icon'] as IconData,
            size: 14,
            color: config['textColor'] as Color,
          ),
          const SizedBox(width: 4),
          Text(
            config['label'] as String,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: config['textColor'] as Color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Retrieve the query from extra if not passed directly
    final routeData = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final taskQuery = widget.taskQuery.isNotEmpty ? widget.taskQuery : (routeData?['query']?.toString() ?? 'Task Details');

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE0F2FE),
                  Color(0xFFF3E8FF),
                  Color(0xFFFDE2E2),
                ],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [
                  Color(0x66DBEAFE),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () => context.go('/tasks'),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chevron_left,
                          size: 20,
                          color: const Color(0xFF1D4ED8),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Back to Tasks',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1D4ED8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Task Header
                  Text(
                    taskQuery,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (task != null)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldRow('Status', '', child: getStatusBadge(task?['status']?.toString() ?? 'pending')),
                          _buildFieldRow('Created At', _formatTimestamp(task?['created_at'])),
                          _buildFieldRow('Scheduled', task?['scheduled']?.toString() ?? 'false'),
                          _buildFieldRow('Scheduled At', task?['scheduled_at']?.toString() ?? 'N/A'),
                          _buildFieldRow('Notify', task?['notify']?.toString() ?? 'false'),
                          _buildFieldRow('Notified', task?['notified']?.toString() ?? 'false'),
                          if (task?['error']?.toString().isNotEmpty ?? false)
                            _buildFieldRow('Error', task?['error']?.toString() ?? 'None'),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Subtasks Section
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.blue[200]!.withOpacity(0.6),
                                border: Border.all(
                                    color: Colors.blue[300]!.withOpacity(0.4)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.check_box,
                                size: 16,
                                color: Colors.blue[700],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Sub-tasks',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (subtasks.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'No subtasks available',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: subtasks.length,
                            itemBuilder: (context, index) {
                              final subtask = subtasks[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.3)),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.4),
                                              border: Border.all(
                                                  color: Colors.white
                                                      .withOpacity(0.5)),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${index + 1}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  subtask['user_payload']?['query']?.toString() ??
                                                      subtask['name']?.toString() ??
                                                      'Unnamed Subtask',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey[800],
                                                  ),
                                                ),
                                                if (subtask['scheduled_at'] != null)
                                                  Padding(
                                                    padding: const EdgeInsets.only(
                                                        top: 4),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.access_time,
                                                          size: 12,
                                                          color: Colors.grey[500],
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'Scheduled: ${_formatTimestamp(subtask['scheduled_at'])}',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey[500],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          getStatusBadge(
                                              subtask['status']?.toString() ??
                                                  'pending'),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          top: BorderSide(
                                              color:
                                                  Colors.white.withOpacity(0.3)),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Display user_payload
                                            if (subtask['user_payload'] != null)
                                              JsonDisplay(
                                                data: subtask['user_payload'],
                                                label: 'User Payload',
                                              ),
                                            // Display response
                                            if (subtask['response'] != null)
                                              _buildResponseWidget(subtask['response']),
                                            if (subtask['error'] != null &&
                                                subtask['error']
                                                    .toString()
                                                    .isNotEmpty)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                    top: 12),
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.red[100]!
                                                      .withOpacity(0.6),
                                                  border: Border.all(
                                                      color: Colors.red[300]!
                                                          .withOpacity(0.6)),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.error_outline,
                                                      size: 18,
                                                      color: Colors.red[600],
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        subtask['error'].toString(),
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.red[800],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            if (subtask['user_payload'] == null &&
                                                subtask['response'] == null &&
                                                subtask['error'] == null &&
                                                subtask['status'] == 'pending')
                                              Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.3),
                                                  border: Border.all(
                                                      color: Colors.white
                                                          .withOpacity(0.4)),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  'This subtask is pending and has no data yet.',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldRow(String label, String value, {Widget? child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: child ?? Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
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

 
 
 Widget _buildResponseWidget(dynamic response) {
  if (response == null) return const SizedBox.shrink();

  // --------------------------------------------------------------
  // 1. Direct .mp3 on the outer level
  // --------------------------------------------------------------
  if (response is Map<String, dynamic> &&
      response.containsKey('s3_url') &&
      response['s3_url'] is String &&
      (response['s3_url'] as String).endsWith('.mp3')) {
    return _audioColumn(response['s3_url'] as String);
  }

  // --------------------------------------------------------------
  // 2. `data` is a JSON-encoded string → decode it
  // --------------------------------------------------------------
  Map<String, dynamic>? inner;
  if (response is Map<String, dynamic> &&
      response.containsKey('data') &&
      response['data'] is String) {
    try {
      inner = jsonDecode(response['data']) as Map<String, dynamic>;

      // 2a. Audio inside the inner payload
      if (inner.containsKey('s3_url') &&
          inner['s3_url'] is String &&
          (inner['s3_url'] as String).endsWith('.mp3')) {
        return _audioColumn(inner['s3_url'] as String);
      }
    } catch (_) {
      // keep `inner` null → we will treat `data` as raw text later
    }
  }

  // --------------------------------------------------------------
  // 3. Show **all outer fields** + (optionally) inner payload
  // --------------------------------------------------------------
  return _fullResponseDisplay(
    outer: response as Map<String, dynamic>,
    inner: inner,               // may be null
  );
}

// -----------------------------------------------------------------
// Re-usable audio UI
// -----------------------------------------------------------------
Widget _audioColumn(String url) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('AUDIO',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        AudioPlayerWidget(url: url),
      ],
    );

// -----------------------------------------------------------------
// Show *every* outer field + decoded inner payload (if any)
// -----------------------------------------------------------------
Widget _fullResponseDisplay({
  required Map<String, dynamic> outer,
  required Map<String, dynamic>? inner,
}) {
  // 1. Build a map that contains **all** outer fields
  final outerCopy = Map<String, dynamic>.from(outer);

  // If `data` was a JSON string we already decoded it → remove the raw string
  // so it does not appear twice.
  if (inner != null) outerCopy.remove('data');

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // ----- All outer fields (message, success, token, …) -----
      if (outerCopy.isNotEmpty)
        JsonDisplay(data: outerCopy, label: 'Meta'),

      // ----- Optional inner payload (the big transcripts list) -----
      if (inner != null) ...[
        const SizedBox(height: 16),
        JsonDisplay(data: inner, label: 'Payload'),
      ],

      // ----- Fallback: raw `data` string when we could not decode -----
      if (inner == null && outer.containsKey('data'))
        JsonDisplay(data: outer['data'], label: 'Raw Data'),
    ],
  );
}

}

class JsonDisplay extends StatelessWidget {
  final dynamic data;
  final String label;

  const JsonDisplay({super.key, required this.data, required this.label});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const SizedBox.shrink();

    dynamic displayData = data;
    // Attempt to decode if data is a JSON string
    if (data is String) {
      try {
        displayData = jsonDecode(data);
      } catch (e) {
        // If decoding fails, use the raw string
      }
    }

    String formattedData;
    try {
      formattedData = const JsonEncoder.withIndent('  ').convert(displayData);
    } catch (e) {
      formattedData = displayData.toString();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            formattedData,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontFamily: 'RobotoMono',
            ),
          ),
        ),
      ],
    );
  }
}

class AudioPlayerWidget extends StatefulWidget {
  final String url;

  const AudioPlayerWidget({super.key, required this.url});

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          duration = newDuration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          position = newPosition;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () async {
                if (isPlaying) {
                  await _audioPlayer.pause();
                } else {
                  await _audioPlayer.play(UrlSource(widget.url));
                }
              },
            ),
            Expanded(
              child: Slider(
                min: 0,
                max: duration.inSeconds.toDouble(),
                value: position.inSeconds.toDouble(),
                onChanged: (value) async {
                  final position = Duration(seconds: value.toInt());
                  await _audioPlayer.seek(position);
                },
              ),
            ),
          ],
        ),
        Text(
          '${_formatDuration(position)} / ${_formatDuration(duration)}',
          style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
