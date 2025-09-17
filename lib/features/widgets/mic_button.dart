// lib/features/home/presentation/pages/widgets/mic_button.dart
import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import '../../../../utils/constants.dart'; // Assuming constants file with kPrimaryColor, kBorderColor, etc.

class MicButton extends StatefulWidget {
  final bool isListening;
  final String currentTranscriptChunk;
  final Function(AnimationController) onStart;
  final Function(AnimationController) onStop;

const MicButton({
    super.key,
    required this.isListening,
    required this.currentTranscriptChunk,
    required this.onStart,
    required this.onStop,
  });

  @override
  _MicButtonState createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(_pulseController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _pulseController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _pulseController.forward();
        }
      });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 120),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isListening ? kPrimaryColor : kBorderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(widget.isListening ? 0.2 : 0.1),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: widget.isListening ? kListeningBackground : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (widget.isListening) {
              widget.onStop(_pulseController);
            } else {
              widget.onStart(_pulseController);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: widget.isListening ? kPrimaryColor : kBorderColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.isListening ? kPrimaryDark : kBorderColor,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            widget.isListening ? FeatherIcons.micOff : FeatherIcons.mic,
                            size: 24,
                            color: widget.isListening ? Colors.white : kPrimaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isListening ? 'Listening...' : 'Talk to Maya',
                            style: kTitleStyle.copyWith(
                              color: widget.isListening ? kPrimaryColor : kTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.currentTranscriptChunk.isNotEmpty
                                ? widget.currentTranscriptChunk
                                : (widget.isListening
                                    ? 'Speak now, I\'m listening'
                                    : 'Tap to start a conversation'),
                            style: kBodyStyle.copyWith(
                              color: widget.currentTranscriptChunk.isNotEmpty
                                  ? kTextSecondary
                                  : kTextHint,
                              fontStyle: widget.currentTranscriptChunk.isNotEmpty
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                              backgroundColor: widget.currentTranscriptChunk.isNotEmpty
                                  ? kTranscriptBackground
                                  : null,
                            ),
                            maxLines: kMaxLines,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (widget.isListening)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        15,
                        (index) => Container(
                          width: 3,
                          height: 4 + (index % 5) * 3.0,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.3 + (index % 5) * 0.1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}