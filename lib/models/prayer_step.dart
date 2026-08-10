enum StepType { rukn, wajib, sunna, info }

StepType stepTypeFromString(String? s) {
  switch (s) {
    case 'rukn':
      return StepType.rukn;
    case 'wajib':
      return StepType.wajib;
    case 'sunna':
      return StepType.sunna;
    default:
      return StepType.info;
  }
}

String stepTypeLabel(StepType t) {
  switch (t) {
    case StepType.rukn:
      return 'ركن';
    case StepType.wajib:
      return 'واجب';
    case StepType.sunna:
      return 'سنة';
    case StepType.info:
      return '';
  }
}

/// خطوة من خطوات الصلاة أو حكم من أحكامها
class PrayerStep {
  final String id;
  final String title;
  final String description;
  final String dhikr;
  final int dhikrRepetitions;
  final String evidence;
  final String source;
  final StepType type;

  PrayerStep({
    required this.id,
    required this.title,
    required this.description,
    this.dhikr = '',
    this.dhikrRepetitions = 0,
    this.evidence = '',
    this.source = '',
    this.type = StepType.info,
  });

  factory PrayerStep.fromJson(Map<String, dynamic> json) {
    return PrayerStep(
      id: json['id']?.toString() ?? json['title'].hashCode.toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dhikr: json['dhikr'] ?? '',
      dhikrRepetitions: json['dhikrRepetitions'] ?? 0,
      evidence: json['evidence'] ?? '',
      source: json['source'] ?? '',
      type: stepTypeFromString(json['type']),
    );
  }
}

/// تبويب داخل قسم الصلاة (الطهارة / الأحكام / الكيفية)
class PrayerTab {
  final String title;
  final List<PrayerStep> steps;

  PrayerTab({required this.title, required this.steps});

  factory PrayerTab.fromJson(Map<String, dynamic> json) {
    return PrayerTab(
      title: json['title'] ?? '',
      steps: (json['steps'] as List? ?? [])
          .map((e) => PrayerStep.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
