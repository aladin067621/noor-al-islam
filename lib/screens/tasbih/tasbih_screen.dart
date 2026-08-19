import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/theme.dart';

class _DhikrOption {
  final String arabic;
  final String transliteration;
  final int target;

  const _DhikrOption(this.arabic, this.transliteration, this.target);
}

const _dhikrOptions = [
  _DhikrOption('سبحان الله', 'Subhan Allah', 33),
  _DhikrOption('الحمد لله', 'Alhamdulillah', 33),
  _DhikrOption('الله أكبر', 'Allahu Akbar', 33),
  _DhikrOption('لا إله إلا الله', 'La ilaha illAllah', 100),
  _DhikrOption('أستغفر الله', 'Astaghfirullah', 100),
  _DhikrOption('سبحان الله وبحمده', 'SubhanAllah wa bihamdihi', 100),
  _DhikrOption('سبحان الله العظيم', 'SubhanAllah al-Adheem', 100),
  _DhikrOption('لا حول ولا قوة إلا بالله', 'La hawla wa la quwwata illa billah', 100),
];

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  int _count = 0;
  int _totalRounds = 0;
  bool _customMode = false;
  final _customController = TextEditingController();
  int _customTarget = 33;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _customController.dispose();
    super.dispose();
  }

  int get _target =>
      _customMode ? _customTarget : _dhikrOptions[_selectedIndex].target;

  String get _currentDhikr =>
      _customMode
          ? (_customController.text.isEmpty ? '...تنقيط' : _customController.text)
          : _dhikrOptions[_selectedIndex].arabic;

  double get _progress => _target > 0 ? (_count % _target) / _target : 0.0;

  void _increment() {
    HapticFeedback.lightImpact();
    _pulseController.forward(from: 0.0);
    setState(() {
      _count++;
      if (_count % _target == 0) {
        _totalRounds++;
      }
    });
  }

  void _reset() {
    setState(() {
      _count = 0;
      _totalRounds = 0;
    });
  }

  void _selectDhikr(int index) {
    setState(() {
      _selectedIndex = index;
      _customMode = false;
      _count = 0;
      _totalRounds = 0;
    });
  }

  void _enableCustom() {
    setState(() {
      _customMode = true;
      _count = 0;
      _totalRounds = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('السبحة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'إعادة',
            onPressed: _reset,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildDhikrDisplay(),
                  const SizedBox(height: 16),
                  _buildCounterRing(),
                  const SizedBox(height: 24),
                  _buildCountInfo(),
                  const SizedBox(height: 30),
                  _buildTargetSelector(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDhikrDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            _currentDhikr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.quranFontFamily,
              fontSize: _currentDhikr.length > 30 ? 22 : 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
              height: 1.6,
            ),
          ),
          if (!_customMode) ...[
            const SizedBox(height: 6),
            Text(
              _dhikrOptions[_selectedIndex].transliteration,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCounterRing() {
    return GestureDetector(
      onTap: _increment,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          );
        },
        child: CustomPaint(
          size: const Size(220, 220),
          painter: _RingPainter(
            progress: _progress,
            color: AppTheme.primaryGreen,
            backgroundColor: AppTheme.primaryGreen.withOpacity(0.12),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_count % _target}',
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                Text(
                  'من $_target',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _infoChip(Icons.fiber_manual_record, 'العدّ الكلي', '$_count'),
        const SizedBox(width: 16),
        _infoChip(Icons.repeat, 'الدورات', '$_totalRounds'),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppTheme.gold),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('اختر الذكر',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _dhikrOptions.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == _dhikrOptions.length) {
                return _buildCustomChip();
              }
              final opt = _dhikrOptions[index];
              final selected = !_customMode && _selectedIndex == index;
              return GestureDetector(
                onTap: () => _selectDhikr(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primaryGreen
                        : AppTheme.primaryGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(
                      color: selected
                          ? AppTheme.primaryGreen
                          : AppTheme.primaryGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    opt.arabic,
                    style: TextStyle(
                      color: selected ? Colors.white : AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_customMode) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'اكتب الذكر...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  style: const TextStyle(fontFamily: AppTheme.quranFontFamily),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 90,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'الهدف',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                  onChanged: (v) {
                    final n = int.tryParse(v);
                    if (n != null && n > 0) {
                      setState(() => _customTarget = n);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCustomChip() {
    final selected = _customMode;
    return GestureDetector(
      onTap: _enableCustom,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.gold : AppTheme.gold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: selected ? AppTheme.gold : AppTheme.gold.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit, size: 16, color: selected ? Colors.white : AppTheme.gold),
            const SizedBox(width: 6),
            Text(
              'ذكر مخصص',
              style: TextStyle(
                color: selected ? Colors.white : AppTheme.gold,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}
