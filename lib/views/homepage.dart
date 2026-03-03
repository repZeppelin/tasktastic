import 'dart:collection';
import 'package:finaltasktastic/scripts/data_handler.dart';
import 'package:finaltasktastic/views/global_popouts.dart';
import 'package:finaltasktastic/views/profile.dart';
import 'package:finaltasktastic/views/snackbars.dart';
import 'package:finaltasktastic/views/taskList.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

DateTime? deadline;
bool dateInserted = false;
bool timeInserted = false;

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

int _calculateXP(int difficulty) {
  switch (difficulty) {
    case 1:
      return 5;
    case 2:
      return 15;
    case 3:
      return 30;
    default:
      return 0;
  }
}

final GlobalKey<ScaffoldMessengerState> rootScaffoldKey =
    GlobalKey<ScaffoldMessengerState>();

typedef DifficultyEntry = DropdownMenuEntry<DifficultyLabel>;

// DropdownMenuEntry labels and values for the first dropdown menu.
enum DifficultyLabel {
  easy('Easy', Colors.green, 1),
  medium('Medium', Colors.orange, 2),
  hard('Hard', Colors.red, 3);

  const DifficultyLabel(this.label, this.color, this.level);
  final String label;
  final Color color;
  final int? level;

  static final List<DifficultyEntry> entries =
      UnmodifiableListView<DifficultyEntry>(
        values.map<DifficultyEntry>(
          (DifficultyLabel color) => DifficultyEntry(
            value: color,
            label: color.label,
            enabled: color.label != 'Grey',
            style: MenuItemButton.styleFrom(foregroundColor: color.color),
          ),
        ),
      );
}

class _HomepageState extends State<Homepage> {
  final taskTable = TaskTable();
  int forgottenInput = 0;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController taskName = TextEditingController();
  final TextEditingController taskDescription = TextEditingController();
  final TextEditingController difficulty = TextEditingController();
  bool submitted = false;

  // Helper Method for XP Calculation
  int _calculateXP(int difficulty) {
    switch (difficulty) {
      case 1:
        return 5;
      case 2:
        return 15;
      case 3:
        return 30;
      default:
        return 0;
    }
  }

  Future<DateTime?> pickDate() => showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime.now(),
    lastDate: DateTime(3000),
  );

  Future<TimeOfDay?> pickTime() =>
      showTimePicker(context: context, initialTime: TimeOfDay.now());

  @override
  void dispose() {
    taskName.dispose();
    taskDescription.dispose();
    difficulty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Task List takes up the top space
        Expanded(child: TaskListView()),

        // 2. Control Row (Confirm Logs and Add Task)
        Row(
          children: [
            // --- CONFIRM LOGS BUTTON ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final taskTableProvider = context.watch<TaskTable>();
                    final bool canFinalize =
                        taskTableProvider.hasTasksToFinalize;

                    return GestureDetector(
                      onTap: canFinalize
                          ? () {
                              int totalGainedXP = 0;
                              for (var task in taskTableProvider.taskList) {
                                if (task.taskStatus == true) {
                                  totalGainedXP += _calculateXP(
                                    task.difficulty,
                                  );
                                }
                              }

                              setState(() {
                                taskTableProvider.removeFalseTrue(context);
                              });

                              if (totalGainedXP > 0) {
                                Player().addXP(context, totalGainedXP);
                                // Using your Noir Toast for consistency
                                showTopSnackBar(
                                  context,
                                  "Task accomplished! Gained $totalGainedXP XP",
                                  Colors.green,
                                );
                                NoirPopouts.triggerRandomFeedback(
                                  context,
                                  "TASK SUBMISSION",
                                );
                              }
                            }
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: canFinalize ? Colors.white : Colors.grey[300],
                          border: Border.all(
                            color: canFinalize
                                ? Colors.black
                                : Colors.grey[600]!,
                            width: 3,
                          ),
                          boxShadow: canFinalize
                              ? const [
                                  BoxShadow(
                                    color: Colors.black,
                                    offset: Offset(4, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'CONFIRM_LOGS',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                                color: canFinalize
                                    ? Colors.black
                                    : Colors.grey[600],
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.check_circle_outline,
                              size: 24,
                              color: canFinalize
                                  ? Colors.black
                                  : Colors.grey[600],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // --- ADD TASK BUTTON ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => CreateTaskDialog(
                        onSave: (name, desc, diff, deadline) async {
                          context.read<TaskTable>().addTask(name, desc, diff, deadline);
                          setState(() {
                            print("dick");
                          });
                        },
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 3),
                      boxShadow: const [
                        BoxShadow(color: Colors.black, offset: Offset(4, 4)),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Text(
                          'ADD TASK',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                            color: Colors.black,
                          ),
                        ),
                        Spacer(),
                        Icon(
                          Icons.add_box_outlined,
                          size: 24,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // 3. Pet Hero Section
        const PetHero(),
      ],
    );
  }
}

class CreateTaskDialog extends StatefulWidget {
  final Function(String name, String desc, int difficulty, DateTime deadline)
  onSave;

  const CreateTaskDialog({super.key, required this.onSave});

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  DateTime? _deadline;
  bool _dateInserted = false;
  bool _timeInserted = false;
  int _difficultyValue = 1;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: NoirAnimationWrapper(
        isTop: false,
        child: Container(
          decoration: const BoxDecoration(
            boxShadow: [BoxShadow(color: Colors.black, offset: Offset(8, 8))],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 3),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'NEW DOSSIER',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: 2.0,
                        color: Colors.black,
                      ),
                    ),
                    const Divider(color: Colors.black, thickness: 3),
                    const SizedBox(height: 20),

                    _buildTextField(_nameController, 'SUBJECT / TASK NAME'),
                    const SizedBox(height: 12),
                    _buildTextField(_descController, 'INTEL / DESCRIPTION'),
                    const SizedBox(height: 20),

                    const Text(
                      "PRIORITY LEVEL",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    
                    // --- UPDATED PRIORITY CHIPS ---
                    Row(
                      children: [
                        _buildPriorityChip(1, "LVL 1", Colors.green),
                        const SizedBox(width: 8),
                        _buildPriorityChip(2, "LVL 2", Colors.orange),
                        const SizedBox(width: 8),
                        _buildPriorityChip(3, "LVL 3", Colors.red),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    const Text(
                      "DEADLINE SETTINGS",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                    const SizedBox(height: 8),

                    // --- UPDATED DATE/TIME PICKERS ---
                    Row(
                      children: [
                        _buildPickerChip(
                          Icons.calendar_today,
                          _dateInserted 
                              ? "${_deadline?.day}/${_deadline?.month}" 
                              : 'SET DAY',
                          _pickDate,
                        ),
                        const SizedBox(width: 10),
                        _buildPickerChip(
                          Icons.access_time_filled,
                          _timeInserted
                              ? "${_deadline?.hour}:${_deadline?.minute.toString().padLeft(2, '0')}"
                              : 'SET TIME',
                          _pickTime,
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    Row(
                      children: [
                        _buildActionBtn(
                          'FILE TASK',
                          Colors.black,
                          Icons.folder_shared_outlined,
                          _submit,
                        ),
                        const SizedBox(width: 10),
                        _buildActionBtn(
                          'ABORT',
                          const Color(0xFFB71C1C),
                          Icons.close,
                          () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper to build Priority Level Chips
  Widget _buildPriorityChip(int value, String label, Color color) {
    bool isSelected = _difficultyValue == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _difficultyValue = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            border: Border.all(color: isSelected ? color : Colors.black, width: 2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  // Helper to build Date/Time Picker Chips
  Widget _buildPickerChip(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace'
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // --- HELPERS (UI) ---

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      cursorColor: Colors.black,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(
          0.8,
        ), // Slightly transparent to let stamp show
        border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.black, width: 2),
        ),
      ),
      validator: (value) =>
          (value == null || value.isEmpty) ? "FIELD REQUIRED" : null,
    );
  }

  Widget _buildPickerBtn(IconData icon, String label, VoidCallback onPressed) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBtn(
    String label,
    Color color,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- LOGIC ---

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() {
        _dateInserted = true;
        _deadline = DateTime(
          date.year,
          date.month,
          date.day,
          _deadline?.hour ?? 0,
          _deadline?.minute ?? 0,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _timeInserted = true;
        _deadline = DateTime(
          _deadline?.year ?? DateTime.now().year,
          _deadline?.month ?? DateTime.now().month,
          _deadline?.day ?? DateTime.now().day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _dateInserted && _timeInserted) {
      widget.onSave(
        _nameController.text,
        _descController.text,
        _difficultyValue,
        _deadline!,
      );
      Navigator.pop(context);
    } else {
      // Logic: Use your custom top snackbar for errors
      showTopSnackBar(
        context,
        "DOSSIER INCOMPLETE: CHECK DATE AND SUBJECT",
        const Color(0xFFB71C1C),
      );
    }
  }
}
