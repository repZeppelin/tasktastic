import 'package:file_picker/file_picker.dart';
import 'package:finaltasktastic/scripts/data_handler.dart';
import 'package:finaltasktastic/views/snackbars.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InteractWithTask extends StatelessWidget {
  const InteractWithTask({super.key, required this.taskId});
  
  // Pass the unique ID of the task, NOT the list index
  final int taskId;

  // Helper to map difficulty to XP
  int _calculateXP(int difficulty) {
    switch (difficulty) {
      case 1: return 5;
      case 2: return 15;
      case 3: return 30;
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // We watch the TaskTable to react to changes, 
    // but use 'getTaskById' to find the specific data for this ID.
    final taskTable = context.watch<TaskTable>();
    final player = context.read<Player>();
    
    // Safely get the task object
    final task = taskTable.getTaskById(taskId);

    return Padding(
      padding: const EdgeInsets.only(right: 16, bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- UPLOAD (BLUE) ---
          _buildNoirActionButton(
            icon: Icons.upload_outlined,
            backgroundColor: Colors.blue[600]!,
            onPressed: () async {
              final result = await FilePicker.platform.pickFiles();
              
              if (result == null) {
                showTopSnackBar(context, "UPLOAD ABORTED", Colors.red);
              } else {
                // 1. Mark task as complete using the UNIQUE ID
                taskTable.truthifyTask(taskId);
                
                // 2. Award XP based on the task found
                
              }
            },
          ),
          const SizedBox(width: 10),

          // --- FALSIFY (RED) ---
          _buildNoirActionButton(
            icon: Icons.close_rounded,
            backgroundColor: Colors.red[600]!,
            onPressed: () => taskTable.falsifyTask(taskId),
          ),
          const SizedBox(width: 10),

          // --- UNDO (GREY) ---
          _buildNoirActionButton(
            icon: Icons.undo_rounded,
            backgroundColor: Colors.grey[600]!,
            onPressed: () => taskTable.nullifyTask(taskId),
          ),
        ],
      ),
    );
  }

  Widget _buildNoirActionButton({
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(3, 3),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}