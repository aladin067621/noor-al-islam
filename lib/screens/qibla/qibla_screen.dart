import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
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

  double? _heading;
  bool _sensorAvailable = false;
  AccelerometerEvent? _accelerometer;
  MagnetometerEvent? _magnetometer;
  final List<StreamSubscription<dynamic>> _subs = [];

  static const double _makkahLat = 21.4225;
  static const double _makkahLon = 39.8262;

  @override
  void initState() {
    super.initState();
    _init();
    _watchSensors();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  void _watchSensors() {
    try {
      _subs.add(
        accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval)
            .listen((event) {
          if (!mounted) return;
          _accelerometer = event;
          _recomputeHeading();
        }, onError: (Object _) {
          if (mounted) setState(() => _sensorAvailable = false);
        }),
      );
      _subs.add(
        magnetometerEventStream(samplingPeriod: SensorInterval.uiInterval)
            .listen((event) {
          if (!mounted) return;
          _magnetometer = event;
          _recomputeHeading();
        }, onError: (Object _) {
          if (mounted) setState(() => _sensorAvailable = false);
        }),
      );
    } catch (_) {
      _sensorAvailable = false;
    }
  }

  void _recomputeHeading() {
    final a = _accelerometer;
    final m = _magnetometer;
    if (a == null || m == null || !mounted) return;

    final heading = _computeHeading(a, m);
    if (heading == null) return;
    setState(() {
      _heading = heading;
      _sensorAvailable = true;
    });
  }

  double? _computeHeading(AccelerometerEvent a, MagnetometerEvent m) {
    final normA = sqrt(a.x * a.x + a.y * a.y + a.z * a.z);
    final normM = sqrt(m.x * m.x + m.y * m.y + m.z * m.z);
    if (normA < 1e-9 || normM < 1e-9) return null;

    final ax = a.x / normA, ay = a.y / normA, az = a.z / normA;
    final mx = m.x / normM, my = m.y / normM, mz = m.z / normM;

    // H = A × M (الأرض: X)
    var hx = ay * mz - az * my;
    var hy = az * mx - ax * mz;
    var hz = ax * my - ay * mx;
    final normH = sqrt(hx * hx + hy * hy + hz * hz);
    if (normH < 1e-9) return null;
    hx /= normH;
    hy /= normH;
    hz /= normH;

    // M' = H × A (الأرض: Y)
    final my2 = hz * ax - hx * az;

    var heading = atan2(hy, my2) * 180 / pi;
    if (heading < 0) heading += 360;
    return heading;
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
        desiredAccuracy: LocationAccuracy.high,
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

  String _cardinal(double deg) {
    const names = ['شمال', 'شمال شرق', 'شرق', 'جنوب شرق', 'جنوب', 'جنوب غرب', 'غرب', 'شمال غرب'];
    return names[((deg + 22.5) % 360 / 45).floor()];
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
    final heading = _heading;
    final rotationAngle = heading != null ? -heading * pi / 180 : 0.0;
    final aligned = heading != null && (qiblaBearing - heading + 360) % 360 <= 3.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: rotationAngle,
                child: SizedBox(
                  width: 280,
                  height: 280,
                  child: CustomPaint(
                    painter: _CompassPainter(
                      qiblaBearing: qiblaBearing,
                      headingAvailable: heading != null,
                    ),
                  ),
                ),
              ),
              // مؤشر ثابت أعلى الشاشة يُمثّل مقدمة الهاتف
              CustomPaint(
                size: const Size(280, 280),
                painter: _ForwardMarkerPainter(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (heading != null)
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        aligned ? 'أنت متّجه نحو القبلة' : _cardinal(heading),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'اتجاه الجهاز: ${heading.toStringAsFixed(0)}°',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (!aligned) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'أدر هاتفك حتى يتطابق مؤشر القبلة الذهبي مع العلامة الثابتة أعلى البوصلة',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ],
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'انتظر حتى يستقر «المؤشر»… أبقِ الهاتف في وضع أفقي',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.gold.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'اتجاه القبلة: ${qiblaBearing.toStringAsFixed(1)}° — ${_cardinal(qiblaBearing)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'المسافة إلى مكة: ${distance.toStringAsFixed(0)} كم',
                  style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.gold.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.gold.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: AppTheme.gold),
                    SizedBox(width: 8),
                    Text('طريقة الاستخدام',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.gold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'أبقِ الهاتف في وضع أفقي وأدره حتى يتطابق المؤشر الذهبي (سهم القبلة) مع العلامة الثابتة أعلى البوصلة، '
                  'فعندها تكون وُجّهت نحو الكعبة المشرّفة.',
                  style: const TextStyle(height: 1.8, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'ملاحظة: قد تختلف دقة البوصلة بدرجات قليلة حسب الجهاز والمجال المغناطيسي المحيط.',
                  style: TextStyle(height: 1.6, fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final double qiblaBearing;
  final bool headingAvailable;

  _CompassPainter({required this.qiblaBearing, required this.headingAvailable});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    final bgPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF2A2A2E), Color(0xFF141416)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, bgPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFF55555C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, borderPaint);
    canvas.drawCircle(center, radius - 8, borderPaint..strokeWidth = 1);

    final tickPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;
    final minorTickPaint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 1;

    for (int i = 0; i < 360; i++) {
      final angle = (i - 90) * pi / 180;
      final isMajor = i % 30 == 0;
      final outerR = radius - 12;
      final innerR = isMajor ? radius - 26 : radius - 18;

      canvas.drawLine(
        Offset(center.dx + outerR * cos(angle), center.dy + outerR * sin(angle)),
        Offset(center.dx + innerR * cos(angle), center.dy + innerR * sin(angle)),
        isMajor ? tickPaint : minorTickPaint,
      );
    }

    final cardinals = {'N': 270, 'E': 0, 'S': 90, 'W': 180};
    cardinals.forEach((label, deg) {
      final angle = deg * pi / 180;
      final r = radius - 40;
      final tp = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: label == 'N' ? const Color(0xFFFF5252) : Colors.white70,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      )..layout();
      tp.paint(
        canvas,
        Offset(
          center.dx + r * cos(angle) - tp.width / 2,
          center.dy + r * sin(angle) - tp.height / 2,
        ),
      );
    });

    final qiblaAngle = (qiblaBearing - 90) * pi / 180;

    // سهم القبلة
    final arrowPaint = Paint()
      ..color = AppTheme.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final arrowStart = Offset(
      center.dx + 30 * cos(qiblaAngle),
      center.dy + 30 * sin(qiblaAngle),
    );
    final arrowEnd = Offset(
      center.dx + (radius - 46) * cos(qiblaAngle),
      center.dy + (radius - 46) * sin(qiblaAngle),
    );
    canvas.drawLine(arrowStart, arrowEnd, arrowPaint);

    // رأس السهم
    final tip1 = Offset(
      arrowEnd.dx + 9 * cos(qiblaAngle + pi * 0.75),
      arrowEnd.dy + 9 * sin(qiblaAngle + pi * 0.75),
    );
    final tip2 = Offset(
      arrowEnd.dx + 9 * cos(qiblaAngle - pi * 0.75),
      arrowEnd.dy + 9 * sin(qiblaAngle - pi * 0.75),
    );
    final tipPaint = Paint()
      ..color = AppTheme.gold
      ..style = PaintingStyle.fill;
    final tipPath = Path()
      ..moveTo(arrowEnd.dx, arrowEnd.dy)
      ..lineTo(tip1.dx, tip1.dy)
      ..lineTo(tip2.dx, tip2.dy)
      ..close();
    canvas.drawPath(tipPath, tipPaint);

    // نقطة في المنتصف
    canvas.drawCircle(center, 5, Paint()..color = Colors.white54);
    canvas.drawCircle(center, 2.5, Paint()..color = AppTheme.gold);
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) =>
      old.qiblaBearing != qiblaBearing || old.headingAvailable != headingAvailable;
}

class _ForwardMarkerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final top = 2.0;
    final path = Path()
      ..moveTo(cx, top)
      ..lineTo(cx - 10, top + 16)
      ..lineTo(cx + 10, top + 16)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx, top + 12), 3, Paint()..color = AppTheme.gold);
  }

  @override
  bool shouldRepaint(covariant _ForwardMarkerPainter old) => false;
}