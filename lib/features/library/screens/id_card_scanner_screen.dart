import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Result returned after a successful scan + confirmation.
class ScanResult {
  final String studentId;
  final String studentName;
  final String rawBarcode;

  const ScanResult({
    required this.studentId,
    required this.studentName,
    required this.rawBarcode,
  });
}

/// Full-screen barcode scanner that:
/// 1. Opens the camera with a scan overlay.
/// 2. On a successful barcode read, parses the student info.
/// 3. Shows a confirmation bottom sheet.
/// 4. Returns a [ScanResult] to the caller on confirmation.
class IdCardScannerScreen extends StatefulWidget {
  const IdCardScannerScreen({super.key});

  @override
  State<IdCardScannerScreen> createState() => _IdCardScannerScreenState();
}

class _IdCardScannerScreenState extends State<IdCardScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerCtrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _torchOn = false;
  bool _processingResult = false;

  // Pulse animation for the scan line
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scannerCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  /// Parse the barcode value into a student info map.
  /// Expected format from a student ID card barcode:
  ///   "ID:<studentId>|NAME:<studentName>"
  /// Falls back gracefully for plain IDs or QR-style JSON.
  _ParsedStudent _parseBarcode(String raw) {
    // Format 1: "ID:abc123|NAME:John Doe"
    if (raw.contains('ID:') && raw.contains('NAME:')) {
      final idMatch = RegExp(r'ID:([^|]+)').firstMatch(raw);
      final nameMatch = RegExp(r'NAME:([^|]+)').firstMatch(raw);
      return _ParsedStudent(
        id: idMatch?.group(1)?.trim() ?? raw,
        name: nameMatch?.group(1)?.trim() ?? 'Unknown',
        raw: raw,
      );
    }

    // Format 2: JSON {"id":"...", "name":"..."}
    if (raw.startsWith('{')) {
      try {
        // Simple regex parse without dart:convert
        final idMatch = RegExp(r'"id"\s*:\s*"([^"]+)"').firstMatch(raw);
        final nameMatch = RegExp(r'"name"\s*:\s*"([^"]+)"').firstMatch(raw);
        if (idMatch != null) {
          return _ParsedStudent(
            id: idMatch.group(1)!,
            name: nameMatch?.group(1) ?? 'Unknown',
            raw: raw,
          );
        }
      } catch (_) {}
    }

    // Fallback: treat the whole barcode as the student ID
    return _ParsedStudent(id: raw, name: 'Unknown Student', raw: raw);
  }

  void _onBarcodeDetected(BarcodeCapture capture) async {
    if (_processingResult) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    setState(() => _processingResult = true);
    await _scannerCtrl.stop();

    final parsed = _parseBarcode(raw);

    if (!mounted) return;
    _showConfirmationSheet(parsed);
  }

  void _showConfirmationSheet(_ParsedStudent student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => _ConfirmationSheet(
        student: student,
        onConfirm: () {
          Navigator.of(context).pop(); // close sheet
          Navigator.of(context).pop(
            ScanResult(
              studentId: student.id,
              studentName: student.name,
              rawBarcode: student.raw,
            ),
          );
        },
        onRescan: () {
          Navigator.of(context).pop(); // close sheet
          setState(() => _processingResult = false);
          _scannerCtrl.start();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera preview ──────────────────────────────────
          MobileScanner(
            controller: _scannerCtrl,
            onDetect: _onBarcodeDetected,
          ),

          // ── Dark vignette overlay ────────────────────────────
          _ScanOverlay(pulseAnim: _pulseAnim),

          // ── Top bar ─────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                  const Spacer(),
                  // Title
                  const Text(
                    'Scan ID Card',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  // Torch toggle
                  GestureDetector(
                    onTap: () {
                      setState(() => _torchOn = !_torchOn);
                      _scannerCtrl.toggleTorch();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _torchOn
                            ? const Color(0xFFFBBF24).withOpacity(0.85)
                            : Colors.black45,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Instruction text ─────────────────────────────────
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Point the camera at the student\'s\nID card barcode',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Scan overlay with animated scan line ────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  final Animation<double> pulseAnim;
  const _ScanOverlay({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const cutoutSize = 260.0;
    final cutoutTop = (size.height - cutoutSize) / 2 - 40;

    return Stack(
      children: [
        // Dark areas around cutout
        CustomPaint(
          size: size,
          painter: _OverlayPainter(
            cutoutSize: cutoutSize,
            cutoutTop: cutoutTop,
          ),
        ),
        // Corner decorations + scan line
        Positioned(
          top: cutoutTop,
          left: (size.width - cutoutSize) / 2,
          child: SizedBox(
            width: cutoutSize,
            height: cutoutSize,
            child: Stack(
              children: [
                // Corner brackets
                ..._corners(),
                // Animated scan line
                AnimatedBuilder(
                  animation: pulseAnim,
                  builder: (_, __) => Positioned(
                    top: pulseAnim.value * (cutoutSize - 4),
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            const Color(0xFF2563EB).withOpacity(0.9),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static List<Widget> _corners() {
    const len = 30.0;
    const thick = 3.5;
    const radius = 6.0;
    const col = Color(0xFF60A5FA);

    return [
      // Top-left
      Positioned(
        top: 0,
        left: 0,
        child: _Corner(len: len, thick: thick, radius: radius, color: col,
            top: true, left: true),
      ),
      // Top-right
      Positioned(
        top: 0,
        right: 0,
        child: _Corner(len: len, thick: thick, radius: radius, color: col,
            top: true, left: false),
      ),
      // Bottom-left
      Positioned(
        bottom: 0,
        left: 0,
        child: _Corner(len: len, thick: thick, radius: radius, color: col,
            top: false, left: true),
      ),
      // Bottom-right
      Positioned(
        bottom: 0,
        right: 0,
        child: _Corner(len: len, thick: thick, radius: radius, color: col,
            top: false, left: false),
      ),
    ];
  }
}

class _Corner extends StatelessWidget {
  final double len, thick, radius;
  final Color color;
  final bool top, left;

  const _Corner({
    required this.len,
    required this.thick,
    required this.radius,
    required this.color,
    required this.top,
    required this.left,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: len,
      height: len,
      child: CustomPaint(
        painter: _CornerPainter(
          thick: thick,
          radius: radius,
          color: color,
          top: top,
          left: left,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final double thick, radius;
  final Color color;
  final bool top, left;

  _CornerPainter({
    required this.thick,
    required this.radius,
    required this.color,
    required this.top,
    required this.left,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thick
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    if (top && left) {
      canvas.drawLine(Offset(0, h), Offset(0, radius), paint);
      canvas.drawLine(Offset(radius, 0), Offset(w, 0), paint);
      canvas.drawArc(Rect.fromLTWH(0, 0, radius * 2, radius * 2),
          3.14159, -3.14159 / 2, false, paint);
    } else if (top && !left) {
      canvas.drawLine(Offset(w, h), Offset(w, radius), paint);
      canvas.drawLine(Offset(0, 0), Offset(w - radius, 0), paint);
      canvas.drawArc(Rect.fromLTWH(w - radius * 2, 0, radius * 2, radius * 2),
          3.14159 * 3 / 2, 3.14159 / 2, false, paint);
    } else if (!top && left) {
      canvas.drawLine(Offset(0, 0), Offset(0, h - radius), paint);
      canvas.drawLine(Offset(radius, h), Offset(w, h), paint);
      canvas.drawArc(Rect.fromLTWH(0, h - radius * 2, radius * 2, radius * 2),
          3.14159 / 2, 3.14159 / 2, false, paint);
    } else {
      canvas.drawLine(Offset(w, 0), Offset(w, h - radius), paint);
      canvas.drawLine(Offset(0, h), Offset(w - radius, h), paint);
      canvas.drawArc(
          Rect.fromLTWH(w - radius * 2, h - radius * 2, radius * 2, radius * 2),
          0,
          3.14159 / 2,
          false,
          paint);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}

class _OverlayPainter extends CustomPainter {
  final double cutoutSize, cutoutTop;
  _OverlayPainter({required this.cutoutSize, required this.cutoutTop});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.65);
    final cutoutLeft = (size.width - cutoutSize) / 2;
    final cutoutRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cutoutLeft, cutoutTop, cutoutSize, cutoutSize),
      const Radius.circular(16),
    );
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()
      ..addRect(fullRect)
      ..addRRect(cutoutRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => false;
}

// ─── Parsed student data ──────────────────────────────────────────────────────

class _ParsedStudent {
  final String id;
  final String name;
  final String raw;
  const _ParsedStudent({required this.id, required this.name, required this.raw});
}

// ─── Confirmation bottom sheet ────────────────────────────────────────────────

class _ConfirmationSheet extends StatelessWidget {
  final _ParsedStudent student;
  final VoidCallback onConfirm;
  final VoidCallback onRescan;

  const _ConfirmationSheet({
    required this.student,
    required this.onConfirm,
    required this.onRescan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Success icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.qr_code_scanner_rounded,
                color: Color(0xFF10B981), size: 32),
          ),
          const SizedBox(height: 12),
          const Text(
            'ID Card Scanned!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Please confirm the student details below.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),

          // Student info card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.badge_rounded,
                  label: 'Student ID',
                  value: student.id,
                  color: const Color(0xFF2563EB),
                ),
                const Divider(height: 20),
                _InfoRow(
                  icon: Icons.person_rounded,
                  label: 'Name',
                  value: student.name,
                  color: const Color(0xFF1A3C6E),
                ),
                if (student.name == 'Unknown Student') ...[
                  const Divider(height: 20),
                  _InfoRow(
                    icon: Icons.qr_code_rounded,
                    label: 'Barcode',
                    value: student.raw.length > 40
                        ? '${student.raw.substring(0, 40)}…'
                        : student.raw,
                    color: const Color(0xFF6B7280),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Rescan
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRescan,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Rescan'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: const Color(0xFF6B7280),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Confirm issue
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onConfirm,
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text('Confirm & Issue'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A3C6E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
