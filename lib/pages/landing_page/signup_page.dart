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
  final TextEditingController _passwordController = TextEditingController(); // New Controller
  final _signUpFormKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true; // For UI toggle

  final OutlineInputBorder _sharpBorder = const OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: Colors.black, width: 3),
  );

  Future<void> _handleSignUp() async {
  if (_signUpFormKey.currentState!.validate()) {
    setState(() => _isLoading = true);
    debugPrint("DEBUG: [SYS_INIT] === INT4 SIGNUP WITH MONEY_COL === ");

    try {
      final data = await Supabase.instance.client.from('tasktastic').insert({
        'username': _usernameController.text.trim(),
        'password': _passwordController.text.trim(),
        'money': 0,      // <--- Initialize starting funds here
        'xp_level': 0,
        'level': 1,
        'task_data': [], 
        'inventory' : []
      }).select('user_id, username, money').single(); // Added money to select to verify
      await SessionManager.initializeOperativeSession(data);
      final int generatedId = data['user_id'];
      final int initialFunds = data['money'];
      
      debugPrint("DEBUG: [SYS_SUCCESS] ID: $generatedId | CAPITAL: $initialFunds");

      // Update Player Singleton
      Player().name = data['username'];
      // Player().balance = data['money']; // If your singleton has a balance field

      if (mounted) {
        NoirPopouts.showToast(context, "ID_$generatedId: INITIALIZED");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      }
    } on PostgrestException catch (e) {
      debugPrint("DEBUG: [DB_POSTGREST_EXCEPTION]");
      debugPrint(" > CODE:    ${e.code}");
      debugPrint(" > MESSAGE: ${e.message}");
      debugPrint(" > DETAILS: ${e.details}");
      
      if (mounted) {
        String errorMsg = e.code == '23505' ? "NAME_TAKEN" : "DB_ERR_${e.code}";
        NoirPopouts.showToast(context, "DENIED: $errorMsg", isError: true);
      }
    } catch (e) {
      debugPrint("DEBUG: [SYS_CRITICAL_FAILURE] -> $e");
      if (mounted) NoirPopouts.showToast(context, "SYSTEM_FAULT", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("DEBUG: [SYS_INIT] === SIGNUP SEQUENCE FINISHED ===");
    }
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
                  icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30),
                ),
              ),
            ),

            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_outlined, size: 80, color: Colors.black),
                    const Text(
                      'CREATE_ACCOUNT',
                      style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, letterSpacing: -1),
                    ),
                    const Text(
                      'ESTABLISHING_NEW_CREDENTIALS',
                      style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w300),
                    ),
                    const SizedBox(height: 40),

                    Form(
                      key: _signUpFormKey,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          children: [
                            _buildTextField(_usernameController, 'INPUT_USERNAME', Icons.person, false),
                            const SizedBox(height: 15),
                            
                            // Added Password Field
                            _buildTextField(
                              _passwordController, 
                              'SET_PASSWORD', 
                              Icons.lock, 
                              _obscurePassword,
                              suffix: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            
                            const SizedBox(height: 25),

                            InkWell(
                              onTap: _isLoading ? null : _handleSignUp,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: _isLoading ? Colors.grey[400] : Colors.black,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _isLoading ? 'ENCRYPTING...' : 'INITIALIZE_USER',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    _isLoading 
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Icon(Icons.bolt, color: Colors.white),
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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool obscure, {Widget? suffix}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      cursorColor: Colors.black,
      style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.black),
        suffixIcon: suffix, // For the visibility toggle
        enabledBorder: _sharpBorder,
        focusedBorder: _sharpBorder.copyWith(borderSide: const BorderSide(width: 4)),
        errorBorder: _sharpBorder.copyWith(borderSide: const BorderSide(color: Colors.red, width: 2)),
        focusedErrorBorder: _sharpBorder.copyWith(borderSide: const BorderSide(color: Colors.red, width: 4)),
      ),
      validator: (val) => (val == null || val.isEmpty) ? 'FIELD REQUIRED' : null,
    );
  }
}