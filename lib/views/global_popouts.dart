import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class NoirPopouts {
  static final AudioPlayer _player = AudioPlayer();

  // Internal audio trigger
  static Future<void> _playBeep() async {
    try {
      await _player.play(AssetSource('sounds/beep.mp3'));
    } catch (e) {
      debugPrint("Audio play failed: $e");
    }
  }

  /// 1. TOP TOAST: Auto-dismissing system notification
  static void showToast(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    _playBeep();
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: _NoirToastWidget(
          message: message,
          isError: isError,
          onDismiss: () => overlayEntry.remove(),
        ),
      ),
    );
    overlayState.insert(overlayEntry);
  }

  /// 2. PROTOCOL DIALOG: Standard information alert
  static void showProtocolDialog(
    BuildContext context, {
    required String title,
    required String body,
    VoidCallback? onConfirm,
  }) {
    _playBeep();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "DISMISS",
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return _buildTerminalTransition(animation, child);
      },
      pageBuilder: (context, anim1, anim2) =>
          _NoirDialogWidget(title: title, body: body, onConfirm: onConfirm),
    );
  }

  /// 3. CONFIRM ACTION: Returns bool (Check = true, X = false)
  static Future<bool> showConfirmAction(
    BuildContext context, {
    required String title,
    required String body,
    Color confirmColor = const Color(0xFF00FF41),
    Color denyColor = const Color(0xFFFF4444),
  }) async {
    _playBeep();
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: "CONFIRM",
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return _buildTerminalTransition(animation, child);
      },
      pageBuilder: (context, anim1, anim2) => _NoirDialogWidget(
        title: title,
        body: body,
        isConfirmation: true,
        confirmColor: confirmColor,
        denyColor: denyColor,
      ),
    );
    return result ?? false;
  }

  /// 4. RATING SELECTOR: Priority/Rating Input 1-4
  static Future<int?> showRatingSelector(
    BuildContext context, {
    required String title,
    int initialRating = 0,
  }) async {
    _playBeep();
    return await showGeneralDialog<int>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "CANCEL",
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return _buildTerminalTransition(animation, child);
      },
      pageBuilder: (context, anim1, anim2) =>
          _NoirRatingWidget(title: title, initialRating: initialRating),
    );
  }

  static Future<void> triggerRandomFeedback(
    BuildContext context,
    String featureName, {
    double probability = 1.0,
  }) async {
    final double roll = Random().nextDouble();

    if (roll <= probability) {
      // Wait slightly for that terminal "processing" feel
      await Future.delayed(const Duration(milliseconds: 500));

      // Call the rating selector instead of the confirm action
      final int? rating = await showRatingSelector(
        context,
        title: "SENTIMENT: $featureName",
      );

      // Handle the return value (null means they backed out without confirming)
      if (rating != null) {
        // Logic: 3 or 4 is positive, 1 or 2 is negative
        if (rating >= 3) {
          showToast(context, "LVL_$rating SENTIMENT LOGGED: POSITIVE");
        } else {
          showToast(
            context,
            "LVL_$rating SENTIMENT LOGGED: NEGATIVE",
            isError: true,
          );
        }
      }
    }
  }

  // Slam transition with elastic bounce
  static Widget _buildTerminalTransition(
    Animation<double> animation,
    Widget child,
  ) {
    final curvedValue = Curves.elasticOut.transform(animation.value) - 1.0;
    return Transform(
      transform: Matrix4.translationValues(0.0, curvedValue * -20, 0.0),
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}

// --- GLITCH ANIMATION WIDGET ---
class _GlitchText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _GlitchText(this.text, {required this.style});

  @override
  State<_GlitchText> createState() => _GlitchTextState();
}

class _GlitchTextState extends State<_GlitchText> {
  late Timer _timer;
  String _displayState = "";
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _displayState = widget.text;
    _timer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (_random.nextInt(10) > 8) {
        setState(() => _displayState = _generateGlitch(widget.text));
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) setState(() => _displayState = widget.text);
        });
      }
    });
  }

  String _generateGlitch(String input) {
    const chars = r'!@#$%-+_<>';
    List<String> result = input.split('');
    for (int i = 0; i < (input.length / 5).clamp(1, 3); i++) {
      result[_random.nextInt(result.length)] =
          chars[_random.nextInt(chars.length)];
    }
    return result.join('');
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(_displayState, style: widget.style);
  }
}

// --- TOAST UI ---
class _NoirToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _NoirToastWidget({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  State<_NoirToastWidget> createState() => _NoirToastWidgetState();
}

class _NoirToastWidgetState extends State<_NoirToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _offset = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.bounceOut));

    _controller.forward();
    Timer(const Duration(seconds: 3), () async {
      if (mounted) {
        await _controller.reverse();
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SlideTransition(
        position: _offset,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: widget.isError ? const Color(0xFFFF4444) : Colors.black,
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(4, 4)),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 6,
                    color: widget.isError
                        ? Colors.white
                        : const Color(0xFF00FF41),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _GlitchText(
                            widget.isError ? "CORE_ERROR" : "UPLINK_STABLE",
                            style: TextStyle(
                              color: widget.isError
                                  ? Colors.black
                                  : const Color(0xFF00FF41),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Text(
                            widget.message.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- DIALOG UI ---
class _NoirDialogWidget extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback? onConfirm;
  final bool isConfirmation;
  final Color confirmColor;
  final Color denyColor;

  const _NoirDialogWidget({
    required this.title,
    required this.body,
    this.onConfirm,
    this.isConfirmation = false,
    this.confirmColor = const Color(0xFF00FF41),
    this.denyColor = const Color(0xFFFF4444),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            border: Border.all(color: Colors.black, width: 4),
            boxShadow: const [
              BoxShadow(color: Colors.black, offset: Offset(10, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                color: Colors.black,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.terminal,
                      color: Color(0xFF00FF41),
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _GlitchText(
                            isConfirmation
                                ? "[ AUTH_LEVEL_REQUIRED ]"
                                : "[ SYSTEM_NOTICE ]",
                            style: const TextStyle(
                              color: Color(0xFF00FF41),
                              fontSize: 9,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Text(
                            title.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Text(
                  body,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF00FF41),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (isConfirmation)
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, false),
                        child: Container(
                          height: 60,
                          color: denyColor,
                          child: const Icon(
                            Icons.close_sharp,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, true),
                        child: Container(
                          height: 60,
                          color: confirmColor,
                          child: const Icon(
                            Icons.check_sharp,
                            color: Colors.black,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    if (onConfirm != null) onConfirm!();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    color: const Color(0xFF00FF41),
                    child: const Center(
                      child: Text(
                        "ACKNOWLEDGE",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- NEW RATING UI ---
class _NoirRatingWidget extends StatefulWidget {
  final String title;
  final int initialRating;

  const _NoirRatingWidget({required this.title, required this.initialRating});

  @override
  State<_NoirRatingWidget> createState() => _NoirRatingWidgetState();
}

class _NoirRatingWidgetState extends State<_NoirRatingWidget> {
  late int _currentRating;
  final Color _greenGlow = const Color(0xFF00FF41);

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            border: Border.all(color: Colors.black, width: 4),
            boxShadow: const [
              BoxShadow(color: Colors.black, offset: Offset(8, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER AREA
              Container(
                width: double.infinity,
                color: Colors.black,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GlitchText(
                      "[ USER_SENTIMENT_ANALYSIS ]",
                      style: TextStyle(
                        color: _greenGlow,
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.title.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),

              // RATING AREA
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 30,
                  horizontal: 20,
                ),
                child: Column(
                  children: [
                    const Text(
                      "INPUT_STRENGTH",
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 8,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(4, (index) {
                        final nodeValue = index + 1;
                        final isActive = nodeValue <= _currentRating;

                        return GestureDetector(
                          onTap: () =>
                              setState(() => _currentRating = nodeValue),
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 60,
                                height: 25,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? _greenGlow
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isActive
                                        ? _greenGlow
                                        : Colors.white12,
                                    width: 2,
                                  ),
                                  boxShadow: isActive
                                      ? [
                                          BoxShadow(
                                            color: _greenGlow.withOpacity(0.6),
                                            blurRadius: 10,
                                          ),
                                          BoxShadow(
                                            color: _greenGlow.withOpacity(0.2),
                                            blurRadius: 20,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Center(
                                  child: Text(
                                    "0$nodeValue",
                                    style: TextStyle(
                                      color: isActive
                                          ? Colors.black
                                          : Colors.white24,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 2,
                                height: 4,
                                color: isActive ? _greenGlow : Colors.white10,
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              // FOOTER CONFIRMATION
              GestureDetector(
                onTap: () => Navigator.pop(context, _currentRating),
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _currentRating > 0
                        ? _greenGlow
                        : const Color(0xFF1A1A1A),
                    border: Border(
                      top: BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _currentRating > 0 ? "UPLOAD_DATA" : "AWAITING_INPUT",
                      style: TextStyle(
                        color: _currentRating > 0
                            ? Colors.black
                            : Colors.white24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
