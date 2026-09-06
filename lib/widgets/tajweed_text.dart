import 'package:flutter/material.dart';
import '../models/quran_models.dart';

/// تحويل لون سداسي إلى Color
Color colorFromHex(String hex) {
  var h = hex.replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  final v = int.tryParse(h, radix: 16) ?? 0xFF000000;
  return Color(v);
}

/// عرض آية قرآنية مع ألوان التجويد (بدون أي تعديل على النص)
class TajweedText extends StatelessWidget {
  final String text;
  final List<TajweedSpan> spans;
  final Map<String, String> ruleColors;
  final bool tajweedOn;
  final double fontSize;
  final String fontFamily;

  /// قاعدة مدّ الوقف لا تُلون افتراضيًا (كما في المحرك الأصلي)
  static const _skippedRules = {'maddSukoon'};

  const TajweedText({
    super.key,
    required this.text,
    required this.spans,
    required this.ruleColors,
    required this.tajweedOn,
    required this.fontSize,
    required this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = dark ? Colors.white : const Color(0xFF1A1A1A);
    final base = TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      height: 1.9,
      color: baseColor,
    );

    if (!tajweedOn || spans.isEmpty) {
      return Text(
        text,
        style: base,
        textDirection: TextDirection.rtl,
      );
    }

    final items = <_Range>[];
    for (final s in spans) {
      if (_skippedRules.contains(s.rule)) continue;
      if (s.start < 0 || s.end > text.length || s.end <= s.start) continue;
      final hex = ruleColors[s.rule];
      final c = hex != null ? colorFromHex(hex) : Colors.grey;
      items.add(_Range(s.start, s.end, c));
    }
    if (items.isEmpty) {
      return Text(
        text,
        style: base,
        textDirection: TextDirection.rtl,
      );
    }
    items.sort((a, b) => a.start != b.start ? a.start - b.start : a.end - b.end);

    final children = <InlineSpan>[];
    var cursor = 0;
    for (final r in items) {
      if (r.start > cursor) {
        children.add(TextSpan(text: text.substring(cursor, r.start)));
      }
      children.add(TextSpan(
        text: text.substring(r.start, r.end),
        style: TextStyle(color: r.color, fontWeight: FontWeight.w600),
      ));
      cursor = r.end > cursor ? r.end : cursor;
    }
    if (cursor < text.length) {
      children.add(TextSpan(text: text.substring(cursor)));
    }

    return Text.rich(
      TextSpan(style: base, children: children),
      textDirection: TextDirection.rtl,
    );
  }
}

class _Range {
  final int start;
  final int end;
  final Color color;
  const _Range(this.start, this.end, this.color);
}

/// تحويل أرقام غربية إلى أرقام عربية مشرقية (٠١٢٣…)
String toArabicDigits(Object? n) {
  const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  final buf = StringBuffer();
  for (final r in n.toString().runes) {
    if (r >= 0x30 && r <= 0x39) {
      buf.write(digits[r - 0x30]);
    } else {
      buf.write(String.fromCharCode(r));
    }
  }
  return buf.toString();
}