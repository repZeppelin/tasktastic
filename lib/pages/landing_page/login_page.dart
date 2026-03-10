import 'package:finaltasktastic/scripts/data_handler.dart';
import 'package:finaltasktastic/pages/landing_page/signup_page.dart';
import 'package:finaltasktastic/pages/main_page/widget_tree.dart';
import 'package:finaltasktastic/scripts/datasync.dart';
import 'package:finaltasktastic/views/global_popouts.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';

final player = AudioPlayer();

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(); // Reintroduced
  final _loginFormValidation = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _obscurePassword = true; // Visibility toggle state

  final OutlineInputBorder _sharpBorder = const OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: Colors.black, width: 3),
  );

Future<void> _handleLogin() async {
  if (!_loginFormValidation.currentState!.validate()) return;

  setState(() => _isLoading = true);
  debugPrint("DEBUG: === STARTING_OPERATIVE_AUTH ===");

  try {
    // 1. Precise DB Query
    final data = await Supabase.instance.client
        .from('tasktastic')
        .select()
        .eq('username', _usernameController.text.trim())
        .eq('password', _passwordController.text.trim())
        .maybeSingle();

    if (data == null) {
      throw Exception("AUTH_FAILURE: INVALID_CREDENTIALS");
    }

    // 2. CRITICAL: Register identity in the Singleton BEFORE loading data
    final player = Player();
    player.id = data['id']; // ID 19
    player.name = data['username'] ?? "UNKNOWN_OPERATIVE";
    player.isAdmin = data['admin'] ?? false;
    player.wallet_amount = data['money'] ?? 0;

    debugPrint("DEBUG: ID_${player.id}_REGISTERED. STARTING_DATA_RECOVERY...");

    // 3. SECURE DATA LOAD: Wait for both Tasks and Inventory to finish
    // This ensures TaskTable.taskList is populated before we switch screens
    await Future.wait([
      TaskTable().loadTasksFromSupabase(),
      player.loadInventoryFromSupabase(),
    ]);

    // 4. Session Persistence (Optional helper)
    await SessionManager.initializeOperativeSession(data);

    if (mounted) {
      NoirPopouts.showToast(context, "WELCOME_BACK_OPERATIVE");
      
      // Use pushReplacement so they can't 'back' into the login screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    }
  } catch (e) {
    debugPrint("DEBUG: AUTH_CRITICAL_ERR -> $e");
    if (mounted) {
      String msg = e.toString().contains("AUTH_FAILURE") 
          ? "ACCESS_DENIED: Check Credentials" 
          : "NETWORK_FAILURE: DB_UNREACHABLE";
      NoirPopouts.showToast(context, msg, isError: true);
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
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

            // SIGN UP FOOTER
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpPage()),
                  ),
                  child: Container(
                    width: 180,
                    decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 2)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('REGISTER_NEW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Spacer(),
                        Icon(Icons.create, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // MAIN CONTENT
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.terminal, size: 80, color: Colors.black),
                    const Text(
                      'tasktastic',
                      style: TextStyle(fontSize: 45, fontWeight: FontWeight.bold, letterSpacing: -1),
                    ),
                    const Text(
                      'SECURE_OPERATIVE_LOGIN',
                      style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w300),
                    ),
                    const SizedBox(height: 40),

                    Form(
                      key: _loginFormValidation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          children: [
                            _buildTextField(_usernameController, 'OPERATIVE_ID', Icons.person, false),
                            const SizedBox(height: 15),
                            
                            // Re-added Password Field
                            _buildTextField(
                              _passwordController, 
                              'ACCESS_KEY', 
                              Icons.lock, 
                              _obscurePassword,
                              suffix: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            
                            const SizedBox(height: 25),

                            InkWell(
                              onTap: _isLoading ? null : _handleLogin,
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
                                      _isLoading ? 'VERIFYING...' : 'LOGIN_TO_SYSTEM',
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
        suffixIcon: suffix,
        enabledBorder: _sharpBorder,
        focusedBorder: _sharpBorder.copyWith(borderSide: const BorderSide(width: 4)),
        errorBorder: _sharpBorder.copyWith(borderSide: const BorderSide(color: Colors.red, width: 2)),
        focusedErrorBorder: _sharpBorder.copyWith(borderSide: const BorderSide(color: Colors.red, width: 4)),
      ),
      validator: (val) => val == null || val.isEmpty ? 'FIELD REQUIRED' : null,
    );
  }
}