import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/constants.dart';
import '../../utils/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('عن التطبيق')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(
            child: Column(
              children: [
                Icon(Icons.mosque, size: 64, color: AppTheme.primaryGreen),
                SizedBox(height: 12),
                Text(AppConstants.appName,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(AppConstants.appTagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.gold)),
                SizedBox(height: 4),
                Text('الإصدار ${AppConstants.appVersion}',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('عن التطبيق',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'تطبيق إسلامي شامل يعتمد على القرآن الكريم والسنة النبوية وفهم السلف الصالح (أهل السنة والجماعة). يجمع الأذكار وأحكام الصلاة والتوحيد وأركان الإسلام والمكتبة الإسلامية وتفسير القرآن، مع روابط لمصادرها.',
            style: TextStyle(height: 1.9),
          ),
          const SizedBox(height: 20),
          const Text('المراجع والمصادر',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          FutureBuilder<String>(
            future: _loadReferences(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: SelectableText(
                    snapshot.data!,
                    style: const TextStyle(height: 1.8, fontSize: 14),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'نسأل الله الإخلاص والقبول',
              style: TextStyle(
                  fontFamily: AppTheme.quranFontFamily,
                  color: Colors.grey.shade600,
                  fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _loadReferences() async {
    return rootBundle.loadString(AppConstants.referencesPath);
  }
}
