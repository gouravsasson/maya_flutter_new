import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:Maya/core/network/api_client.dart';
import 'package:Maya/core/services/mic_service.dart';
import 'package:Maya/utils/constants.dart';
import 'package:ultravox_client/ultravox_client.dart';

class TalkToMaya extends StatefulWidget {
  const TalkToMaya({super.key});

  @override
  State<TalkToMaya> createState() => _TalkToMayaState();
}

class _TalkToMayaState extends State<TalkToMaya>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  bool _isMicMuted = false;
  bool _isSpeakerMuted = false;
  String _currentTranscriptChunk = '';
  final List<Map<String, dynamic>> _conversation = [];
  String _inputValue = '';
  UltravoxSession? _session;
  String _previousStatus = '';
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  final ApiClient _apiClient = GetIt.instance<ApiClient>();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );
    _session = UltravoxSession.create();
  }

  @override
  void dispose() {
    _session?.leaveCall();
    _session?.statusNotifier.removeListener(_onStatusChange);
    _session?.dataMessageNotifier.removeListener(_onDataMessage);
    _session = null;
    _pulseController?.dispose();
    super.dispose();
  }

  void _onStatusChange() {
    UltravoxSessionStatus current = _session!.status;
    if (current == 'idle' && _previousStatus == 'speaking') {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _currentTranscriptChunk = '';
            _isListening = false;
          });
        }
      });
    }
    _previousStatus = current as String;
    if (mounted) {
      setState(() {});
    }
  }

  void _onDataMessage() {
    final message = _session!.lastDataMessage;
    if (message['type'] == 'transcript') {
      final lastTranscript = _session!.transcripts.last;
      if (mounted && lastTranscript.isFinal) {
        setState(() {
          _currentTranscriptChunk = lastTranscript.text;
          _conversation.add({
            'type': lastTranscript.speaker == Role.user ? 'user' : 'maya',
            'text': _currentTranscriptChunk,
          });
          _currentTranscriptChunk = '';
          if (_conversation.length > 10) {
            _conversation.removeAt(0);
          }
        });
      }
    }
  }

  Future<void> _onStart() async {
    bool granted = await MicrophonePermissionHandler.requestPermission();
    if (!granted) {
      if (mounted) {
        setState(() {
          _currentTranscriptChunk = 'Microphone permission denied';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isListening = true;
        _currentTranscriptChunk = '';
        _isMicMuted = false;
        _isSpeakerMuted = false;
      });
    }
    _pulseController?.repeat();

    try {
      final payload = _apiClient.prepareStartThunderPayload('main');
      final response = await _apiClient.startThunder(payload['agent_type']);
      if (response['statusCode'] == 200) {
        final data = response['data']['data'];
        String joinUrl = data['joinUrl'];

        await _session!.joinCall(joinUrl);
        _session!.micMuted = _isMicMuted;
        _session!.speakerMuted = _isSpeakerMuted;
        _session!.statusNotifier.addListener(_onStatusChange);
        _session!.dataMessageNotifier.addListener(_onDataMessage);
      } else {
        if (mounted) {
          setState(() {
            _currentTranscriptChunk =
                'Error starting session: ${response['statusCode']}';
          });
        }
        _onStop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentTranscriptChunk = 'Error: $e';
        });
      }
      _onStop();
    }
  }

  void _onStop() {
    if (_session != null) {
      _session!.micMuted = true;
      _session!.speakerMuted = true;
      _session!.leaveCall();
      _session!.statusNotifier.removeListener(_onStatusChange);
      _session!.dataMessageNotifier.removeListener(_onDataMessage);
    }
    if (mounted) {
      setState(() {
        _isListening = false;
        _currentTranscriptChunk = '';
      });
    }
    _pulseController?.stop();
  }

  void _toggleMicMute() {
    if (mounted) {
      setState(() {
        _isMicMuted = !_isMicMuted;
        _session?.micMuted = _isMicMuted;
      });
    }
  }

  void _toggleSpeakerMute() {
    if (mounted) {
      setState(() {
        _isSpeakerMuted = !_isSpeakerMuted;
        _session?.speakerMuted = _isSpeakerMuted;
      });
    }
  }

  void _handleSendMessage() {
    if (_inputValue.trim().isEmpty || _isListening) return;
    if (mounted) {
      setState(() {
        _conversation.add({'type': 'user', 'text': _inputValue});
        _conversation.add({
          'type': 'maya',
          'text': 'I understand. Let me help you with that right away!'
        });
        _inputValue = '';
        _session?.sendText(_inputValue);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.purple.shade50],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Floating Orb with Animation
              Expanded(
                flex: 2,
                child: Center(
                  child: GestureDetector(
                    onTap: _isListening ? _onStop : _onStart,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Large Pulse Ring
                        if (_isListening)
                          AnimatedBuilder(
                            animation: _pulseAnimation!,
                            builder: (context, child) {
                              return Container(
                                width: 300 * _pulseAnimation!.value,
                                height: 300 * _pulseAnimation!.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue.shade200.withOpacity(0.3),
                                ),
                              );
                            },
                          ),
                        // Medium Pulse Ring
                        if (_isListening)
                          AnimatedBuilder(
                            animation: _pulseAnimation!,
                            builder: (context, child) {
                              return Container(
                                width: 250 * _pulseAnimation!.value,
                                height: 250 * _pulseAnimation!.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue.shade300.withOpacity(0.4),
                                ),
                              );
                            },
                          ),
                        // Small Pulse Ring
                        if (_isListening)
                          AnimatedBuilder(
                            animation: _pulseAnimation!,
                            builder: (context, child) {
                              return Container(
                                width: 200 * _pulseAnimation!.value,
                                height: 200 * _pulseAnimation!.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue.shade400.withOpacity(0.5),
                                ),
                              );
                            },
                          ),
                        // Core Orb
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: _isListening
                                  ? [Colors.blue.shade600, Colors.purple.shade600]
                                  : [Colors.blue.shade300, Colors.purple.shade300],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Conversation and Controls
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    // Mute Controls
                    if (_isListening)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(
                                _isMicMuted ? Icons.mic_off : Icons.mic,
                                color: _isMicMuted ? Colors.grey : Colors.blue,
                              ),
                              onPressed: _toggleMicMute,
                            ),
                            IconButton(
                              icon: Icon(
                                _isSpeakerMuted ? Icons.volume_off : Icons.volume_up,
                                color: _isSpeakerMuted ? Colors.grey : Colors.blue,
                              ),
                              onPressed: _toggleSpeakerMute,
                            ),
                          ],
                        ),
                      ),

                    // Conversation List
                    if (_conversation.isNotEmpty)
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: _conversation.asMap().entries.map((entry) {
                              final msg = entry.value;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Align(
                                  alignment: msg['type'] == 'user'
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: msg['type'] == 'user'
                                          ? Colors.blue.shade100
                                          : Colors.purple.shade100,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      msg['text'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                    // Transcript Display
                    if (_currentTranscriptChunk.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white.withOpacity(0.1),
                            border: Border.all(color: Colors.blue.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Listening: ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _currentTranscriptChunk,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Input and Send Button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white.withOpacity(0.1),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                enabled: !_isListening,
                                onChanged: (value) {
                                  setState(() {
                                    _inputValue = value;
                                  });
                                },
                                onSubmitted: (_) => _handleSendMessage(),
                                decoration: InputDecoration(
                                  hintText: 'Type your message...',
                                  hintStyle: TextStyle(color: Colors.grey.shade500),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _handleSendMessage,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: _inputValue.trim().isEmpty || _isListening
                                      ? [Colors.grey.shade300, Colors.grey.shade400]
                                      : [Colors.blue.shade400, Colors.purple.shade500],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.send,
                                size: 24,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}