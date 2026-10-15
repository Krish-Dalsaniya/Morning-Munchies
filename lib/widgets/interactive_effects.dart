import 'package:flutter/material.dart';

/// Interactive card that lifts up, expands shadow, and scales gently on web hover & mobile touch.
class HoverLiftCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? color;
  final Border? border;
  final Border? hoverBorder;

  const HoverLiftCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin,
    this.padding,
    this.borderRadius,
    this.color,
    this.border,
    this.hoverBorder,
  });

  @override
  State<HoverLiftCard> createState() => _HoverLiftCardState();
}

class _HoverLiftCardState extends State<HoverLiftCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(16);
    final theme = Theme.of(context);
    final cardColor = widget.color ?? theme.colorScheme.surface;

    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: MouseRegion(
        cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() {
          _isHovered = false;
          _isPressed = false;
        }),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _isPressed ? 0.985 : (_isHovered ? 1.01 : 1.0),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: AnimatedSlide(
              offset: Offset(0.0, _isPressed ? 0.005 : (_isHovered ? -0.012 : 0.0)),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: widget.padding,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: radius,
                  border: _isHovered ? (widget.hoverBorder ?? widget.border) : widget.border,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.03),
                      blurRadius: _isHovered ? 16 : 8,
                      offset: Offset(0, _isHovered ? 8 : 2),
                      spreadRadius: _isHovered ? 1 : 0,
                    ),
                  ],
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tactile button that smoothly springs/bounces on click and scales up on hover.
class BouncingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Duration duration;
  final double scaleFactor;

  const BouncingButton({
    super.key,
    required this.child,
    this.onPressed,
    this.duration = const Duration(milliseconds: 140),
    this.scaleFactor = 0.95,
  });

  @override
  State<BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<BouncingButton> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onPressed != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTapDown: widget.onPressed != null ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: widget.onPressed != null
            ? (_) {
                setState(() => _isPressed = false);
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? widget.scaleFactor : (_isHovered ? 1.02 : 1.0),
          duration: widget.duration,
          curve: Curves.easeOutBack,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Smooth staggered entrance animation (fade + slide up).
class FadeSlideEntry extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;

  const FadeSlideEntry({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = const Duration(milliseconds: 40),
    this.duration = const Duration(milliseconds: 350),
  });

  @override
  State<FadeSlideEntry> createState() => _FadeSlideEntryState();
}

class _FadeSlideEntryState extends State<FadeSlideEntry> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay * widget.index, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Animated progress indicator with smooth bar tweening.
class AnimatedVoteBar extends StatelessWidget {
  final double value;
  final Color color;
  final Color backgroundColor;
  final double height;
  final BorderRadius borderRadius;

  const AnimatedVoteBar({
    super.key,
    required this.value,
    required this.color,
    required this.backgroundColor,
    this.height = 8,
    this.borderRadius = const BorderRadius.all(Radius.circular(99)),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return ClipRRect(
          borderRadius: borderRadius,
          child: Container(
            height: height,
            color: backgroundColor,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: animatedValue,
                child: Container(color: color),
              ),
            ),
          ),
        );
      },
    );
  }
}
