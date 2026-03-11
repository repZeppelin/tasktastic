import 'package:finaltasktastic/scripts/data_handler.dart';
import 'package:finaltasktastic/pages/main_page/widget_tree.dart';
import 'package:finaltasktastic/views/global_popouts.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:finaltasktastic/scripts/datasync.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController =
      TextEditingController(); // New Controller
  final _signUpFormKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  double _currentPasswordProgress = 0.0; // For UI toggle

  final OutlineInputBorder _sharpBorder = const OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: Colors.black, width: 3),
  );

  void initState() {
    super.initState();
    _passwordController.addListener(_handlePasswordChange);
  }

  void dispose() {
    super.dispose();
  }

  void _handlePasswordChange() {
    // 3. Update the global progress whenever the text changes
    final metrics = calculatePasswordMetrics(_passwordController.text);
    setState(() {
      _currentPasswordProgress = metrics['progress'];
    });
  }

  Map<String, dynamic> calculatePasswordMetrics(String password) {
    final rules = {
      'At least 9 characters': password.length >= 9,
      'At least one uppercase letter': password.contains(RegExp(r'[A-Z]')),
      'At least one number': password.contains(RegExp(r'[0-9]')),
      'At least one special character': password.contains(
        RegExp(r'[!@#$%^&*]'),
      ),
    };

    int passedCount = rules.values.where((valid) => valid).length;

    return {
      'progress': passedCount / rules.length,
      'rules': rules, // Map of { "Description": bool }
    };
  }

  Future<void> _handleSignUp() async {
    if (!_signUpFormKey.currentState!.validate()) return;

    if (_currentPasswordProgress == 1.0) {
      setState(() => _isLoading = true);
      debugPrint("DEBUG: [SYS_INIT] === HANDSHAKE_SEQUENCE_STARTING ===");

      try {
        // 1. DATABASE INSERTION WITH ADMIN SECURITY

        final data = await Supabase.instance.client
            .from('tasktastic')
            .insert({
              'username': _usernameController.text.trim(),
              'password': _passwordController.text
                  .trim(), // Consider hashing for production
              'money': 0,
              'xp_level': 0,
              'level': 1,
              'admin': false, // <--- Mandatory default: non-admin status
              'task_data': [],
              'inventory': [],
              'task_history': [], // Ensure history field is ready for logs
            })
            .select('user_id, username, money, admin')
            .single();

        // 2. SESSION INITIALIZATION
        await SessionManager.initializeOperativeSession(data);

        // 3. SINGLETON SYNC
        final player = Player();
        player.name = data['username'];
        player.isAdmin = data['admin'] ?? false;
        // player.balance = data['money'];

        final int generatedId = data['user_id'];
        debugPrint(
          "DEBUG: [SYS_SUCCESS] ID: $generatedId | ADMIN_AUTH: ${player.isAdmin}",
        );

        if (mounted) {
          NoirPopouts.showToast(context, "ID_$generatedId: ACCESS_GRANTED");

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        }
      } on PostgrestException catch (e) {
        debugPrint("DEBUG: [DB_POSTGREST_EXCEPTION] -> CODE: ${e.code}");

        if (mounted) {
          // 23505 is the PostgreSQL code for Unique Violation (Username taken)
          String errorMsg = e.code == '23505'
              ? "NAME_TAKEN"
              : "DB_ERR_${e.code}";
          NoirPopouts.showToast(context, "DENIED: $errorMsg", isError: true);
        }
      } catch (e) {
        debugPrint("DEBUG: [SYS_CRITICAL_FAILURE] -> $e");
        if (mounted) {
          NoirPopouts.showToast(context, "SYSTEM_FAULT", isError: true);
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
        debugPrint("DEBUG: [SYS_INIT] === SIGNUP_SEQUENCE_TERMINATED ===");
      }
    }
    {
      NoirPopouts.showProtocolDialog(
        context,
        title: "IMPROPER PASSWORD",
        body: "Check your password and make sure they follow the rules!",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // BACK BUTTON
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.black,
                    size: 30,
                  ),
                ),
              ),
            ),

            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 80,
                      color: Colors.black,
                    ),
                    const Text(
                      'CREATE_ACCOUNT',
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                    const Text(
                      'ESTABLISHING_NEW_CREDENTIALS',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 40),

                    Form(
                      key: _signUpFormKey,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          children: [
                            _buildTextField(
                              _usernameController,
                              'INPUT_USERNAME',
                              Icons.person,
                              false,
                            ),
                            const SizedBox(height: 15),

                            // Added Password Field
                            _buildTextField(
                              _passwordController,
                              'SET_PASSWORD',
                              Icons.lock,
                              _obscurePassword,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _passwordController,
                              builder: (context, value, child) {
                                final metrics = calculatePasswordMetrics(
                                  value.text,
                                );
                                final Map<String, bool> rules =
                                    metrics['rules'] ?? {};
                                final int passed = rules.values
                                    .where((v) => v)
                                    .length;
                                final int remaining = rules.length - passed;
                                final bool allMet = _currentPasswordProgress == 1.0;

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 0,
                                    vertical: 8,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white, // Stark background
                                    border: Border(
                                      // Sharp Vertical Line on the far left
                                      left: BorderSide(
                                        color: allMet
                                            ? const Color(0xFF00C853)
                                            : const Color(0xFF800000),
                                        width: 12,
                                      ),
                                      right: BorderSide(
                                        color: Colors.black,
                                        width: 3
                                      ),
                                      top: BorderSide(
                                        color: Colors.black,
                                        width: 3
                                      ),
                                      bottom: BorderSide(
                                        color: Colors.black,
                                        width: 3
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Left Side: Requirements Checklist
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize
                                              .min, // Fight the overflow
                                          children: rules.entries.map((entry) {
                                            final isMet = entry.value;
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 3,
                                                  ),
                                              child: Row(
                                                children: [
                                                  // Using the PIXEL/SQUARE check style from your photo
                                                  Icon(
                                                    isMet
                                                        ? Icons
                                                              .check_box_outlined
                                                        : Icons
                                                              .check_box_outline_blank,
                                                    size: 14,
                                                    color: isMet
                                                        ? Colors.green
                                                        : Colors.red,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Flexible(
                                                    child: Text(
                                                      entry.key.toUpperCase(),
                                                      style: TextStyle(
                                                        // Success is WHITE/GREEN, failure is MUTED RED
                                                        color: isMet
                                                            ? Colors.green
                                                            : const Color(
                                                                0xFF800000,
                                                              ),
                                                        fontSize:
                                                            12, // Smaller font to fit overflow
                                                        fontFamily:
                                                            'monospace', // Monospaced Terminal font
                                                        fontWeight: FontWeight.bold,
                                                        letterSpacing: 1.0,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 25),

                            InkWell(
                              onTap: _isLoading ? null : _handleSignUp,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: _isLoading
                                      ? Colors.grey[400]
                                      : Colors.black,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _isLoading
                                          ? 'ENCRYPTING...'
                                          : 'INITIALIZE_USER',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    _isLoading
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.bolt,
                                            color: Colors.white,
                                          ),
                                  ],
                                ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool obscure, {
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      cursorColor: Colors.black,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        prefixIcon: Icon(icon, color: Colors.black),
        suffixIcon: suffix, // For the visibility toggle
        enabledBorder: _sharpBorder,
        focusedBorder: _sharpBorder.copyWith(
          borderSide: const BorderSide(width: 4),
        ),
        errorBorder: _sharpBorder.copyWith(
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: _sharpBorder.copyWith(
          borderSide: const BorderSide(color: Colors.red, width: 4),
        ),
      ),
      validator: (val) =>
          (val == null || val.isEmpty) ? 'FIELD REQUIRED' : null,
    );
  }
}

class DiamondSegmentedPainter extends CustomPainter {
  final int total;
  final int passed;

  DiamondSegmentedPainter({required this.total, required this.passed});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Define the 4 points of the diamond
    final List<Offset> points = [
      Offset(w / 2, 0), // Top
      Offset(w, h / 2), // Right
      Offset(w / 2, h), // Bottom
      Offset(0, h / 2), // Left
      Offset(w / 2, 0), // Back to Top
    ];

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.square; // Sharp edges for Noir

    // Total perimeter length is the sum of the 4 hypotenuses
    // But for 4 rules, it's easier to map 1 rule to 1 side of the diamond.
    for (int i = 0; i < total; i++) {
      paint.color = i < passed
          ? const Color(0xFF00C853)
          : const Color(0xFF800000);

      // This logic maps each requirement to one specific side of the diamond
      // If you have more than 4 rules, it will subdivide the sides.
      canvas.drawLine(
        _getPointOnDiamond(i / total, w, h),
        _getPointOnDiamond((i + 0.9) / total, w, h), // 0.9 creates a small gap
        paint,
      );
    }
  }

  // Helper to find a point along the diamond perimeter (0.0 to 1.0)
  Offset _getPointOnDiamond(double t, double w, double h) {
    t = t % 1.0;
    if (t < 0.25)
      return Offset(w / 2 + (w / 2 * (t / 0.25)), h / 2 * (t / 0.25));
    if (t < 0.50)
      return Offset(
        w - (w / 2 * ((t - 0.25) / 0.25)),
        h / 2 + (h / 2 * ((t - 0.25) / 0.25)),
      );
    if (t < 0.75)
      return Offset(
        w / 2 - (w / 2 * ((t - 0.5) / 0.25)),
        h - (h / 2 * ((t - 0.5) / 0.25)),
      );
    return Offset(
      w / 2 * ((t - 0.75) / 0.25),
      h / 2 - (h / 2 * ((t - 0.75) / 0.25)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
