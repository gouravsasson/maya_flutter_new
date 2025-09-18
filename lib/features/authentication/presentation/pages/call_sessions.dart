import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import 'package:my_flutter_app/core/network/api_client.dart';

class Session {
  final int id;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final int userId;
  final int agentId;
  final int duration;
  final int billedDuration;
  final String transcription;
  final String shortSummary;
  final String summary;
  final List<dynamic> toolCalls;
  final String thunderSessionId;

  Session({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    required this.userId,
    required this.agentId,
    required this.duration,
    required this.billedDuration,
    required this.transcription,
    required this.shortSummary,
    required this.summary,
    required this.toolCalls,
    required this.thunderSessionId,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['ID'] as int,
      createdAt: DateTime.parse(json['CreatedAt'] as String),
      updatedAt: json['UpdatedAt'] != null
          ? DateTime.parse(json['UpdatedAt'] as String)
          : null,
      deletedAt: json['DeletedAt'] != null
          ? DateTime.parse(json['DeletedAt'] as String)
          : null,
      userId: json['user_id'] as int,
      agentId: json['agent_id'] as int,
      duration: json['duration'] as int,
      billedDuration: json['billed_duration'] as int,
      transcription: json['transcription'] as String? ?? '',
      shortSummary: json['short_summary'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      toolCalls: json['tool_calls'] as List<dynamic>? ?? [],
      thunderSessionId: json['thunder_session_id'] as String? ?? '',
    );
  }
}

class CallSessionsPage extends StatefulWidget {
  const CallSessionsPage({super.key});

  @override
  _CallSessionsPageState createState() => _CallSessionsPageState();
}

class _CallSessionsPageState extends State<CallSessionsPage> {
  final apiClient = getIt<ApiClient>();
  List<Session> sessions = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  String? errorMessage;
  int currentPage = 1;
  int pageSize = 20;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    fetchSessions(isLoadMore: false);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!isLoadingMore && hasMore) {
        // Debounce scroll events to prevent multiple triggers
        if (_debounce?.isActive ?? false) _debounce!.cancel();
        _debounce = Timer(const Duration(milliseconds: 300), () {
          fetchSessions(isLoadMore: true);
        });
      }
    }
  }

  Future<void> fetchSessions({required bool isLoadMore}) async {
    if (isLoadMore && isLoadingMore) return;

    setState(() {
      if (isLoadMore) {
        isLoadingMore = true;
      } else {
        isLoading = true;
        errorMessage = null;
        sessions.clear();
        currentPage = 1;
        hasMore = true;
      }
    });

    try {
      final response = await apiClient.fetchCallSessions(
        page: isLoadMore ? currentPage + 1 : currentPage,
      );

      if (response['statusCode'] == 200 &&
          response['data']['success'] == true) {
        final newSessions = (response['data']['data'] as List<dynamic>? ?? [])
            .map((json) => Session.fromJson(json as Map<String, dynamic>))
            .toList();

        setState(() {
          if (isLoadMore) {
            sessions.addAll(newSessions);
          } else {
            sessions = newSessions;
          }
          hasMore = newSessions.length == pageSize;
          currentPage = isLoadMore ? currentPage + 1 : currentPage;
          isLoading = false;
          isLoadingMore = false;
        });
      } else {
        setState(() {
          errorMessage =
              response['data']['message'] ?? 'Failed to load sessions';
          isLoading = false;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching sessions: $e';
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  String formatDate(DateTime dateTime) {
    return DateFormat.yMMMd().add_jm().format(dateTime.toLocal());
  }

  String formatDuration(int seconds) {
    return '${(seconds / 60).toStringAsFixed(2)} min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Sessions'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchSessions(isLoadMore: false);
        },
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      errorMessage!,
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => fetchSessions(isLoadMore: false),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : sessions.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No sessions found',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => fetchSessions(isLoadMore: false),
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: hasMore ? sessions.length + 1 : sessions.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index >= sessions.length) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: isLoadingMore
                            ? const CircularProgressIndicator()
                            : TextButton(
                                onPressed: () =>
                                    fetchSessions(isLoadMore: true),
                                child: const Text('Load More'),
                              ),
                      ),
                    );
                  }
                  final session = sessions[index];
                  return ListTile(
                    leading: const Icon(
                      FeatherIcons.phone,
                      color: Color(0xFF6366F1),
                    ),
                    title: Text(
                      formatDate(session.createdAt),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Duration: ${formatDuration(session.duration)}\n'
                      'Billed Duration: ${formatDuration(session.billedDuration)}',
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SessionDetailsPage(session: session),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class SessionDetailsPage extends StatelessWidget {
  final Session session;

  const SessionDetailsPage({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Date: ${DateFormat.yMMMd().add_jm().format(session.createdAt.toLocal())}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              const Text(
                'Summary:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                session.summary.isEmpty
                    ? 'No summary available'
                    : session.summary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Short Summary:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                session.shortSummary.isEmpty
                    ? 'No short summary available'
                    : session.shortSummary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Transcription:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                session.transcription.isEmpty
                    ? 'No transcription available'
                    : session.transcription,
              ),
              const SizedBox(height: 16),
              const Text(
                'Tool Calls:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                session.toolCalls.isEmpty
                    ? 'No tool calls'
                    : session.toolCalls
                          .map((call) => call.toString())
                          .join('\n'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
