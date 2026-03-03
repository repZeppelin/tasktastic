import 'package:finaltasktastic/views/global_popouts.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Local State for toggles
  bool _hapticEnabled = true;
  bool _audioEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0), // Concrete Grey
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "SYSTEM_CONFIG",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            fontSize: 14,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader("HARDWARE_INTERFACE"),
          
          _buildSettingsToggle(
            "HAPTIC_FEEDBACK", 
            _hapticEnabled, 
            (val) => setState(() => _hapticEnabled = val)
          ),
          
          _buildSettingsToggle(
            "AUDIO_CHIRPS", 
            _audioEnabled, 
            (val) => setState(() => _audioEnabled = val)
          ),
          
          const SizedBox(height: 32),
          
          _buildSectionHeader("USER_PROFILE"),
          
          _buildSettingsAction(
            "WIPE_DATA", 
            Icons.delete_forever_rounded, 
            isDestructive: true, 
            () async {
              // Now waits for user interaction
              bool confirm = await NoirPopouts.showConfirmAction(
                context, 
                title: "DANGER: DATA_PURGE", 
                body: "All progression data will be overwritten with null values. Proceed with purge?"
              );
              
              if (confirm) {
                NoirPopouts.showToast(context, "DATA_PURGE_SUCCESSFUL", isError: true);
              }
            }
          ),
          
          _buildSettingsAction(
            "SYSTEM_INFO", 
            Icons.terminal_rounded, 
            () {
              NoirPopouts.showToast(context, "CORE_V2.0.4 // KERNEL_STABLE");
            }
          ),

          _buildSettingsAction(
            "RATE_INTERFACE_UX", 
            Icons.assessment_outlined, 
            () {
              // Testing the new 1-4 rating system you built
              NoirPopouts.triggerRandomFeedback(context, "SYSTEM_UX", probability: 1.0);
            }
          ),
        ],
      ),
    );
  }

  // --- BRUTALIST UI COMPONENTS ---

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "// $title",
          style: const TextStyle(
            fontSize: 10,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Container(height: 4, color: Colors.black),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSettingsToggle(String title, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: value ? Colors.black : Colors.white,
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: value ? null : const [BoxShadow(color: Colors.black, offset: Offset(5, 5))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title, 
              style: TextStyle(
                fontWeight: FontWeight.w900, 
                fontSize: 13,
                fontFamily: 'monospace',
                color: value ? Colors.white : Colors.black,
              )
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: const Color(0xFF00FF41), // Matrix Green
                activeTrackColor: Colors.grey[900],
                inactiveThumbColor: Colors.black,
                inactiveTrackColor: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsAction(String title, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: isDestructive ? const Color(0xFFFF4444) : Colors.white,
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(5, 5))],
        ),
        child: Row(
          children: [
            Icon(icon, color: isDestructive ? Colors.white : Colors.black, size: 18),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isDestructive ? Colors.white : Colors.black,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: isDestructive ? Colors.black26 : Colors.black12,
              child: Text(
                isDestructive ? "![PURGE]" : "[RUN]",
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: isDestructive ? Colors.white : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}