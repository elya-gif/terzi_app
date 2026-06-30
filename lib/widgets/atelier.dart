import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// İmza öğesi: el dikişi (running stitch) motifi ve atölye yardımcıları.

/// Yatay dikiş çizgisi — düz Divider yerine kullanılır.
class StitchDivider extends StatelessWidget {
  const StitchDivider({super.key, this.color, this.dash = 7, this.gap = 5});

  final Color? color;
  final double dash;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final c = color ??
        Theme.of(context).extension<AtelierColors>()!.stitch;
    return SizedBox(
      height: 1.5,
      child: CustomPaint(
        painter: _StitchPainter(color: c, dash: dash, gap: gap),
        size: const Size(double.infinity, 1.5),
      ),
    );
  }
}

class _StitchPainter extends CustomPainter {
  _StitchPainter({required this.color, required this.dash, required this.gap});

  final Color color;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + dash, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_StitchPainter old) =>
      old.color != color || old.dash != dash || old.gap != gap;
}

/// Dikey dikiş şeridi — kart sol kenarında durum/renk vurgusu.
class SeamAccent extends StatelessWidget {
  const SeamAccent({super.key, required this.color, this.height});

  final Color color;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 3,
      height: height,
      child: CustomPaint(
        painter: _VerticalStitchPainter(color: color),
      ),
    );
  }
}

class _VerticalStitchPainter extends CustomPainter {
  _VerticalStitchPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const dash = 6.0;
    const gap = 4.0;
    final x = size.width / 2;
    double y = 0;
    while (y < size.height) {
      final end = (y + dash).clamp(0.0, size.height);
      canvas.drawLine(Offset(x, y), Offset(x, end), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_VerticalStitchPainter old) => old.color != color;
}

/// Bölüm başlığı — küçük etiket + dikiş çizgisi.
class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.label,
    this.icon,
    this.color,
  });

  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final atelier = Theme.of(context).extension<AtelierColors>()!;
    final c = color ?? atelier.brass;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: c),
            const SizedBox(width: 7),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: c,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: StitchDivider(color: c.withValues(alpha: 0.45))),
        ],
      ),
    );
  }
}

/// Dikiş halkalı monogram avatarı.
class MonogramAvatar extends StatelessWidget {
  const MonogramAvatar({
    super.key,
    required this.name,
    this.size = 46,
    this.color,
    this.background,
  });

  final String name;
  final double size;
  final Color? color;
  final Color? background;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.isNotEmpty && parts[0].isNotEmpty
        ? parts[0][0].toUpperCase()
        : '?';
  }

  @override
  Widget build(BuildContext context) {
    final atelier = Theme.of(context).extension<AtelierColors>()!;
    final fg = color ?? atelier.brass;
    final bg = background ?? atelier.brassSoft;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: fg.withValues(alpha: 0.35), width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}
