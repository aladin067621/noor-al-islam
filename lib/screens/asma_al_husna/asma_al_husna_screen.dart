import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/theme.dart';

/// نموذج اسمٍ من أسماء الله الحسنى (من asma_husna_entries.json)
class AsmaHusnaEntry {
  final String id;
  final String name;
  final String category;
  final String short;
  final String detailed;
  final String source;

  const AsmaHusnaEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.short,
    required this.detailed,
    required this.source,
  });

  factory AsmaHusnaEntry.fromJson(Map<String, dynamic> json) {
    return AsmaHusnaEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      short: json['short'] as String,
      detailed: json['detailed'] as String,
      source: json['source'] as String,
    );
  }
}

class AsmaAlHusnaScreen extends StatefulWidget {
  const AsmaAlHusnaScreen({super.key});

  @override
  State<AsmaAlHusnaScreen> createState() => _AsmaAlHusnaScreenState();
}

class _AsmaAlHusnaScreenState extends State<AsmaAlHusnaScreen> {
  static const String _assetPath =
      'assets/asma_al_husna/asma_husna_entries.json';

  static const String _hadith =
      'عن أبي هريرة رضي الله عنه قال: قال رسول الله ﷺ: '
      '«إن لله تسعةً وتسعين اسماً مائةً إلا واحداً، من أحصاها دخل الجنة»';
  static const String _hadithRef = 'رواه البخاري (2736) ومسلم (2677)';

  List<AsmaHusnaEntry>? _entries;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_entries != null || _error != null) {
      setState(() {
        _entries = null;
        _error = null;
      });
    }
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final data = json.decode(raw) as Map<String, dynamic>;
      final items = (data['entries'] as List)
          .map((e) => AsmaHusnaEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() => _entries = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'تعذر تحميل الأسماء: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أسماء الله الحسنى')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final error = _error;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.dangerRed),
              ),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      );
    }
    final entries = _entries;
    if (entries == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return _EntriesList(entries: entries);
  }
}

/// القائمة بتجميع الأسماء (كتاب الله / سنة النبي) مع عدّاد وفتح تفاصيل
class _EntriesList extends StatelessWidget {
  final List<AsmaHusnaEntry> entries;

  const _EntriesList({required this.entries});

  @override
  Widget build(BuildContext context) {
    final quran = entries.where((e) => e.category == 'من كتاب الله تعالى').toList();
    final sunnah = entries.where((e) => e.category == 'من سنة النبي ﷺ').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        const _HeaderCard(),
        const SizedBox(height: 12),
        _SectionHeader(title: 'من كتاب الله تعالى', count: quran.length),
        ...quran.map((e) => _NameTile(entry: e, index: entries.indexOf(e) + 1)),
        const SizedBox(height: 12),
        _SectionHeader(title: 'من سنة النبي ﷺ', count: sunnah.length),
        ...sunnah.map((e) => _NameTile(entry: e, index: entries.indexOf(e) + 1)),
      ],
    );
  }
}

/// بطاقة الحديث الافتتاحي
class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              AppTheme.primaryGreen.withOpacity(0.12),
              AppTheme.gold.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              _AsmaAlHusnaScreenState._hadith,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 16,
                height: 1.9,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.92)
                    : AppTheme.darkGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _AsmaAlHusnaScreenState._hadithRef,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة الاسم النصي في القائمة
class _NameTile extends StatelessWidget {
  final AsmaHusnaEntry entry;
  final int index;

  const _NameTile({required this.entry, required this.index});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () {
          HapticFeedback.lightImpact();
          _showDetails(context);
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: AppTheme.primaryGreen.withOpacity(0.12),
          child: Text(
            '$index',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
        ),
        title: Text(
          entry.name,
          style: TextStyle(
            fontFamily: AppTheme.quranFontFamily,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.lightGold
                : AppTheme.primaryGreen,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            entry.short,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, height: 1.6),
          ),
        ),
        trailing: const Icon(Icons.chevron_left, color: AppTheme.gold),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '$index · ${entry.category}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  entry.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.quranFontFamily,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.lightGold
                        : AppTheme.primaryGreen,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  entry.detailed,
                  textAlign: TextAlign.justify,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 16,
                    height: 1.9,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.menu_book, size: 18, color: AppTheme.gold),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.source,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.gold,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}