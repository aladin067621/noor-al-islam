import 'package:flutter/material.dart';

import '../../services/quran_data_service.dart';
import '../../utils/theme.dart';
import '../../widgets/tajweed_text.dart' show colorFromHex;

/// قسم أحكام التجويد — شرح مبسط لقواعد التلاوة.
/// المحتوى من كتالوج ألوان التجويد (tajweed-rules.json) الخاص بـ Quran-Tajweed-Engine
/// مع تعليق عربي موثق (لا إضافة من خارج المصدر).
class TajweedRulesScreen extends StatefulWidget {
  const TajweedRulesScreen({super.key});

  @override
  State<TajweedRulesScreen> createState() => _TajweedRulesScreenState();
}

class _TajweedRulesScreenState extends State<TajweedRulesScreen> {
  Map<String, dynamic>? _catalog;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final catalog = await QuranDataService.instance.loadRulesCatalog();
      if (mounted) setState(() => _catalog = catalog);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  /// عنوان عربي معتمد للأقسام الأربعة في كتالوج محرك التجويد
  static String _sectionTitle(String id) {
    switch (id) {
      case 'silents':
        return 'السواكن والأحرف غير المنطوقة';
      case 'ghunnah':
        return 'الغنة وأحكام النون الساكنة والتنوين';
      case 'sifaat':
        return 'صفات الحروف والتفخيم';
      case 'madd':
        return 'أحكام المدود';
      default:
        return id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أحكام التجويد')),
      body: _error
          ? const Center(child: Text('تعذّر تحميل الأحكام'))
          : _catalog == null
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final sections = _catalog!['sections'] as List;
    final categories = _catalog!['categories'] as List;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // تمهيد قصير
        Card(
          color: AppTheme.gold.withOpacity(isDark ? 0.18 : 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.gold.withOpacity(isDark ? 0.5 : 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_stories, color: AppTheme.gold, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'هذه أحكام التجويد مقسّمة إلى أقسام، ولكل قسم حكمه ولونه في ألوان التجويد المعتمدة في هذا التطبيق. '
                    'يقصد بالألوان إبراز موضع الحكم في المصحف لتلاوة صحيحة بإذن الله.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.7,
                      color: isDark ? Colors.grey[300] : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final s in sections) ...[
          _sectionCard(s as Map<String, dynamic>, categories as List),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _sectionCard(Map<String, dynamic> section, List categories) {
    final sectionId = section['id'] as String;
    final sectionCategories = categories
        .where((c) => (c as Map<String, dynamic>)['section'] == sectionId)
        .toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                _sectionTitle(sectionId),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.lightGold : AppTheme.primaryGreen,
                ),
              ),
            ),
            for (final c in sectionCategories) _ruleTile(c as Map<String, dynamic>),
          ],
        ),
      ),
    );
  }

  Widget _ruleTile(Map<String, dynamic> rule) {
    final arabicTitle = rule['arabicTitle'] as String? ?? '';
    final transliteration = rule['transliteration'] as String? ?? '';
    final literalMeaning = rule['literalMeaning'] as String? ?? '';
    final longDesc = rule['longDescription'] as String? ?? '';
    final letters = rule['applicableLetters'] as String? ?? '';
    final colorHex = rule['colorHex'] as String? ?? '#888888';
    final color = colorFromHex(colorHex);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final header = Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            arabicTitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );

    final details = <Widget>[
      if (transliteration.isNotEmpty)
        Text(
          transliteration,
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      if (literalMeaning.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            literalMeaning,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              height: 1.5,
              color: isDark ? Colors.grey[200] : null,
            ),
          ),
        ),
      if (longDesc.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            longDesc,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ),
      if (letters.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'موضعه: $letters',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[200] : null,
              ),
            ),
          ),
        ),
    ];

    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(isDark ? 0.5 : 0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        // إبقاء سهم التوسيع في وضع التنقل حتى في النمط الغامق
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          title: header,
          children: details,
        ),
      ),
    );
  }
}