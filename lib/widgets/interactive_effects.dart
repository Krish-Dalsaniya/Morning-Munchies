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

/// Pure Flutter smooth shimmer effect for skeleton loaders
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFF0EAE1),
    this.highlightColor = const Color(0xFFFAF5EE),
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.1, 0.5, 0.9],
              transform: _SlidingGradientTransform(slidePercent: _controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0.0, 0.0);
  }
}

/// Rounded rectangle skeleton placeholder
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton for a voting food card in VoteTab
class ShimmerDishCard extends StatelessWidget {
  const ShimmerDishCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE5DA), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ShimmerBox(width: 80, height: 14, borderRadius: 6),
              ShimmerBox(width: 60, height: 16, borderRadius: 10),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: 150, height: 18, borderRadius: 6),
                    SizedBox(height: 8),
                    ShimmerBox(width: 70, height: 14, borderRadius: 6),
                    SizedBox(height: 10),
                    ShimmerBox(height: 12, borderRadius: 4),
                    SizedBox(height: 4),
                    ShimmerBox(width: 140, height: 12, borderRadius: 4),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              const ShimmerBox(width: 95, height: 72, borderRadius: 14),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: const [
              Expanded(child: ShimmerBox(height: 42, borderRadius: 12)),
              SizedBox(width: 10),
              Expanded(child: ShimmerBox(height: 42, borderRadius: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shimmer list placeholder for dishes
class ShimmerDishList extends StatelessWidget {
  final int count;
  const ShimmerDishList({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: List.generate(count, (_) => const ShimmerDishCard()),
      ),
    );
  }
}

/// Shimmer skeleton for the wallet tab
class ShimmerWalletList extends StatelessWidget {
  const ShimmerWalletList({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // Balance card skeleton
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: const [
                ShimmerBox(width: 58, height: 58, borderRadius: 29),
                SizedBox(height: 14),
                ShimmerBox(width: 110, height: 14, borderRadius: 6),
                SizedBox(height: 10),
                ShimmerBox(width: 160, height: 36, borderRadius: 8),
                SizedBox(height: 16),
                ShimmerBox(width: 150, height: 42, borderRadius: 14),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const ShimmerBox(width: 160, height: 22, borderRadius: 6),
          const SizedBox(height: 14),
          // Transaction row skeletons
          for (int i = 0; i < 4; i++)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: const [
                  ShimmerBox(width: 44, height: 44, borderRadius: 22),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 120, height: 16, borderRadius: 6),
                        SizedBox(height: 6),
                        ShimmerBox(width: 80, height: 12, borderRadius: 4),
                      ],
                    ),
                  ),
                  ShimmerBox(width: 60, height: 18, borderRadius: 6),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Engaging and friendly empty state widget with cheerful micro-copy and warm visuals
class CheerfulEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? customBadge;

  const CheerfulEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.customBadge,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEDE5DA), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF35170F).withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cheerful badge icon
            customBadge ??
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFEDE4), Color(0xFFFDE0CF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE94B0C).withValues(alpha: 0.15),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 38,
                    color: const Color(0xFFE94B0C),
                  ),
                ),
            const SizedBox(height: 20),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Color(0xFF35170F),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF7A6A63),
                height: 1.45,
              ),
            ),

            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              BouncingButton(
                onPressed: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B1A), Color(0xFFE94B0C)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE94B0C).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        actionLabel!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
