import 'dart:convert'; // For JSON parsing
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart'; // Import audioplayers
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
  List<Map<String, dynamic>> tasks = [];
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
                : [data as Map<String, dynamic>];
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
                      ..._formatResponse(
                        task['response'] as Map<String, dynamic>? ?? {},
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
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
            child: value is String
                ? Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF374151),
                    ),
                  )
                : value is Widget
                ? value
                : const Text(
                    'Invalid data',
                    style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
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

  List<Widget> _formatResponse(Map<String, dynamic>? response) {
    if (response == null || response.isEmpty) {
      return [_buildDetailRow('Response', 'No response data')];
    }

    List<Widget> formattedEntries = [];

    response.forEach((key, value) {
      String formattedKey = key
          .split('_')
          .map(
            (word) => word.isNotEmpty
                ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                : '',
          )
          .join(' ');

      if (key == 'data' && value is String) {
        // Parse the JSON string in the 'data' field
        try {
          final decodedData = jsonDecode(value) as Map<String, dynamic>;
          print(decodedData['s3_url']);
          if (decodedData.containsKey('s3_url') &&
              decodedData['s3_url'] is String &&
              (decodedData['s3_url'] as String).endsWith('.mp3')) {
            // Handle s3_url as an MP3 file
            formattedEntries.add(
              _buildDetailRow(
                'Audio',
                AudioPlayerWidget(url: decodedData['s3_url'] as String),
              ),
            );
          } else {
            // Format other fields in the decoded data
            decodedData.forEach((subKey, subValue) {
              String formattedSubKey = subKey
                  .split('_')
                  .map(
                    (word) => word.isNotEmpty
                        ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                        : '',
                  )
                  .join(' ');
              if (subKey == 's3_url' &&
                  subValue is String &&
                  subValue.endsWith('.mp3')) {
                formattedEntries.add(
                  _buildDetailRow(
                    formattedSubKey,
                    AudioPlayerWidget(url: subValue),
                  ),
                );
              } else {
                String formattedSubValue = _formatValue(
                  subValue,
                  indentLevel: 1,
                );
                formattedEntries.add(
                  _buildDetailRow(formattedSubKey, formattedSubValue),
                );
              }
            });
          }
        } catch (e) {
          // If parsing fails, treat as a regular string
          String formattedValue = _formatValue(value, indentLevel: 1);
          formattedEntries.add(_buildDetailRow(formattedKey, formattedValue));
        }
      } else if (key == 's3_url' && value is String && value.endsWith('.mp3')) {
        formattedEntries.add(
          _buildDetailRow(formattedKey, AudioPlayerWidget(url: value)),
        );
      } else {
        String formattedValue = _formatValue(value, indentLevel: 1);
        formattedEntries.add(_buildDetailRow(formattedKey, formattedValue));
      }
    });

    return formattedEntries;
  }

  String _formatValue(dynamic value, {int indentLevel = 0}) {
    const String indent = '  '; // Two spaces per indent level

    if (value == null) {
      return 'N/A';
    } else if (value is String) {
      // Check if the string is a JSON object or array
      try {
        final decoded = jsonDecode(value);
        return _formatValue(decoded, indentLevel: indentLevel);
      } catch (e) {
        // Check if the string is a date-time
        if (_isDateTime(value)) {
          try {
            final dateTime = DateTime.parse(value).toLocal();
            return DateFormat('MMM d, yyyy h:mm a').format(dateTime);
          } catch (e) {
            return value;
          }
        }
        return value.isEmpty ? 'N/A' : value;
      }
    } else if (value is Map<String, dynamic>) {
      if (value.isEmpty) {
        return 'Empty object';
      }
      final entries = value.entries
          .map((entry) {
            String formattedKey = entry.key
                .split('_')
                .map(
                  (word) => word.isNotEmpty
                      ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                      : '',
                )
                .join(' ');
            String formattedValue = _formatValue(
              entry.value,
              indentLevel: indentLevel + 1,
            );
            return '${indent * (indentLevel + 1)}$formattedKey: $formattedValue';
          })
          .join('\n');
      return '\n$entries';
    } else if (value is List) {
      if (value.isEmpty) {
        return 'Empty list';
      }
      final entries = value
          .asMap()
          .entries
          .map((entry) {
            int index = entry.key;
            dynamic item = entry.value;
            String formattedItem = _formatValue(
              item,
              indentLevel: indentLevel + 1,
            );
            return '${indent * (indentLevel + 1)}[$index]: $formattedItem';
          })
          .join('\n');
      return '\n$entries';
    } else if (value is bool || value is num) {
      return value.toString();
    } else {
      try {
        final jsonString = jsonEncode(value);
        final decoded = jsonDecode(jsonString);
        return _formatValue(decoded, indentLevel: indentLevel);
      } catch (e) {
        return value.toString();
      }
    }
  }

  bool _isDateTime(String value) {
    final dateTimePattern = RegExp(
      r'^\d{4}-\d{2}-\d{2}(T|\s)\d{2}:\d{2}:\d{2}(\.\d+)?([Z+|-]\d{2}:\d{2})?$',
    );
    return dateTimePattern.hasMatch(value);
  }
}

// Widget to handle audio playback
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
