import 'package:flutter/material.dart';
import '../../models/prayer_step.dart';
import '../../services/data_service.dart';
import '../../utils/theme.dart';

class PrayerScreen extends StatelessWidget {
  const PrayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PrayerTab>>(
      future: DataService.instance.loadPrayerTabs(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final tabs = snapshot.data!;
        return DefaultTabController(
          length: tabs.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('الصلاة'),
              bottom: TabBar(
                isScrollable: true,
                indicatorColor: AppTheme.gold,
                tabs: tabs.map((t) => Tab(text: t.title)).toList(),
              ),
            ),
            body: TabBarView(
              children: tabs.map((t) => _StepsList(steps: t.steps)).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _StepsList extends StatelessWidget {
  final List<PrayerStep> steps;
  const _StepsList({required this.steps});

  Color _typeColor(StepType t) {
    switch (t) {
      case StepType.rukn:
        return AppTheme.primaryGreen;
      case StepType.wajib:
        return AppTheme.gold;
      case StepType.sunna:
        return Colors.blueGrey;
      case StepType.info:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final s = steps[index];
        final label = stepTypeLabel(s.type);
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryGreen.withOpacity(0.15),
              child: Text('${index + 1}',
                  style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
            ),
            title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: label.isEmpty
                ? null
                : Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Chip(
                      label: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
                      backgroundColor: _typeColor(s.type),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              if (s.description.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(s.description, style: const TextStyle(height: 1.8)),
                ),
              if (s.dhikr.isNotEmpty || s.dhikrVariants.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      if (s.dhikr.isNotEmpty)
                        Text(
                          s.dhikr,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontFamily: AppTheme.quranFontFamily, fontSize: 18, height: 1.9),
                        ),
                      if (s.dhikrVariants.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        for (var i = 0; i < s.dhikrVariants.length; i++) ...[
                          if (s.dhikr.isNotEmpty && i == 0)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Divider(thickness: 1),
                            ),
                          Text(
                            s.dhikrVariants[i],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontFamily: AppTheme.quranFontFamily, fontSize: 18, height: 1.9),
                          ),
                          if (i != s.dhikrVariants.length - 1) const SizedBox(height: 10),
                        ],
                      ],
                      if (s.dhikrRepetitions > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('التكرار: ${s.dhikrRepetitions}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.gold)),
                        ),
                    ],
                  ),
                ),
              ],
              if (s.evidence.isNotEmpty) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('الدليل: ${s.evidence}',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.7)),
                ),
              ],
              if (s.source.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('المصدر: ${s.source}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
