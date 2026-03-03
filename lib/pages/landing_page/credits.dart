import 'package:flutter/material.dart';

class CreditsPage extends StatelessWidget {
  const CreditsPage({super.key});

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
          "SYSTEM_CREDITS",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildCreditBlock("LEADER", "NORMAN G. SANIDAD"),
          const SizedBox(height: 16),
          _buildCreditBlock("UI DESIGN", "JOHN AEROLD AMABLE \n JOAQUIN NATHANIEL CADIZ \n SOFIA JOVELLE ESTETA \n FRANCIS BRENT MAGSAYSAY \n AVIYAH TARIN"),
          const SizedBox(height: 16),
          _buildCreditBlock("IDEA", "GROUP 3"),
          const SizedBox(height: 16),
          _buildCreditBlock("RESEARCH ADVISER", "KIM MAGBANUA"),
          const SizedBox(height: 16),
          _buildCreditBlock("CORE_PROTOCOLS", "FLUTTER_DART"),
          const SizedBox(height: 40),
          const Opacity(
            opacity: 0.5,
            child: Text(
              "ACCESS_LEVEL: ADMIN\nALL_RIGHTS_RETAINED_2026",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditBlock(String role, String name) {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              color: Colors.black,
              child: Text(
                role,
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}