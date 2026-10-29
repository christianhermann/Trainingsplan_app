import 'package:flutter/material.dart';

/// A fun, energetic comic-style Ronnie Coleman loading indicator.
/// Shows Ronnie lifting heavy weights with iconic catchphrases.
class RonnieLoadingIndicator extends StatefulWidget {
  const RonnieLoadingIndicator({
    super.key,
    this.message,
    this.size = 140,
    this.compact = false,
  });

  const RonnieLoadingIndicator.compact({
    super.key,
    this.message,
    this.size = 36,
  }) : compact = true;

  final String? message;
  final double size;
  final bool compact;

  @override
  State<RonnieLoadingIndicator> createState() => _RonnieLoadingIndicatorState();
}

class _RonnieLoadingIndicatorState extends State<RonnieLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _liftAnimation;
  late final Animation<double> _plateWobble;

  final List<String> _catchphrases = const [
    'YEAH BUDDY! 🏋️‍♂️',
    'LIGHT WEIGHT BABY!',
    "AIN'T NOTHIN' BUT A PEANUT!",
    'EVERYBODY WANNA BE A BODYBUILDER!',
  ];

  int _phraseIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.reverse();
        } else if (status == AnimationStatus.dismissed) {
          setState(() {
            _phraseIndex = (_phraseIndex + 1) % _catchphrases.length;
          });
          _controller.forward();
        }
      });

    // Smooth lifting acceleration curve
    _liftAnimation = Tween<double>(begin: 0.0, end: -14.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _plateWobble = Tween<double>(begin: -0.04, end: 0.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (widget.compact) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _liftAnimation.value * 0.3),
              child: child,
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.size / 2),
            child: Image.asset(
              'assets/images/ronnie_lifting.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.fitness_center_rounded,
                size: widget.size * 0.7,
                color: cs.primary,
              ),
            ),
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Animated Ronnie lifting badge ──────────────────────────────
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _liftAnimation.value),
                  child: Transform.rotate(
                    angle: _plateWobble.value,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.35),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                  border: Border.all(
                    color: cs.primary,
                    width: 3.5,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/ronnie_lifting.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: cs.primaryContainer,
                      child: Icon(
                        Icons.fitness_center_rounded,
                        size: widget.size * 0.5,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Iconic Catchphrase Pill ────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Container(
                key: ValueKey(_phraseIndex),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  _catchphrases[_phraseIndex],
                  style: tt.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
            ),

            if (widget.message != null) ...[
              const SizedBox(height: 12),
              Text(
                widget.message!,
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ── Bouncing barbell mini bar ──────────────────────────────────
            SizedBox(
              width: 140,
              child: LinearProgressIndicator(
                backgroundColor: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
