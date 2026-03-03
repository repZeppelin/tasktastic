import 'package:finaltasktastic/views/global_popouts.dart';
import 'package:flutter/material.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_sharp, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "NETWORK_SUPPORT",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "STRENGTHEN_THE_SIGNAL",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, height: 1),
            ),
            const SizedBox(height: 8),
            const Text(
              "Help keep the servers running and the code clean.",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 32),
            _buildSupportAction(
              label: "JOIN_DISCORD",
              sub: "Community & Updates",
              icon: Icons.discord,
              color: const Color(0xFF5865F2),
              onTap: () {
                NoirPopouts.showProtocolDialog(context, title: "Sorry!", body: "No discord yet!");
              },
            ),
            const SizedBox(height: 16),
            _buildSupportAction(
              label: "DONATE_CC",
              sub: "Support Development",
              icon: Icons.coffee_sharp,
              color: Colors.orange[800]!,
              onTap: () {
                NoirPopouts.showProtocolDialog(context, title: "No need!", body: "No funding needed yet.");
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportAction({
    required String label,
    required String sub,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black, offset: Offset(6, 6))],
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 3),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black,
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    Text(
                      sub,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_sharp, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}