import 'dart:async';
import 'dart:ui';

class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  void run(VoidCallback action) {
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer(delay, action); // Start a new timer
  }

  void cancel() {
    _timer?.cancel();
  }
}