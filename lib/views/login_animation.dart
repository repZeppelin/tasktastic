import 'dart:async';
import 'package:flutter/material.dart';

class NoirWelcomeOverlay extends StatefulWidget {
  final String username;
  final VoidCallback onComplete;

  const NoirWelcomeOverlay({
    super.key, 
    required this.username, 
    required this.onComplete
  });

  @override
  State<NoirWelcomeOverlay> createState() => _NoirWelcomeOverlayState();
}

class _NoirWelcomeOverlayState extends State<NoirWelcomeOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showText = false;
  bool _isGlitching = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _startSequence();
  }

  void _startSequence() async {
    // 1. Slide the black bar in
    await _controller.forward();
    setState(() => _showText = true);
    
    // 2. Trigger a few random glitches
    for (int i = 0; i < 3; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) setState(() => _isGlitching = !_isGlitching);
    }
    setState(() => _isGlitching = false);

    // 3. Hold, then fade out and close
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      await _controller.reverse();
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // The Sliding "Scanner" Bar
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Center(
                child: Container(
                  height: 100 * _controller.value, // Vertical expansion
                  width: double.infinity,
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: _showText ? _buildGlitchText() : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGlitchText() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Main Text
        Text(
          "WELCOME, ${widget.username.toUpperCase()}",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            fontFamily: 'monospace',
          ),
        ),
        // Glitch Ghost (Cyan)
        if (_isGlitching)
          Transform.translate(
            offset: const Offset(-4, 2),
            child: Text(
              "WELCOME, ${widget.username.toUpperCase()}",
              style: TextStyle(
                color: Colors.cyan.withOpacity(0.5),
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                fontFamily: 'monospace',
              ),
            ),
          ),
      ],
    );
  }
}