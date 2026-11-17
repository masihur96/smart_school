import 'package:flutter/material.dart';
import 'package:flutter_tour_guide/src/tour_step.dart';
import 'package:flutter_tour_guide/src/tour_theme.dart';

class TourOverlay extends StatefulWidget {
  final List<TourStep> steps;
  final TourTheme theme;
  final VoidCallback onDone;
  final VoidCallback? onSkip;

  const TourOverlay({
    super.key,
    required this.steps,
    required this.theme,
    required this.onDone,
    this.onSkip,
  });

  @override
  State<TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<TourOverlay>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Rect? _targetRect;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _measureAndShow();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  TourStep get _step => widget.steps[_currentIndex];

  Future<void> _measureAndShow() async {
    final step = _step;

    if (step.onBefore != null) await step.onBefore!();

    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    final ctx = step.targetKey.currentContext;
    if (ctx != null && ctx.mounted) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
      await Future.delayed(const Duration(milliseconds: 350));
    }

    if (!mounted) return;
    setState(() => _targetRect = _getRenderRect(step));
    _animController.forward(from: 0);
  }

  Rect? _getRenderRect(TourStep step) {
    final ctx = step.targetKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _goTo(int index) async {
    await _animController.reverse();
    if (!mounted) return;
    setState(() {
      _currentIndex = index;
      _targetRect = null;
    });
    await _measureAndShow();
  }

  void _next() {
    if (_currentIndex < widget.steps.length - 1) {
      _goTo(_currentIndex + 1);
    } else {
      widget.onDone();
    }
  }

  void _prev() {
    if (_currentIndex > 0) _goTo(_currentIndex - 1);
  }

  void _skip() {
    widget.onSkip?.call();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final rect = _targetRect;
    final step = _step;
    final theme = widget.theme;
    final padding = step.padding ?? theme.spotlightPadding;
    final radius = step.radius ?? theme.spotlightRadius;
    final isLast = _currentIndex == widget.steps.length - 1;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Stack(
        children: [
          // ── Scrim ──────────────────────────────────────────────────────────
          GestureDetector(
            onTap: _next,
            child: CustomPaint(
              size: size,
              painter: rect != null
                  ? _SpotlightPainter(
                      hole: rect.inflate(padding),
                      radius: radius,
                      scrimOpacity: theme.scrimOpacity,
                    )
                  : _FullScrimPainter(scrimOpacity: theme.scrimOpacity),
            ),
          ),

          // ── Tooltip ────────────────────────────────────────────────────────
          _buildTooltip(context, rect, step, theme, padding, isLast, size),
        ],
      ),
    );
  }

  Widget _buildTooltip(
    BuildContext context,
    Rect? rect,
    TourStep step,
    TourTheme theme,
    double padding,
    bool isLast,
    Size screenSize,
  ) {
    const tooltipWidth = 280.0;
    const tooltipMaxHeight = 220.0;
    const arrowSize = 10.0;
    const margin = 16.0;

    final card = _TooltipCard(
      step: step,
      theme: theme,
      currentIndex: _currentIndex,
      total: widget.steps.length,
      isLast: isLast,
      onNext: _next,
      onPrev: _currentIndex > 0 ? _prev : null,
      onSkip: _skip,
    );

    // No target — center the card with no arrow.
    if (rect == null) {
      return Positioned(
        left: (screenSize.width - tooltipWidth) / 2,
        top: screenSize.height / 2 - tooltipMaxHeight / 2,
        width: tooltipWidth,
        child: Material(color: Colors.transparent, child: card),
      );
    }

    final holeBottom = rect.bottom + padding;
    final holeTop = rect.top - padding;
    final spaceBelow = screenSize.height - holeBottom;
    final showAbove = spaceBelow < tooltipMaxHeight + arrowSize + margin * 2;

    double left = rect.center.dx - tooltipWidth / 2;
    left = left.clamp(margin, screenSize.width - tooltipWidth - margin);

    final top = showAbove
        ? holeTop - tooltipMaxHeight - arrowSize - 8
        : holeBottom + arrowSize + 8;

    final arrowLeft = (rect.center.dx - left - arrowSize).clamp(
      margin,
      tooltipWidth - margin - arrowSize * 2,
    );

    return Positioned(
      left: left,
      top: top.clamp(margin, screenSize.height - tooltipMaxHeight - margin),
      width: tooltipWidth,
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!showAbove)
              _Arrow(
                left: arrowLeft,
                size: arrowSize,
                pointUp: true,
                color: theme.cardColor,
              ),
            card,
            if (showAbove)
              _Arrow(
                left: arrowLeft,
                size: arrowSize,
                pointUp: false,
                color: theme.cardColor,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Painters ──────────────────────────────────────────────────────────────────

class _SpotlightPainter extends CustomPainter {
  final Rect hole;
  final double radius;
  final double scrimOpacity;

  const _SpotlightPainter({
    required this.hole,
    required this.radius,
    required this.scrimOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: scrimOpacity);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(hole, Radius.circular(radius)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => old.hole != hole;
}

class _FullScrimPainter extends CustomPainter {
  final double scrimOpacity;
  const _FullScrimPainter({required this.scrimOpacity});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black.withValues(alpha: scrimOpacity),
    );
  }

  @override
  bool shouldRepaint(_FullScrimPainter old) => old.scrimOpacity != scrimOpacity;
}

// ── Tooltip card ──────────────────────────────────────────────────────────────

class _TooltipCard extends StatelessWidget {
  final TourStep step;
  final TourTheme theme;
  final int currentIndex;
  final int total;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback? onPrev;
  final VoidCallback onSkip;

  const _TooltipCard({
    required this.step,
    required this.theme,
    required this.currentIndex,
    required this.total,
    required this.isLast,
    required this.onNext,
    required this.onSkip,
    this.onPrev,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(theme.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: counter + skip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${currentIndex + 1} of $total', style: theme.captionStyle),
              if (!isLast)
                GestureDetector(
                  onTap: onSkip,
                  child: Text('Skip tour', style: theme.captionStyle),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(step.title, style: theme.titleStyle),
          const SizedBox(height: 6),
          Text(step.body, style: theme.bodyStyle),
          const SizedBox(height: 14),
          // Progress dots
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(total, (i) {
                final active = i == currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 4),
                  width: active ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? theme.accentColor : const Color(0xFFCCCCCC),
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          // Prev / Next buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (onPrev != null)
                GestureDetector(
                  onTap: onPrev,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.accentColor, width: 1.5),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'Prev',
                      style: TextStyle(
                        color: theme.accentColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              GestureDetector(
                onTap: onNext,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.accentColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    isLast ? 'Done' : 'Next',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Arrow pointer ─────────────────────────────────────────────────────────────

class _Arrow extends StatelessWidget {
  final double left;
  final double size;
  final bool pointUp;
  final Color color;

  const _Arrow({
    required this.left,
    required this.size,
    required this.pointUp,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: left),
      child: CustomPaint(
        size: Size(size * 2, size),
        painter: _ArrowPainter(pointUp: pointUp, color: color),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final bool pointUp;
  final Color color;
  const _ArrowPainter({required this.pointUp, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    if (pointUp) {
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => false;
}
