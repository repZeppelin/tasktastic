import 'dart:io';

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
    if (_loginFormValidation.currentState!.validate()) {
      setState(() => _isLoading = true);
      debugPrint("DEBUG: === LOGIN_SEQUENCE_STARTED ===");

      try {
        // 1. Query table for a row matching BOTH username and plain-text password
        final data = await Supabase.instance.client
            .from('tasktastic')
            .select()
            .eq('username', _usernameController.text.trim())
            .eq('password', _passwordController.text.trim()) // Plain text check
            .maybeSingle();

        if (data == null) {
          debugPrint("DEBUG: AUTH_FAILED - No match for credentials.");
          throw Exception("INVALID_OPERATIVE_OR_PASSWORD");
        }

        debugPrint("DEBUG: Access Granted for ID: ${data['user_id']}");

        // 2. Map data to Player Singleton
        await SessionManager.initializeOperativeSession(data);

        // 3. Navigation
        if (mounted) {
          NoirPopouts.showToast(context, "AUTHENTICATION_SUCCESSFUL");
          TaskTable().loadTasksFromSupabase();
          Player().loadInventoryFromSupabase();
          Navigator.pushAndRemoveUntil(
            context, 
            MaterialPageRoute(builder: (context) => const HomePage()), 
            (route) => false
          );
        }
      } catch (e) {
        debugPrint("DEBUG: LOGIN_ERROR -> $e");
        if (mounted) {
          String errorMsg = e.toString().contains("INVALID") 
            ? "ERROR: ACCESS_DENIED" 
            : "SYSTEM_FAILURE: DATABASE_OFFLINE";
          NoirPopouts.showToast(context, errorMsg, isError: true);
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
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