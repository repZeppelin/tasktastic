import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

/// --- 1. THE STACKING & COUNT MANAGER (Logic remains the same) ---

class _NoirStackManager {
  static final List<_NoirEntry> activeTopEntries = [];
  static final List<_NoirEntry> activeBottomEntries = [];

  static double getOffset(bool isTop, Key key) {
    final list = isTop ? activeTopEntries : activeBottomEntries;
    double offset = 0;
    for (var entry in list) {
      if (entry.key == key) break;
      offset += entry.height + 2;
    }
    return offset;
  }

  static _NoirEntry? findDuplicate(String message, bool isTop) {
    final list = isTop ? activeTopEntries : activeBottomEntries;
    try {
      return list.firstWhere((e) => e.message == message);
    } catch (_) {
      return null;
    }
  }
}

class _NoirEntry {
  final Key key;
  final String message;
  final double height = 75.0; // Slightly taller for the new header
  int count = 1;
  Function()? onUpdate;
  Function()? onResetTimer;

  _NoirEntry(this.key, this.message);
}

/// --- 2. PUBLIC API ---

void showTopSnackBar(BuildContext context, String message, Color color) {
  _handleLogic(context, message, color, isTop: true, isTranslucent: false);
}

void showBottomSnackBar(BuildContext context, String message, Color color) {
  _handleLogic(context, message, color, isTop: false, isTranslucent: false);
}

void showTopTranslucent(BuildContext context, String message, Color color) {
  _handleLogic(context, message, color, isTop: true, isTranslucent: true);
}

void showBottomTranslucent(BuildContext context, String message, Color color) {
  _handleLogic(context, message, color, isTop: false, isTranslucent: true);
}

/// --- 3. INTERNAL ENGINE ---

void _handleLogic(
  BuildContext context,
  String message,
  Color color, {
  required bool isTop,
  required bool isTranslucent,
}) {
  final existing = _NoirStackManager.findDuplicate(message, isTop);

  if (existing != null) {
    existing.count++;
    if (existing.onUpdate != null) existing.onUpdate!();
    if (existing.onResetTimer != null) existing.onResetTimer!();
    return;
  }

  _insertOverlay(context, message, color, isTop, isTranslucent);
}

void _insertOverlay(
  BuildContext context,
  String message,
  Color color,
  bool isTop,
  bool isTranslucent,
) {
  final overlay = Overlay.of(context);
  final animationKey = GlobalKey<_NoirAnimationWrapperState>();
  final entryKey = UniqueKey();
  final entry = _NoirEntry(entryKey, message);

  late OverlayEntry overlayEntry;

  Future<void> removeSequence() async {
    if (animationKey.currentState != null) {
      await animationKey.currentState!.reverse();
    }

    if (isTop) {
      _NoirStackManager.activeTopEntries.removeWhere((e) => e.key == entryKey);
    } else {
      _NoirStackManager.activeBottomEntries.removeWhere((e) => e.key == entryKey);
    }

    overlay.setState(() {});
    overlayEntry.remove();
  }

  if (isTop) {
    _NoirStackManager.activeTopEntries.add(entry);
  } else {
    _NoirStackManager.activeBottomEntries.add(entry);
  }

  overlayEntry = OverlayEntry(
    builder: (context) => _StackingPositioner(
      isTop: isTop,
      entry: entry,
      onTriggerRemoval: removeSequence,
      child: Material(
        color: Colors.transparent,
        child: NoirAnimationWrapper(
          key: animationKey,
          isTop: isTop,
          child: isTranslucent
              ? _NoirTranslucentWidget(message: message, color: color, entry: entry)
              : _NoirSolidWidget(message: message, color: color, entry: entry),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);
}

/// --- 4. SHARED UI ELEMENTS (GLITCH & BADGE) ---

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
      result[_random.nextInt(result.length)] = chars[_random.nextInt(chars.length)];
    }
    return result.join('');
  }

  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) { return Text(_displayState, style: widget.style); }
}

class _CounterBadge extends StatelessWidget {
  final int count;
  const _CounterBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF00FF41),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Text(
          "x$count",
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

/// --- 5. UPDATED NOIR UI COMPONENTS ---
/// 
/// --- 5. UNIFIED NOIR UI COMPONENTS ---

class _NoirSolidWidget extends StatelessWidget {
  final String message;
  final Color color;
  final _NoirEntry entry;
  const _NoirSolidWidget({required this.message, required this.color, required this.entry});

  @override
  Widget build(BuildContext context) {
    const boxGrey = Color(0xFF2A2A2A);
    const greenGlow = Color(0xFF00FF41);

    // We use a Stack with Clip.none at the VERY top level 
    // so the badge can breathe outside the box.
    return Stack(
      clipBehavior: Clip.none, 
      children: [
        // 1. THE BOX (With its own internal clipping for the blur)
        ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              decoration: BoxDecoration(
                color: boxGrey.withOpacity(0.96),
                border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    offset: const Offset(6, 6),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Accent Bar
                  Container(
                    height: 2,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: color,
                      boxShadow: [BoxShadow(color: color, blurRadius: 8)],
                    ),
                  ),
                  // Content Padding
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _GlitchText(">>", style: TextStyle(
                          color: color, 
                          fontWeight: FontWeight.bold, 
                          fontFamily: 'monospace',
                          fontSize: 14,
                          shadows: [Shadow(color: color, blurRadius: 8)],
                        )),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message.toUpperCase(),
                            style: TextStyle(
                              color: greenGlow,
                              fontFamily: 'monospace',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              height: 1.2, // Fixes vertical alignment
                              shadows: [
                                Shadow(blurRadius: 4.0, color: greenGlow.withOpacity(0.7)),
                                Shadow(blurRadius: 12.0, color: greenGlow.withOpacity(0.4)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // 2. THE BADGE (Positioned outside the ClipRRect)
        StatefulBuilder(
          builder: (context, setBadgeState) {
            entry.onUpdate = () => setBadgeState(() {});
            return entry.count > 1
                ? Positioned(
                    bottom: -10, 
                    right: -10, 
                    child: _CounterBadge(count: entry.count),
                  )
                : const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

class _NoirTranslucentWidget extends StatelessWidget {
  final String message;
  final Color color;
  final _NoirEntry entry;
  const _NoirTranslucentWidget({required this.message, required this.color, required this.entry});

  @override
  Widget build(BuildContext context) {
    const boxGrey = Color(0xFF333333);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                // Lower opacity for the true translucent look
                color: boxGrey.withOpacity(0.7),
                border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 2, 
                    width: double.infinity, 
                    decoration: BoxDecoration(
                      color: color,
                      boxShadow: [BoxShadow(color: color, blurRadius: 10)]
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        _GlitchText(">>", style: TextStyle(
                          color: color, 
                          fontWeight: FontWeight.bold, 
                          fontFamily: 'monospace',
                          shadows: [Shadow(color: color, blurRadius: 12)],
                        )),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'monospace',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(blurRadius: 15, color: Colors.white24),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            StatefulBuilder(
              builder: (context, setBadgeState) {
                entry.onUpdate = () => setBadgeState(() {});
                return entry.count > 1
                    ? Positioned(bottom: -8, right: -8, child: _CounterBadge(count: entry.count))
                    : const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// --- 6. POSITIONER & WRAPPERS (Unchanged logic, updated heights) ---

class _StackingPositioner extends StatefulWidget {
  final bool isTop;
  final _NoirEntry entry;
  final Widget child;
  final Future<void> Function() onTriggerRemoval;

  const _StackingPositioner({
    required this.isTop,
    required this.entry,
    required this.child,
    required this.onTriggerRemoval,
  });

  @override
  State<_StackingPositioner> createState() => _StackingPositionerState();
}

class _StackingPositionerState extends State<_StackingPositioner> {
  late DateTime _expiry;
  bool _isRemoving = false;

  @override
  void initState() {
    super.initState();
    _resetTimer();
    widget.entry.onResetTimer = _resetTimer;
    widget.entry.onUpdate = () { if (mounted) setState(() {}); };
  }

  void _resetTimer() {
    _expiry = DateTime.now().add(const Duration(seconds: 3));
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted || _isRemoving) return;
      if (DateTime.now().isAfter(_expiry) || DateTime.now().isAtSameMomentAs(_expiry)) {
        _isRemoving = true;
        widget.onTriggerRemoval();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      tween: Tween<double>(
        begin: 0,
        end: _NoirStackManager.getOffset(widget.isTop, widget.entry.key),
      ),
      builder: (context, offset, child) {
        return Positioned(
          top: widget.isTop ? (60 + offset) : null,
          bottom: widget.isTop ? null : (60 + offset),
          left: 15,
          right: 15,
          child: child!,
        );
      },
      child: widget.child,
    );
  }
}

class NoirAnimationWrapper extends StatefulWidget {
  final Widget child;
  final bool isTop;
  const NoirAnimationWrapper({super.key, required this.child, required this.isTop});

  @override
  State<NoirAnimationWrapper> createState() => _NoirAnimationWrapperState();
}

class _NoirAnimationWrapperState extends State<NoirAnimationWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _offsetAnimation = Tween<Offset>(
      begin: Offset(0, widget.isTop ? -2.0 : 2.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  Future<void> reverse() async { if (mounted) await _controller.reverse(); }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _offsetAnimation, child: widget.child),
    );
  }
}