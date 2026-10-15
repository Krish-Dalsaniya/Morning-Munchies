import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _signup = false;
  bool _busy = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _obscurePassword = true;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final pass = _pass.text;
    final name = _name.text.trim();

    if (email.isEmpty || pass.isEmpty || (_signup && name.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      if (_signup) {
        final res = await supabase.auth.signUp(
          email: email,
          password: pass,
          data: {'name': name},
        );
        if (res.session == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created! Please check your email or verify in Supabase dashboard.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else {
        await supabase.auth.signInWithPassword(email: email, password: pass);
      }
    } on AuthException catch (e) {
      if (mounted) {
        final msg = e.message.toLowerCase().contains('invalid login credentials')
            ? 'Invalid email or password. If you are new, tap "Sign up" below.'
            : e.message;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFFBF8F3);
    const primaryColor = Color(0xFFBA4E2C);
    const borderColor = Color(0xFFE5DDD3);
    const labelColor = Color(0xFF8C827A);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Hero Food Illustration
                  Image.asset(
                    'assets/images/login_illustration.jpg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 48, bottom: 20),
                        child: Column(
                          children: [
                            Image.asset('assets/images/logo.png', height: 140, errorBuilder: (ctx, err, stack) => const Icon(Icons.wb_sunny, size: 72, color: Colors.orange)),
                            const SizedBox(height: 12),
                            const Text('Morning Munchies', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: primaryColor)),
                            const Text("Decide today's meal together", style: TextStyle(fontSize: 14, color: labelColor)),
                          ],
                        ),
                      );
                    },
                  ),

                  // Form Container
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_signup) ...[
                          _buildTextField(
                            controller: _name,
                            hintText: 'Your name',
                            icon: Icons.person_outline_rounded,
                            keyboardType: TextInputType.name,
                            borderColor: borderColor,
                            labelColor: labelColor,
                            primaryColor: primaryColor,
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Email Field
                        _buildTextField(
                          controller: _email,
                          hintText: 'Email',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          borderColor: borderColor,
                          labelColor: labelColor,
                          primaryColor: primaryColor,
                        ),
                        const SizedBox(height: 14),

                        // Password Field
                        _buildTextField(
                          controller: _pass,
                          hintText: 'Password',
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword == true,
                          borderColor: borderColor,
                          labelColor: labelColor,
                          primaryColor: primaryColor,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword == true ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: labelColor,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !(_obscurePassword == true)),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Log In / Create Account Button
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _busy ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shadowColor: primaryColor.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _busy
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : Text(
                                    _signup ? 'Create account' : 'Log in',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Toggle Mode
                        Center(
                          child: GestureDetector(
                            onTap: () => setState(() => _signup = !_signup),
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 14, color: Color(0xFF5A524C)),
                                children: [
                                  TextSpan(text: _signup ? 'Already have an account? ' : 'New here? '),
                                  TextSpan(
                                    text: _signup ? 'Log in' : 'Sign up',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Footer with steam icon & tagline
                        Row(
                          children: [
                            const Expanded(child: Divider(color: Color(0xFFE2DAD0), thickness: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(Icons.soup_kitchen_outlined, size: 20, color: labelColor.withValues(alpha: 0.8)),
                            ),
                            const Expanded(child: Divider(color: Color(0xFFE2DAD0), thickness: 1)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Good food. One team decision.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: labelColor, letterSpacing: 0.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required Color borderColor,
    required Color labelColor,
    required Color primaryColor,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText == true,
        enableSuggestions: obscureText != true,
        autocorrect: obscureText != true,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15, color: Color(0xFF2C2420)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: labelColor, fontSize: 15),
          prefixIcon: Icon(icon, color: labelColor, size: 20),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor, width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor, width: 1.6),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
