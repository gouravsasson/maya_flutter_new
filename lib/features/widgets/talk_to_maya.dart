// lib/features/home/presentation/pages/widgets/talk_to_maya.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:Maya/core/network/api_client.dart';
import 'package:Maya/core/services/mic_service.dart';
import 'package:Maya/utils/constants.dart';
import 'package:ultravox_client/ultravox_client.dart';

import 'mic_button.dart';

class TalkToMaya extends StatefulWidget {
  const TalkToMaya({super.key});

  @override
  State<TalkToMaya> createState() => _TalkToMayaState();
}

class _TalkToMayaState extends State<TalkToMaya>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  String _currentTranscriptChunk = '';
  final List<String> _transcriptChunks = [];
  UltravoxSession? _session;
  String _previousStatus = '';
  AnimationController? _pulseController;

  final ApiClient _apiClient = GetIt.instance<ApiClient>();

  @override
  void initState() {
    super.initState();
    _session = UltravoxSession.create();
  }

  @override
  void dispose() {
    _session?.leaveCall();
    _session = null;
    super.dispose();
  }

  void _onStatusChange() {
    UltravoxSessionStatus current = _session!.status;
    setState(() {});
    if (current == 'idle' && _previousStatus == 'speaking') {
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _currentTranscriptChunk = '';
          _transcriptChunks.clear();
          _isListening = false;
        });
      });
    }
    _previousStatus = current as String;
  }

  void _onDataMessage() {
    final message = _session!.lastDataMessage;
    if (message['type'] == 'transcript') {
      setState(() {
        final lastTranscript = _session!.transcripts.last;
        String newText = lastTranscript.speaker == Role.user
            ? lastTranscript.text
            : (_currentTranscriptChunk.isNotEmpty
                  ? '$_currentTranscriptChunk ${lastTranscript.text}'
                  : lastTranscript.text);

        while (newText.length > kMaxDisplayLength) {
          _transcriptChunks.add(newText.substring(0, kMaxDisplayLength));
          newText = newText.substring(kMaxDisplayLength);
        }
        _transcriptChunks.add(newText);

        _currentTranscriptChunk = _transcriptChunks.last;
        if (_transcriptChunks.length > 5) {
          _transcriptChunks.removeAt(0);
        }
      });
    }
  }

  Future<void> _onStart(AnimationController pulseController) async {
    bool granted = await MicrophonePermissionHandler.requestPermission();
    if (!granted) {
      setState(() {
        _currentTranscriptChunk = 'Microphone permission denied';
      });
      return;
    }

    setState(() {
      _isListening = true;
      _currentTranscriptChunk = '';
      _transcriptChunks.clear();
    });
    _pulseController = pulseController;
    pulseController.forward();

    try {
      final payload = _apiClient.prepareStartThunderPayload('main');
      final response = await _apiClient.startThunder(payload['agent_type']);
      if (response['statusCode'] == 200) {
        final data = response['data']['data'];
        String joinUrl = data['joinUrl'];

        await _session!.joinCall(joinUrl);
        _session!.micMuted = false;
        _session!.speakerMuted = false;
        _session!.statusNotifier.addListener(_onStatusChange);
        _session!.dataMessageNotifier.addListener(_onDataMessage);
      } else {
        setState(() {
          _currentTranscriptChunk =
              'Error starting session: ${response['statusCode']}';
        });
        _onStop(pulseController);
      }
    } catch (e) {
      setState(() {
        _currentTranscriptChunk = 'Error: $e';
      });
      _onStop(pulseController);
    }
  }

  void _onStop(AnimationController pulseController) {
    if (_session != null) {
      _session!.micMuted = true;
      _session!.leaveCall();
      _session!.statusNotifier.removeListener(_onStatusChange);
      _session!.dataMessageNotifier.removeListener(_onDataMessage);
    }
    setState(() {
      _isListening = false;
    });
    pulseController.stop();
    pulseController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Talk to Maya',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF424242),
          ),
        ),
        const SizedBox(height: 16),
        MicButton(
          isListening: _isListening,
          currentTranscriptChunk: _currentTranscriptChunk,
          onStart: _onStart,
          onStop: _onStop,
        ),
      ],
    );
  }
}
