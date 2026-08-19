import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../utils/theme.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  Position? _position;
  bool _loading = true;
  String? _error;

  static const double _makkahLat = 21.4225;
  static const double _makkahLon = 39.8262;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() { _error = 'خدمة الموقع غير مفعّلة'; _loading = false; });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() { _error = 'الرجاء تفعيل صلاحية الموقع'; _loading = false; });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() { _error = 'صلاحية الموقع ممنوعة نهائياً'; _loading = false; });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      setState(() { _position = pos; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'فشل في تحديد الموقع'; _loading = false; });
    }
  }

  double _calculateQiblaBearing() {
    if (_position == null) return 0;
    final lat1 = _position!.latitude * pi / 180;
    final lon1 = _position!.longitude * pi / 180;
    final lat2 = _makkahLat * pi / 180;
    final lon2 = _makkahLon * pi / 180;

    final dLon = lon2 - lon1;
    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    final bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360;
  }

  double _distanceToMakkah() {
    if (_position == null) return 0;
    const R = 6371.0;
    final dLat = (_makkahLat - _position!.latitude) * pi / 180;
    final dLon = (_makkahLon - _position!.longitude) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_position!.latitude * pi / 180) * cos(_makkahLat * pi / 180) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اتجاه القبلة')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildCompass(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => setState(() { _loading = true; _error = null; _init(); }),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompass() {
    final qiblaBearing = _calculateQiblaBearing();
    final distance = _distanceToMakkah();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 260,
            height: 260,
            child: CustomPaint(
              painter: _CompassPainter(qiblaBearing: qiblaBearing),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${qiblaBearing.toStringAsFixed(1)}°',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'المسافة: ${distance.toStringAsFixed(0)} كم',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'اتجاه القبلة من موقعك الحالي',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final double qiblaBearing;

  _CompassPainter({required this.qiblaBearing});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    final bgPaint = Paint()
      ..color = AppTheme.primaryGreen.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    final borderPaint = Paint()
      ..color = AppTheme.primaryGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, borderPaint);

    final tickPaint = Paint()
      ..color = AppTheme.primaryGreen
      ..strokeWidth = 2;
    final minorTickPaint = Paint()
      ..color = AppTheme.primaryGreen.withOpacity(0.4)
      ..strokeWidth = 1;

    for (int i = 0; i < 360; i++) {
      final angle = (i - 90) * pi / 180;
      final isMajor = i % 30 == 0;
      final outerR = radius - 4;
      final innerR = isMajor ? radius - 20 : radius - 12;

      canvas.drawLine(
        Offset(center.dx + outerR * cos(angle), center.dy + outerR * sin(angle)),
        Offset(center.dx + innerR * cos(angle), center.dy + innerR * sin(angle)),
        isMajor ? tickPaint : minorTickPaint,
      );
    }

    final cardinals = {'N': 270, 'E': 0, 'S': 90, 'W': 180};
    final cardinalPaint = TextPainter(textDirection: TextDirection.ltr);
    cardinals.forEach((label, deg) {
      final angle = deg * pi / 180;
      final r = radius - 30;
      cardinalPaint.text = TextSpan(
        text: label,
        style: TextStyle(
          color: label == 'N' ? Colors.red : AppTheme.primaryGreen,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
      cardinalPaint.layout();
      cardinalPaint.paint(
        canvas,
        Offset(
          center.dx + r * cos(angle) - cardinalPaint.width / 2,
          center.dy + r * sin(angle) - cardinalPaint.height / 2,
        ),
      );
    });

    final qiblaAngle = (qiblaBearing - 90) * pi / 180;
    final kaabaPaint = Paint()
      ..color = const Color(0xFF2E7D5B)
      ..style = PaintingStyle.fill;

    final kaabaR = radius - 55;
    final kaabaCenter = Offset(
      center.dx + kaabaR * cos(qiblaAngle),
      center.dy + kaabaR * sin(qiblaAngle),
    );
    canvas.drawRect(
      Rect.fromCenter(center: kaabaCenter, width: 18, height: 18),
      kaabaPaint,
    );

    final arrowPaint = Paint()
      ..color = AppTheme.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final arrowStart = Offset(
      center.dx + 25 * cos(qiblaAngle),
      center.dy + 25 * sin(qiblaAngle),
    );
    final arrowEnd = Offset(
      center.dx + (radius - 70) * cos(qiblaAngle),
      center.dy + (radius - 70) * sin(qiblaAngle),
    );
    canvas.drawLine(arrowStart, arrowEnd, arrowPaint);

    final tipPaint = Paint()
      ..color = AppTheme.gold
      ..style = PaintingStyle.fill;
    canvas.drawCircle(arrowEnd, 5, tipPaint);
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) =>
      old.qiblaBearing != qiblaBearing;
}
