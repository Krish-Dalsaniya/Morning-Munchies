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

  void _showAlert({
    required String title,
    required String message,
    bool isError = true,
    bool isSuccess = false,
  }) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final Color badgeBg = isSuccess
            ? const Color(0xFFE8F5E9)
            : (isError ? const Color(0xFFFFEBE8) : const Color(0xFFFFF4E5));
        final Color iconColor = isSuccess
            ? const Color(0xFF2E7D32)
            : (isError ? const Color(0xFFD32F2F) : const Color(0xFFE94B0C));
        final IconData icon = isSuccess
            ? Icons.check_circle_rounded
            : (isError ? Icons.error_outline_rounded : Icons.info_outline_rounded);

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF35170F).withValues(alpha: 0.15),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon badge
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: badgeBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 30),
                  ),
                  const SizedBox(height: 18),

                  // Title
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF35170F),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Message
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF5A524C),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE94B0C),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Got it',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final pass = _pass.text;
    final name = _name.text.trim();

    if (email.isEmpty || pass.isEmpty || (_signup && name.isEmpty)) {
      _showAlert(
        title: 'Missing Details',
        message: 'Please fill in all required fields to continue.',
        isError: true,
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
          _showAlert(
            title: 'Account Created!',
            message: 'Your account has been created. Please check your email or verify in your Supabase dashboard.',
            isSuccess: true,
            isError: false,
          );
        }
      } else {
        await supabase.auth.signInWithPassword(email: email, password: pass);
      }
    } on AuthException catch (e) {
      if (mounted) {
        final msg =
            e.message.toLowerCase().contains('invalid login credentials')
            ? 'Invalid email or password. If you are new, tap "Sign up" below to create an account.'
            : e.message;
        _showAlert(
          title: 'Login Failed',
          message: msg,
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showAlert(
          title: 'Authentication Error',
          message: '$e',
          isError: true,
        );
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
    const primaryOrange = Color(0xFFE94B0C);
    const darkBrown = Color(0xFF35170F);
    const subtitleColor = Color(0xFF7A6A63);

    final screenHeight = MediaQuery.sizeOf(context).height;
    final heroHeight = screenHeight < 700 ? 230.0 : 285.0;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background warm cream fill
          Positioned.fill(
            child: Container(color: bgColor),
          ),

          // Top-left watermark chef hat outline
          Positioned(
            top: 36,
            left: 18,
            child: IgnorePointer(
              child: Transform.rotate(
                angle: -0.15,
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: CustomPaint(
                    painter: _ChefHatPainter(
                      color: const Color(0xFFE8DACB).withValues(alpha: 0.65),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Top-left subtle orange droplet
          Positioned(
            top: 110,
            left: 48,
            child: IgnorePointer(
              child: Transform.rotate(
                angle: 0.35,
                child: Container(
                  width: 8,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B1A).withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),

          // Top-right watermark fork & knife outline
          Positioned(
            top: 32,
            right: 22,
            child: IgnorePointer(
              child: Transform.rotate(
                angle: 0.12,
                child: SizedBox(
                  width: 54,
                  height: 54,
                  child: CustomPaint(
                    painter: _UtensilsPainter(
                      color: const Color(0xFFE8DACB).withValues(alpha: 0.65),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom soft wave fluid shapes
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 150,
            child: IgnorePointer(
              child: CustomPaint(
                painter: _BottomWavePainter(),
              ),
            ),
          ),

          // Bottom-left decorative droplets
          Positioned(
            bottom: 64,
            left: 24,
            child: IgnorePointer(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.rotate(
                    angle: -0.4,
                    child: Container(
                      width: 9,
                      height: 17,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B1A).withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Transform.rotate(
                    angle: 0.3,
                    child: Container(
                      width: 7,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B1A).withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main scrollable content
          SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Hero Section: Office Munchies Illustration
                      FadeSlideEntry(
                        index: 0,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 26, 16, 12),
                          child: SizedBox(
                            height: heroHeight,
                            width: double.infinity,
                            child: Image.asset(
                              'assets/images/login_illustration.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 36, bottom: 20),
                                  child: Column(
                                    children: [
                                      Image.asset(
                                        'assets/images/logo.png',
                                        height: 120,
                                        errorBuilder: (ctx, err, stack) => const Icon(
                                          Icons.fastfood_rounded,
                                          size: 72,
                                          color: Colors.orange,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Office Munchies',
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: primaryOrange,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      // Form Container Card
                      FadeSlideEntry(
                        index: 1,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4A2511).withValues(alpha: 0.06),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Heading
                              Text(
                                _signup ? 'Create Account' : 'Welcome Back!',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: darkBrown,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Subtitle
                              Text(
                                _signup
                                    ? 'Sign up to continue with Office Munchies'
                                    : 'Log in to continue with Office Munchies',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: subtitleColor,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Name Field (only shown on Sign Up)
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
                                          borderColor: const Color(0xFFEFE8DF),
                                          labelColor: const Color(0xFF9E8E84),
                                          primaryColor: primaryOrange,
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
                                borderColor: const Color(0xFFEFE8DF),
                                labelColor: const Color(0xFF9E8E84),
                                primaryColor: primaryOrange,
                              ),
                              const SizedBox(height: 14),

                              // Password Field
                              _HoverTextField(
                                controller: _pass,
                                hintText: 'Password',
                                icon: Icons.lock_outline_rounded,
                                obscureText: _obscurePassword == true,
                                borderColor: const Color(0xFFEFE8DF),
                                labelColor: const Color(0xFF9E8E84),
                                primaryColor: primaryOrange,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword == true
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: const Color(0xFF8C7A72),
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
                                child: Container(
                                  height: 52,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFF6B1A), Color(0xFFE94B0C)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFE94B0C).withValues(alpha: 0.35),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: _busy
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              _signup ? 'Create Account' : 'Log In',
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Toggle Mode
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
                                                color: primaryOrange,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 26),

                              // Footer Divider & Tagline
                              Row(
                                children: [
                                  const Expanded(
                                    child: Divider(
                                      color: Color(0xFFEFE8DF),
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Icon(
                                      Icons.restaurant_rounded,
                                      size: 18,
                                      color: const Color(0xFF8C7A72).withValues(alpha: 0.8),
                                    ),
                                  ),
                                  const Expanded(
                                    child: Divider(
                                      color: Color(0xFFEFE8DF),
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Good food. One team decision.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8C7A72),
                                  letterSpacing: 0.2,
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
        ],
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
    this.borderColor = const Color(0xFFEFE8DF),
    this.labelColor = const Color(0xFF9E8E84),
    this.primaryColor = const Color(0xFFE94B0C),
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
    final primaryOrange = widget.primaryColor;
    final borderColor = widget.borderColor;
    const peachBg = Color(0xFFFFEDE4);
    const iconColor = Color(0xFFC04E1E);

    final activeBorderColor = _isFocused
        ? primaryOrange
        : (_isHovered
              ? primaryOrange.withValues(alpha: 0.45)
              : borderColor);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: activeBorderColor,
            width: _isFocused ? 1.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _isFocused
                  ? primaryOrange.withValues(alpha: 0.12)
                  : (_isHovered
                        ? Colors.black.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.015)),
              blurRadius: _isFocused ? 12 : (_isHovered ? 8 : 4),
              offset: Offset(0, _isHovered || _isFocused ? 3 : 1),
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
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF35170F),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: widget.labelColor,
              fontSize: 15,
              fontWeight: FontWeight.normal,
            ),
            prefixIcon: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.fromLTRB(8, 7, 10, 7),
              decoration: BoxDecoration(
                color: peachBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.icon,
                color: iconColor,
                size: 19,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 54,
              minHeight: 50,
            ),
            suffixIcon: widget.suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the subtle watermark chef hat outline
class _ChefHatPainter extends CustomPainter {
  final Color color;
  const _ChefHatPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Brim of hat
    final brimPath = Path()
      ..moveTo(w * 0.22, h * 0.82)
      ..lineTo(w * 0.78, h * 0.82)
      ..lineTo(w * 0.74, h * 0.94)
      ..lineTo(w * 0.26, h * 0.94)
      ..close();
    canvas.drawPath(brimPath, paint);

    // Puffs of hat
    final puffPath = Path()
      ..moveTo(w * 0.24, h * 0.80)
      ..cubicTo(w * 0.04, h * 0.65, w * 0.04, h * 0.35, w * 0.30, h * 0.32)
      ..cubicTo(w * 0.32, h * 0.08, w * 0.68, h * 0.08, w * 0.70, h * 0.32)
      ..cubicTo(w * 0.96, h * 0.35, w * 0.96, h * 0.65, w * 0.76, h * 0.80);
    canvas.drawPath(puffPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for the subtle watermark fork and knife outline
class _UtensilsPainter extends CustomPainter {
  final Color color;
  const _UtensilsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Fork on left
    final forkX = w * 0.32;
    canvas.drawLine(Offset(forkX, h * 0.45), Offset(forkX, h * 0.92), paint);
    canvas.drawLine(Offset(forkX - 6, h * 0.12), Offset(forkX - 6, h * 0.38), paint);
    canvas.drawLine(Offset(forkX, h * 0.12), Offset(forkX, h * 0.38), paint);
    canvas.drawLine(Offset(forkX + 6, h * 0.12), Offset(forkX + 6, h * 0.38), paint);
    final forkBase = Path()
      ..moveTo(forkX - 6, h * 0.38)
      ..quadraticBezierTo(forkX, h * 0.48, forkX + 6, h * 0.38);
    canvas.drawPath(forkBase, paint);

    // Knife on right
    final knifeX = w * 0.70;
    canvas.drawLine(Offset(knifeX, h * 0.45), Offset(knifeX, h * 0.92), paint);
    final blade = Path()
      ..moveTo(knifeX, h * 0.45)
      ..lineTo(knifeX, h * 0.12)
      ..quadraticBezierTo(knifeX + 11, h * 0.22, knifeX, h * 0.45);
    canvas.drawPath(blade, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for the layered bottom fluid waves
class _BottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Back wave (lighter warm peach)
    final backPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFFEE8DC).withValues(alpha: 0.8),
          const Color(0xFFFBD7C0).withValues(alpha: 0.65),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final backPath = Path()
      ..moveTo(0, h * 0.45)
      ..quadraticBezierTo(w * 0.25, h * 0.20, w * 0.60, h * 0.45)
      ..quadraticBezierTo(w * 0.85, h * 0.62, w, h * 0.35)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(backPath, backPaint);

    // Front wave (warm peach-orange curve)
    final frontPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFF8CBA8).withValues(alpha: 0.75),
          const Color(0xFFF4B892).withValues(alpha: 0.60),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.3, w, h * 0.7));

    final frontPath = Path()
      ..moveTo(0, h * 0.68)
      ..quadraticBezierTo(w * 0.35, h * 0.48, w * 0.72, h * 0.66)
      ..quadraticBezierTo(w * 0.88, h * 0.75, w, h * 0.60)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(frontPath, frontPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
