import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;

import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // GoRouter handles navigation automatically through redirect logic
        print('📱 Splash: Auth state changed to ${state.runtimeType}');
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Background gradients
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[100]!,
                    Colors.purple[100]!,
                    Colors.pink[100]!,
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [
                    Colors.blue[200]!.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Orb
                  _AnimatedOrb(),
                  SizedBox(height: 32),
                  // App Name
                  Text(
                    'Maya',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..shader = LinearGradient(
                          colors: [
                            Colors.blue[600]!,
                            Colors.purple[600]!,
                            Colors.pink[600]!,
                          ],
                        ).createShader(Rect.fromLTWH(0, 0, 200, 70)),
                    ),
                  ),
                  SizedBox(height: 8),
                  // Subtitle
                  Text(
                    'Your AI Personal Assistant',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 32),
                  // Loading Animation
                  _BouncingDots(),
                  SizedBox(height: 20),
                  // Loading Text
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      String loadingText = 'Initializing...';
                      if (state is AuthLoading) {
                        loadingText = 'Checking authentication...';
                      }
                      return Text(
                        loadingText,
                        style: TextStyle(
                          color: Colors.grey[600]!.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Animated Orb Widget
class _AnimatedOrb extends StatefulWidget {
  @override
  __AnimatedOrbState createState() => __AnimatedOrbState();
}

class __AnimatedOrbState extends State<_AnimatedOrb> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      height: 128,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background blur effect
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue[300]!.withOpacity(0.5),
                  Colors.purple[300]!.withOpacity(0.5),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 24,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
          // Main orb
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue[400]!, Colors.purple[500]!],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.star,
              size: 48,
              color: Colors.white,
            ),
          ),
          // Orbiting particles
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * 2 * math.pi,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 64 - 6,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue[400],
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 64 - 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.purple[400],
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
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
    );
  }
}

// Bouncing Dots Widget
class _BouncingDots extends StatefulWidget {
  @override
  __BouncingDotsState createState() => __BouncingDotsState();
}

class __BouncingDotsState extends State<_BouncingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _animations = [
      Tween<double>(begin: 0, end: -10).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(0.0, 0.7, curve: Curves.easeOut),
        ),
      ),
      Tween<double>(begin: 0, end: -10).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(0.15, 0.85, curve: Curves.easeOut),
        ),
      ),
      Tween<double>(begin: 0, end: -10).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(0.3, 1.0, curve: Curves.easeOut),
        ),
      ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animations[index].value),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.blue[400]!, Colors.purple[500]!],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}