import 'dart:async';
import 'package:finaltasktastic/scripts/data_handler.dart';
import 'package:finaltasktastic/main.dart';
import 'package:finaltasktastic/views/taskInteraction.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TaskListView extends StatefulWidget {
  const TaskListView({super.key});

  @override
  State<TaskListView> createState() => _ListViewState();
}

class _ListViewState extends State<TaskListView> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Map<String, dynamic> _getTimerData(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return {"text": "EXPIRED", "color": Colors.grey, "isExpired": true};
    }

    final days = difference.inDays;
    final hours = (difference.inHours % 24).toString().padLeft(2, '0');
    final minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (difference.inSeconds % 60).toString().padLeft(2, '0');

    String timeStr = days > 0 ? "$days d, $hours:$minutes:$seconds" : "$hours:$minutes:$seconds";

    if (difference.inHours >= 24) {
      return {"text": "$timeStr LEFT", "color": Colors.green, "isExpired": false};
    } else if (difference.inHours >= 12) {
      return {"text": "$timeStr LEFT", "color": Colors.orange, "isExpired": false};
    } else {
      return {"text": "$timeStr LEFT", "color": Colors.red, "isExpired": false};
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskTable = context.watch<TaskTable>();

    final sortedTasks = List.from(taskTable.taskList);
    sortedTasks.sort((a, b) {
      final dataA = _getTimerData(a.deadline);
      final dataB = _getTimerData(b.deadline);
      if (dataA["isExpired"] != dataB["isExpired"]) return dataA["isExpired"] ? 1 : -1;
      return b.difficulty.compareTo(a.difficulty);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopHeader(taskTable),
        Expanded(
          child: sortedTasks.isEmpty
              ? const Center(child: Text('NO ACTIVE TASKS', style: TextStyle(fontWeight: FontWeight.bold)))
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 0, bottom: 20),
                  itemCount: sortedTasks.length,
                  itemBuilder: (context, index) {
                    final task = sortedTasks[index];
                    final timerData = _getTimerData(task.deadline);
                    final bool isExpired = timerData["isExpired"];
                    
                    // Logic for the icon only
                    final bool isDone = task.taskStatus == true; 
                    final bool isFailed = task.taskStatus == false; // State when 'X' is pressed

                    bool showHeader = false;
                    String headerTitle = "";
                    Color headerColor = Colors.black;

                    if (index == 0) {
                      showHeader = true;
                    } else {
                      final prevTask = sortedTasks[index - 1];
                      final prevData = _getTimerData(prevTask.deadline);
                      if (prevTask.difficulty != task.difficulty || prevData["isExpired"] != isExpired) {
                        showHeader = true;
                      }
                    }

                    if (showHeader) {
                      if (isExpired) {
                        headerTitle = "ARCHIVED / EXPIRED";
                        headerColor = Colors.grey;
                      } else {
                        switch (task.difficulty) {
                          case 3: headerTitle = "HIGH PRIORITY (LVL 3)"; headerColor = Colors.red; break;
                          case 2: headerTitle = "MID PRIORITY (LVL 2)"; headerColor = Colors.orange; break;
                          case 1: headerTitle = "LOW PRIORITY (LVL 1)"; headerColor = Colors.green; break;
                          default: headerTitle = "TASKS"; headerColor = Colors.blueGrey;
                        }
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showHeader) _buildSectionHeader(headerTitle, headerColor),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 3.0),
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: isExpired ? Colors.grey : Colors.black, width: 3),
                                  color: isExpired ? Colors.grey[100] : Colors.white,
                                  boxShadow: isExpired ? null : const [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      // --- ICON CHANGES TO RED X, BUT CARD STAYS ACTIVE ---
                                      Icon(
                                        isExpired 
                                            ? Icons.timer_off 
                                            : (isDone 
                                                ? Icons.check_circle 
                                                : (isFailed ? Icons.cancel : Icons.radio_button_unchecked)),
                                        color: isDone 
                                            ? Colors.green 
                                            : (isFailed ? Colors.red : (isExpired ? Colors.grey : timerData["color"])),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              task.name.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 14, 
                                                fontWeight: FontWeight.bold,
                                                color: isExpired ? Colors.grey : Colors.black,
                                                // Removed strike-through for failed tasks per your request
                                                decoration: isExpired ? TextDecoration.lineThrough : null,
                                              )
                                            ),
                                            Text(task.description, style: const TextStyle(fontSize: 11, color: Colors.black87)),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                _buildSmallTag("LVL: ${task.difficulty}", isExpired ? Colors.grey : Colors.black),
                                                const SizedBox(width: 4),
                                                _buildSmallTag(
                                                  isDone ? "COMPLETE" : (isFailed ? "FAILED" : timerData["text"]), 
                                                  isDone ? Colors.green : (isFailed ? Colors.red : timerData["color"])
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerRight,
                                child: InteractWithTask(taskId: task.id),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- (Helper widgets remain the same) ---
  Widget _buildTopHeader(TaskTable taskTable) {
    int lv3 = taskTable.taskList.where((t) => t.difficulty == 3 && !t.deadline.isBefore(DateTime.now())).length;
    int lv2 = taskTable.taskList.where((t) => t.difficulty == 2 && !t.deadline.isBefore(DateTime.now())).length;
    int lv1 = taskTable.taskList.where((t) => t.difficulty == 1 && !t.deadline.isBefore(DateTime.now())).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              const Text("📋 TASKS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const Spacer(),
              _buildStatusChip("LVL3", lv3, Colors.red),
              const SizedBox(width: 4),
              _buildStatusChip("LVL2", lv2, Colors.orange),
              const SizedBox(width: 4),
              _buildStatusChip("LVL1", lv1, Colors.green),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  taskTable.taskList.removeWhere((t) => t.deadline.isBefore(DateTime.now()));
                  taskTable.syncTasks();
                  setState(() {});
                },
                icon: const Icon(Icons.archive_outlined, size: 20),
                visualDensity: VisualDensity.compact,
              )
            ],
          ),
          const Divider(color: Colors.black, thickness: 3),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
            child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9, letterSpacing: 1.1)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 2, color: color.withOpacity(0.3))),
        ],
      ),
    );
  }

  Widget _buildSmallTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
      child: Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace')),
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
      child: Text("$label: $count", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }
}