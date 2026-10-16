import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core.dart';
import '../widgets/interactive_effects.dart';

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
              content: Text(
                'Account created! Please check your email or verify in Supabase dashboard.',
              ),
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else {
        await supabase.auth.signInWithPassword(email: email, password: pass);
      }
    } on AuthException catch (e) {
      if (mounted) {
        final msg =
            e.message.toLowerCase().contains('invalid login credentials')
            ? 'Invalid email or password. If you are new, tap "Sign up" below.'
            : e.message;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
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
                  // Top Hero Food Illustration with gentle fade entrance
                  FadeSlideEntry(
                    index: 0,
                    child: SizedBox(
                      height: MediaQuery.sizeOf(context).height < 680 ? 170 : 220,
                      width: double.infinity,
                      child: Image.asset(
                        'assets/images/login_illustration.jpg',
                        fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 48, bottom: 20),
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/images/logo.png',
                                height: 140,
                                errorBuilder: (ctx, err, stack) => const Icon(
                                  Icons.wb_sunny,
                                  size: 72,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Morning Munchies',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              const Text(
                                "Decide today's meal together",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: labelColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                  // Form Container
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                    child: FadeSlideEntry(
                      index: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.topCenter,
                            child: _signup
                                ? Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: _HoverTextField(
                                      controller: _name,
                                      hintText: 'Your name',
                                      icon: Icons.person_outline_rounded,
                                      keyboardType: TextInputType.name,
                                      borderColor: borderColor,
                                      labelColor: labelColor,
                                      primaryColor: primaryColor,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),

                          // Email Field
                          _HoverTextField(
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
                          _HoverTextField(
                            controller: _pass,
                            hintText: 'Password',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword == true,
                            borderColor: borderColor,
                            labelColor: labelColor,
                            primaryColor: primaryColor,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword == true
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: labelColor,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword =
                                    !(_obscurePassword == true),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Log In / Create Account Button with bounce & hover lift
                          BouncingButton(
                            onPressed: _busy ? null : _submit,
                            child: SizedBox(
                              height: 52,
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _busy ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 3,
                                  shadowColor: primaryColor.withValues(
                                    alpha: 0.4,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _busy
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Text(
                                        _signup ? 'Create account' : 'Log in',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Toggle Mode with animated text
                          Center(
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => setState(() => _signup = !_signup),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 8,
                                  ),
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF5A524C),
                                      ),
                                      children: [
                                        TextSpan(
                                          text: _signup
                                              ? 'Already have an account? '
                                              : 'New here? ',
                                        ),
                                        TextSpan(
                                          text: _signup ? 'Log in' : 'Sign up',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Footer with steam icon & tagline
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(
                                  color: Color(0xFFE2DAD0),
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Icon(
                                  Icons.soup_kitchen_outlined,
                                  size: 20,
                                  color: labelColor.withValues(alpha: 0.8),
                                ),
                              ),
                              const Expanded(
                                child: Divider(
                                  color: Color(0xFFE2DAD0),
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Good food. One team decision.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: labelColor,
                              letterSpacing: 0.3,
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
        ),
      ),
    );
  }
}

class _HoverTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final Color borderColor;
  final Color labelColor;
  final Color primaryColor;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  const _HoverTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.borderColor,
    required this.labelColor,
    required this.primaryColor,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  State<_HoverTextField> createState() => _HoverTextFieldState();
}

class _HoverTextFieldState extends State<_HoverTextField> {
  bool _isHovered = false;
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeBorderColor = _isFocused
        ? widget.primaryColor
        : (_isHovered
              ? widget.primaryColor.withValues(alpha: 0.45)
              : widget.borderColor);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _isFocused
                  ? widget.primaryColor.withValues(alpha: 0.12)
                  : (_isHovered
                        ? Colors.black.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.02)),
              blurRadius: _isFocused ? 12 : (_isHovered ? 10 : 6),
              offset: Offset(0, _isHovered || _isFocused ? 3 : 2),
            ),
          ],
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.obscureText == true,
          enableSuggestions: widget.obscureText != true,
          autocorrect: widget.obscureText != true,
          keyboardType: widget.keyboardType,
          style: const TextStyle(fontSize: 15, color: Color(0xFF2C2420)),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(color: widget.labelColor, fontSize: 15),
            prefixIcon: Icon(
              widget.icon,
              color: _isFocused ? widget.primaryColor : widget.labelColor,
              size: 20,
            ),
            suffixIcon: widget.suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: activeBorderColor, width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: activeBorderColor, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: widget.primaryColor, width: 1.6),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
