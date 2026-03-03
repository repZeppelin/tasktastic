import 'package:finaltasktastic/pages/landing_page/credits.dart';
import 'package:finaltasktastic/pages/landing_page/login_page.dart';
import 'package:finaltasktastic/pages/landing_page/support.dart';
import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  final List<Map<String, dynamic>> menuButtons = const [
    {
      'title': 'BEGIN ADVENTURE',
      'icon': Icons.play_arrow,
      'page': LoginPage(),
    },
    {
      'title': 'CREDITS',
      'icon': Icons.cottage,
      'page': CreditsPage(),
    },
    {
      'title': 'SUPPORT',
      'icon': Icons.headphones,
      'page': SupportPage(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.note_add, size: 80, color: Colors.black),
                const Text(
                  'tasktastic',
                  style: TextStyle(
                    fontSize: 45,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
                ),
                const Text(
                  'LEVEL UP YOUR PRODUCTIVITY',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 60),

                // Map your buttons to the Hover component
                ...menuButtons.map((item) => NoirHoverButton(item: item)),
                
                const SizedBox(height: 20),
                const Text(
                  "v 1.0.4",
                  style: TextStyle(
                    fontSize: 10, 
                    color: Colors.grey, 
                    fontWeight: FontWeight.bold
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NoirHoverButton extends StatefulWidget {
  final Map<String, dynamic> item;
  const NoirHoverButton({super.key, required this.item});

  @override
  State<NoirHoverButton> createState() => _NoirHoverButtonState();
}

class _NoirHoverButtonState extends State<NoirHoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isPrimary = widget.item['title'] == 'BEGIN ADVENTURE';

    // 1. Invert Logic: 
    // If Primary: Start Black -> Hover White
    // If others: Start White -> Hover Black
    final Color bgColor = isPrimary 
        ? (_isHovered ? Colors.white : Colors.black) 
        : (_isHovered ? Colors.black : Colors.white);
    
    final Color contentColor = isPrimary 
        ? (_isHovered ? Colors.black : Colors.white) 
        : (_isHovered ? Colors.white : Colors.black);

    return Padding(
      // Increased bottom padding to 20 to prevent shadow/scale clipping
      padding: const EdgeInsets.only(bottom: 20), 
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => widget.item['page']),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutQuart,
            width: 250,
            // 2. SCALE EFFECT: Grow by 5% on hover
            transform: _isHovered 
                ? (Matrix4.identity()..scale(1.05)) 
                : Matrix4.identity(),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(color: Colors.black, width: 3),
              // 3. SHARP OFFSET SHADOW: Only visible when hovered
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  offset: _isHovered ? const Offset(6, 6) : const Offset(0, 0),
                  blurRadius: 0, 
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  widget.item['title'],
                  style: TextStyle(
                    color: contentColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Icon(
                  widget.item['icon'],
                  color: contentColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}