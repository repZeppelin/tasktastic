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
  bool _obscurePassword = true; // For UI toggle

  final OutlineInputBorder _sharpBorder = const OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: Colors.black, width: 3),
  );

  Future<void> _handleSignUp() async {
  if (!_signUpFormKey.currentState!.validate()) return;

  setState(() => _isLoading = true);
  debugPrint("DEBUG: [SYS_INIT] === HANDSHAKE_SEQUENCE_STARTING ===");

  try {
    // 1. DATABASE INSERTION WITH ADMIN SECURITY
    final data = await Supabase.instance.client.from('tasktastic').insert({
      'username': _usernameController.text.trim(),
      'password': _passwordController.text.trim(), // Consider hashing for production
      'money': 0,
      'xp_level': 0,
      'level': 1,
      'admin': false, // <--- Mandatory default: non-admin status
      'task_data': [],
      'inventory': [],
      'task_history': [], // Ensure history field is ready for logs
    }).select('user_id, username, money, admin').single();

    // 2. SESSION INITIALIZATION
    await SessionManager.initializeOperativeSession(data);

    // 3. SINGLETON SYNC
    final player = Player();
    player.name = data['username'];
    player.isAdmin = data['admin'] ?? false;
    // player.balance = data['money']; 

    final int generatedId = data['user_id'];
    debugPrint("DEBUG: [SYS_SUCCESS] ID: $generatedId | ADMIN_AUTH: ${player.isAdmin}");

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
      String errorMsg = e.code == '23505' ? "NAME_TAKEN" : "DB_ERR_${e.code}";
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
