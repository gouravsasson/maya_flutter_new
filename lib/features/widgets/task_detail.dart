import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart'; // Added for audio playback
import 'package:Maya/core/network/api_client.dart';

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
  Map<String, dynamic>? task;
  List<Map<String, dynamic>> subtasks = [];
  bool isLoading = true;
  String? errorMessage;
  String? expandedSubtask;

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
            subtasks = (task?['subtasks'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
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
    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
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
          // Radial Gradient Overlay
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
            child: Padding(
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  task?['user_payload']?['task']?.toString() ??
                                      'No query provided',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                              getStatusBadge(task?['status']?.toString() ?? 'pending'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatTimestamp(task?['created_at']),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          // Display user_payload as JSON
                          if (task?['user_payload'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: JsonDisplay(
                                data: task?['user_payload'],
                                label: 'User Payload',
                              ),
                            ),
                          // Display response with audio handling
                          if (task?['response'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: _buildResponseWidget(task!['response']),
                            ),
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
                              final isExpanded = expandedSubtask == subtask['id']?.toString();
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    expandedSubtask = isExpanded
                                        ? null
                                        : subtask['id']?.toString();
                                  });
                                },
                                child: Container(
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
                                                    subtask['name']?.toString() ??
                                                        'Unnamed Subtask',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.grey[800],
                                                    ),
                                                  ),
                                                  if (subtask['scheduledAt'] != null)
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
                                                            'Scheduled: ${_formatTimestamp(subtask['scheduledAt'])}',
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
                                            const SizedBox(width: 8),
                                            Icon(
                                              isExpanded
                                                  ? Icons.expand_more
                                                  : Icons.chevron_right,
                                              size: 20,
                                              color: Colors.grey[500],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isExpanded)
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
                                                if (subtask['payload'] != null)
                                                  JsonDisplay(
                                                    data: subtask['payload'],
                                                    label: 'Payload',
                                                  ),
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
                                                if (subtask['payload'] == null &&
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

    // Check if response contains an s3_url ending with .mp3
    if (response is Map<String, dynamic> && response.containsKey('s3_url') && response['s3_url'] is String && (response['s3_url'] as String).endsWith('.mp3')) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AUDIO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          AudioPlayerWidget(url: response['s3_url'] as String),
        ],
      );
    }

    // Check if response has a 'data' field that is a JSON string
    if (response is Map<String, dynamic> && response.containsKey('data') && response['data'] is String) {
      try {
        final decodedData = jsonDecode(response['data']) as Map<String, dynamic>;
        if (decodedData.containsKey('s3_url') && decodedData['s3_url'] is String && (decodedData['s3_url'] as String).endsWith('.mp3')) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AUDIO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              AudioPlayerWidget(url: decodedData['s3_url'] as String),
            ],
          );
        } else {
          return JsonDisplay(data: decodedData, label: 'Response');
        }
      } catch (e) {
        return JsonDisplay(data: response['data'], label: 'Response');
      }
    }

    // Default to JSON display for other response data
    return JsonDisplay(data: response, label: 'Response');
  }
}

class JsonDisplay extends StatelessWidget {
  final dynamic data;
  final String label;

  const JsonDisplay({super.key, required this.data, required this.label});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const SizedBox.shrink();

    String formattedData;
    try {
      formattedData = const JsonEncoder.withIndent('  ').convert(data);
    } catch (e) {
      formattedData = data.toString();
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