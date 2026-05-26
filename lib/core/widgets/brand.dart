import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Signature Vistar brand widgets: the orbit / breathing S-mark loader,
/// the ambient dark canvas with a faint S watermark, and a ribbon
/// gradient ShaderMask helper. These reproduce the five "S treatments"
/// from the design system on Flutter.
const String kSMarkAsset = 'assets/logo.png';
const String kWordmarkAsset = 'assets/logo_name.png';

/// Renders [child] with the ribbon gradient applied as a fill via a
/// ShaderMask — for KPI numbers, brand headlines, accent words.
class RibbonText extends StatelessWidget {
  const RibbonText(this.text, {super.key, this.style, this.textAlign});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (rect) => ribbonGradient().createShader(rect),
      child: Text(
        text,
        textAlign: textAlign,
        // Color must be white for ShaderMask srcIn to take effect.
        style: (style ?? const TextStyle()).copyWith(color: Colors.white),
      ),
    );
  }
}

/// A thin ribbon-gradient pill — useful as a section accent bar next
/// to titles ("the acc" from the design system).
class RibbonAccent extends StatelessWidget {
  const RibbonAccent({super.key, this.width = 5, this.height = 16, this.radius = 6});
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: ribbonGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Ambient page backdrop — radial aurora glows + a faint rotated S
/// watermark + subtle grain. Drop it as the bottom-most child of a
/// stack to give any screen the premium dark canvas. Pointer-event
/// transparent.
class AmbientCanvas extends StatelessWidget {
  const AmbientCanvas({super.key, this.intensity = 1.0});

  /// 0..1, scales the glow opacities. Use 0.5 inside cards/sheets to
  /// avoid double-saturation.
  final double intensity;

  @override
  Widget build(BuildContext context) {
    // Subscribe to the global brightness notifier so the canvas
    // refreshes on theme toggle even when constructed as
    // `const AmbientCanvas()` (Flutter would otherwise skip rebuilds
    // of const widgets when only their parent rebuilds).
    return AnimatedBuilder(
      animation: appBrightness,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    // Light mode runs noticeably softer — the auroras would otherwise
    // saturate the paper-white canvas and tint everything pink. Dark
    // mode keeps the original premium glow.
    final isDark = appBrightness.value == Brightness.dark;
    final auroraScale = isDark ? 1.0 : 0.55;
    final watermarkOpacity = isDark ? 0.05 : 0.045;

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Deep base.
          ColoredBox(color: AppColors.bgDeep),
          // Top-left violet aurora.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.88, -1.1),
                radius: 0.9,
                colors: [
                  const Color(0xFF7A1FB0)
                      .withValues(alpha: 0.22 * intensity * auroraScale),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Top-right pink aurora.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(1.05, -0.9),
                radius: 0.85,
                colors: [
                  const Color(0xFFE0218A)
                      .withValues(alpha: 0.16 * intensity * auroraScale),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Bottom-right amber aurora.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.6, 1.1),
                radius: 1.0,
                colors: [
                  const Color(0xFFF06000)
                      .withValues(alpha: 0.12 * intensity * auroraScale),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Faint rotated S watermark on the right edge.
          Positioned(
            right: -80,
            top: 0,
            bottom: 0,
            child: Center(
              child: Transform.rotate(
                angle: 4 * 3.1415926 / 180,
                child: Opacity(
                  opacity: watermarkOpacity * intensity,
                  child: SizedBox(
                    width: 620,
                    height: 620,
                    child: Image.asset(kSMarkAsset, fit: BoxFit.contain),
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

/// Faint S-corner accent for cards. Place inside a `Stack` with the
/// card content. Bottom-right by default.
class CardCornerS extends StatelessWidget {
  const CardCornerS({super.key, this.size = 120, this.opacity = 0.05});
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: -size * 0.22,
      bottom: -size * 0.25,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: SizedBox(
            width: size,
            height: size,
            child: Image.asset(kSMarkAsset, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

/// The orbit / breathing S-mark loader from the design system. Two
/// counter-spinning ribbon-tinted rings around a softly pulsing S, with
/// optional wordmark + ribbon progress bar underneath (`splash: true`).
class BrandLoader extends StatefulWidget {
  const BrandLoader({
    super.key,
    this.size = 96,
    this.splash = false,
    this.label,
  });

  /// Diameter of the S mark (rings extend ~2x this size).
  final double size;

  /// If true, lays out the bigger splash variant: orbit + wordmark +
  /// ribbon progress bar (use as the app boot screen).
  final bool splash;

  /// Optional caption shown below the loader.
  final String? label;

  @override
  State<BrandLoader> createState() => _BrandLoaderState();
}

class _BrandLoaderState extends State<BrandLoader>
    with TickerProviderStateMixin {
  late final AnimationController _ring1;
  late final AnimationController _ring2;
  late final AnimationController _breathe;
  late final AnimationController _bar;

  @override
  void initState() {
    super.initState();
    _ring1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _ring2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: false);
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _bar = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ring1.dispose();
    _ring2.dispose();
    _breathe.dispose();
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Subscribe to the global brightness notifier so the loader's
    // pink halo softens / brightens on theme toggle, even when this
    // widget is hosted as a `const BrandLoader(...)` (Flutter would
    // otherwise skip rebuilds when only the parent rebuilds).
    return AnimatedBuilder(
      animation: appBrightness,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    // Soften the pink halo on light mode so the orbit reads as a
    // halo, not a fluorescent stamp.
    final isDark = appBrightness.value == Brightness.dark;
    final haloAlpha = isDark ? 0.55 : 0.28;
    final orbit = SizedBox(
      width: widget.size * 2.08,
      height: widget.size * 2.08,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring (forward).
          AnimatedBuilder(
            animation: _ring1,
            builder: (_, __) => Transform.rotate(
              angle: _ring1.value * 2 * 3.1415926,
              child: CustomPaint(
                size: Size.square(widget.size * 2.08),
                painter: _ArcRingPainter(
                  colors: [
                    AppColors.ribbonPink.withValues(alpha: 0.65),
                    AppColors.ribbonOrange.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
          ),
          // Inner ring (reverse).
          AnimatedBuilder(
            animation: _ring2,
            builder: (_, __) => Transform.rotate(
              angle: -_ring2.value * 2 * 3.1415926,
              child: CustomPaint(
                size: Size.square(widget.size * 1.6),
                painter: _ArcRingPainter(
                  colors: [
                    AppColors.ribbonViolet.withValues(alpha: 0.65),
                    AppColors.ribbonAmber.withValues(alpha: 0.45),
                  ],
                  startSweep: 3.1415926 / 2,
                ),
              ),
            ),
          ),
          // Breathing S mark.
          AnimatedBuilder(
            animation: _breathe,
            builder: (_, child) {
              final t = Curves.easeInOut.transform(_breathe.value);
              final scale = 0.92 + (t * 0.12);
              return Transform.scale(scale: scale, child: child);
            },
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ribbonPink.withValues(alpha: haloAlpha),
                      blurRadius: 26,
                    ),
                  ],
                ),
                child: Image.asset(kSMarkAsset, fit: BoxFit.contain),
              ),
            ),
          ),
        ],
      ),
    );

    if (!widget.splash) {
      if (widget.label == null) return orbit;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          orbit,
          const SizedBox(height: 14),
          Text(
            widget.label!,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
        ],
      );
    }

    // Splash variant — orbit + wordmark + ribbon progress bar.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        orbit,
        const SizedBox(height: 28),
        SizedBox(
          width: 220,
          child: Image.asset(kWordmarkAsset, fit: BoxFit.contain),
        ),
        const SizedBox(height: 18),
        if (widget.label != null) ...[
          Text(
            widget.label!.toUpperCase(),
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Ribbon progress bar.
        SizedBox(
          width: 200,
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(color: AppColors.line),
                AnimatedBuilder(
                  animation: _bar,
                  builder: (_, __) {
                    final t = _bar.value;
                    return Align(
                      alignment: Alignment(-1 + t * 4.7, 0),
                      child: Container(
                        width: 80,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: ribbonGradient(),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ArcRingPainter extends CustomPainter {
  _ArcRingPainter({required this.colors, this.startSweep = 0});
  final List<Color> colors;
  final double startSweep;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const stroke = 1.5;
    // Two arcs: top with first color, bottom-ish with second.
    final paint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..color = colors[0];
    canvas.drawArc(
      rect.deflate(stroke / 2),
      startSweep,
      3.1415926 * 0.85,
      false,
      paint1,
    );
    final paint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..color = colors[1];
    canvas.drawArc(
      rect.deflate(stroke / 2),
      startSweep + 3.1415926,
      3.1415926 * 0.55,
      false,
      paint2,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcRingPainter old) =>
      old.colors != colors || old.startSweep != startSweep;
}
