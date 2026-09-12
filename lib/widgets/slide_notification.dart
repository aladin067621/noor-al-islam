import 'dart:async';
import 'package:flutter/material.dart';

import '../utils/theme.dart';

/// إشعار حديث ينزلق من حافة الشاشة اليمنى (كالتنبيهات في التطبيقات الحديثة)
/// يعمل فوق التطبيق كله عبر Overlay، ويختفي تلقائيًا بعد مدة قابلة للتخصيص.
class SlideNotification {
  static OverlayEntry? _current;

  /// عرض إشعار ينزلق من الجانب.
  ///
  /// [title] عنوان قصير، [message] نص الإشعار، [icon] أيقونة اختيارية،
  /// [color] لون الشريط الجانبي (افتراضيًا الأخضر الأساسي)، [duration] مدة الظهور.
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    IconData? icon,
    Color? color,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    // إغلاق أي إشعار سابق قبل عرض الجديد
    _current?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _SlideNotificationBanner(
        title: title,
        message: message,
        icon: icon ?? Icons.notifications_active_outlined,
        color: color ?? AppTheme.primaryGreen,
        duration: duration,
        onDone: () => _remove(entry),
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }

  static void _remove(OverlayEntry entry) {
    if (entry.mounted) {
      entry.remove();
    }
    if (identical(_current, entry)) {
      _current = null;
    }
  }
}

class _SlideNotificationBanner extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final Duration duration;
  final VoidCallback onDone;

  const _SlideNotificationBanner({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.duration,
    required this.onDone,
  });

  @override
  State<_SlideNotificationBanner> createState() =>
      _SlideNotificationBannerState();
}

class _SlideNotificationBannerState extends State<_SlideNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _controller.forward();
    Timer(widget.duration, () {
      if (mounted) _controller.reverse();
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) widget.onDone();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // انزلاق من اليمين مع تلاشٍ خفيف
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_controller.value);
        return Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12 + (1 - t) * 60,
          right: 12,
          child: IgnorePointer(
            ignoring: false,
            child: Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: _banner(),
            ),
          ),
        );
      },
    );
  }

  Widget _banner() {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF15201C)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // شريط لون جانبي يمين
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: Container(
                width: 5,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 14),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 22),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.message,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.85)
                                : Colors.black.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (mounted) _controller.reverse();
                  },
                  icon: const Icon(Icons.close, size: 18),
                  color: Colors.grey,
                  padding: const EdgeInsets.all(8),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }
}