import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

/// موقع محفوظ: إحداثيات + اسم مدينة (اختياري) + مصدر (GPS أو يدوي)
class SavedLocation {
  final double latitude;
  final double longitude;
  final String city;
  final String source; // gps | manual

  const SavedLocation({
    required this.latitude,
    required this.longitude,
    this.city = '',
    this.source = 'gps',
  });

  /// اسم يُعرض للمستخدم في المواقيت والقبلة
  String get label => city.isNotEmpty ? city : '${latitude.toStringAsFixed(2)}°، ${longitude.toStringAsFixed(2)}°';
}

/// خدمة الموقع المحفوظ — توفّر الموقع فورًا دون طلب إذن في كل مرة،
/// مع إمكانية الاختيار اليدوي لمدينة (إحداثيات ثابتة لا تحتاج إنترنت).
class LocationService extends ChangeNotifier {
  LocationService._();

  static final LocationService instance = LocationService._();

  SavedLocation? _saved;
  SavedLocation? get saved => _saved;

  bool _loaded = false;

  /// مدن رئيسية بإحداثيات ثابتة للاختيار اليدوي (تعمل دون إنترنت)
  static const List<Map<String, String>> presetCities = [
    {'name': 'مكة المكرمة', 'lat': '21.4225', 'lon': '39.8262'},
    {'name': 'المدينة المنورة', 'lat': '24.4672', 'lon': '39.6111'},
    {'name': 'الرياض', 'lat': '24.7136', 'lon': '46.6753'},
    {'name': 'جدة', 'lat': '21.4858', 'lon': '39.1925'},
    {'name': 'الدمام', 'lat': '26.4207', 'lon': '50.0888'},
    {'name': 'الطائف', 'lat': '21.2703', 'lon': '40.4158'},
    {'name': 'تبوك', 'lat': '28.3838', 'lon': '36.5550'},
    {'name': 'خميس مشيط', 'lat': '18.3044', 'lon': '42.7273'},
    {'name': 'بريدة', 'lat': '26.3260', 'lon': '43.9750'},
    {'name': 'القاهرة', 'lat': '30.0444', 'lon': '31.2357'},
    {'name': 'الإسكندرية', 'lat': '31.2001', 'lon': '29.9187'},
    {'name': 'الجيزة', 'lat': '30.0131', 'lon': '31.2089'},
    {'name': 'المنصورة', 'lat': '31.0409', 'lon': '31.3785'},
    {'name': 'طنطا', 'lat': '30.7885', 'lon': '31.0019'},
    {'name': 'أسيوط', 'lat': '27.1809', 'lon': '31.1837'},
    {'name': 'دبي', 'lat': '25.2048', 'lon': '55.2708'},
    {'name': 'أبوظبي', 'lat': '24.4539', 'lon': '54.3773'},
    {'name': 'الشارقة', 'lat': '25.3463', 'lon': '55.4209'},
    {'name': 'العين', 'lat': '24.1302', 'lon': '55.8023'},
    {'name': 'الدوحة', 'lat': '25.2854', 'lon': '51.5310'},
    {'name': 'المنامة', 'lat': '26.2285', 'lon': '50.5860'},
    {'name': 'الكويت العاصمة', 'lat': '29.3759', 'lon': '47.9774'},
    {'name': 'مسقط', 'lat': '23.5880', 'lon': '58.3829'},
    {'name': 'عمّان', 'lat': '31.9539', 'lon': '35.9106'},
    {'name': 'الزرقاء', 'lat': '32.0831', 'lon': '36.0878'},
    {'name': 'إربد', 'lat': '32.5556', 'lon': '35.8501'},
    {'name': 'القدس', 'lat': '31.7683', 'lon': '35.2137'},
    {'name': 'بغداد', 'lat': '33.3128', 'lon': '44.3615'},
    {'name': 'البصرة', 'lat': '30.5080', 'lon': '47.7805'},
    {'name': 'الموصل', 'lat': '36.3350', 'lon': '43.1189'},
    {'name': 'دمشق', 'lat': '33.5138', 'lon': '36.2765'},
    {'name': 'حلب', 'lat': '36.2021', 'lon': '37.1343'},
    {'name': 'حمص', 'lat': '34.7308', 'lon': '36.7233'},
    {'name': 'إسطنبول', 'lat': '41.0082', 'lon': '28.9784'},
    {'name': 'أنقرة', 'lat': '39.9334', 'lon': '32.8597'},
    {'name': 'إزمير', 'lat': '38.4237', 'lon': '27.1428'},
    {'name': 'طرابلس', 'lat': '32.8872', 'lon': '13.1913'},
    {'name': 'بنغازي', 'lat': '32.1167', 'lon': '20.0667'},
    {'name': 'الدار البيضاء', 'lat': '33.5731', 'lon': '-7.5898'},
    {'name': 'الرباط', 'lat': '34.0209', 'lon': '-6.8416'},
    {'name': 'فاس', 'lat': '34.0331', 'lon': '-5.0003'},
    {'name': 'مراكش', 'lat': '31.6346', 'lon': '-8.0779'},
    {'name': 'تونس العاصمة', 'lat': '36.8065', 'lon': '10.1815'},
    {'name': 'سوسة', 'lat': '35.8256', 'lon': '10.6064'},
    {'name': 'الجزائر العاصمة', 'lat': '36.7538', 'lon': '3.0588'},
    {'name': 'وهران', 'lat': '35.6987', 'lon': '-0.6333'},
    {'name': 'قسنطينة', 'lat': '36.3637', 'lon': '6.6116'},
    {'name': 'الخرطوم', 'lat': '15.5007', 'lon': '32.5599'},
    {'name': 'أم درمان', 'lat': '15.6445', 'lon': '32.4773'},
    {'name': 'كوالالمبور', 'lat': '3.1390', 'lon': '101.6869'},
    {'name': 'جاكرتا', 'lat': '-6.2088', 'lon': '106.8456'},
    {'name': 'لندن', 'lat': '51.5074', 'lon': '-0.1278'},
    {'name': 'باريس', 'lat': '48.8566', 'lon': '2.3522'},
    {'name': 'نيويورك', 'lat': '40.7128', 'lon': '-74.0060'},
    {'name': 'تورونتو', 'lat': '43.6532', 'lon': '-79.3832'},
  ];

  /// البحث عن مدينة على الإنترنت (آخر عدد من النتائج).
  Future<List<Map<String, String>>> searchCities(String query) async {
    final results = <Map<String, String>>[];
    if (query.trim().isEmpty) return results;
    final url = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeQueryComponent(query)}&count=20&language=ar&format=json');
    try {
      final resp = await http
          .get(url, headers: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36',
          })
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) return results;
      final data = json.decode(resp.body) as Map<String, dynamic>;
      final list = data['results'] as List? ?? [];
      for (final r in list) {
        final m = r as Map<String, dynamic>;
        final name = (m['name'] as String? ?? '').trim();
        final lat = m['latitude'];
        final lon = m['longitude'];
        final country = m['country'] as String? ?? '';
        final admin = m['admin1'] as String? ?? '';
        if (name.isEmpty || lat is! num || lon is! num) continue;
        final label = country.isNotEmpty
            ? '$name — $country'
            : name;
        results.add({
          'name': name,
          'label': label,
          'lat': lat.toString(),
          'lon': lon.toString(),
          'sub': admin,
        });
      }
    } catch (_) {}
    return results;
  }

  /// تحميل الموقع المحفوظ إن وُجد
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(AppConstants.keyLocationLat);
    final lon = prefs.getDouble(AppConstants.keyLocationLon);
    if (lat == null || lon == null) return;
    _saved = SavedLocation(
      latitude: lat,
      longitude: lon,
      city: prefs.getString(AppConstants.keyLocationCity) ?? '',
      source: prefs.getString(AppConstants.keyLocationSource) ?? 'gps',
    );
    notifyListeners();
  }

  Future<void> saveGps(double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.keyLocationLat, lat);
    await prefs.setDouble(AppConstants.keyLocationLon, lon);
    await prefs.setString(AppConstants.keyLocationCity, '');
    await prefs.setString(AppConstants.keyLocationSource, 'gps');
    _saved = SavedLocation(latitude: lat, longitude: lon);
    notifyListeners();
  }

  Future<void> saveManual(double lat, double lon, String cityName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.keyLocationLat, lat);
    await prefs.setDouble(AppConstants.keyLocationLon, lon);
    await prefs.setString(AppConstants.keyLocationCity, cityName);
    await prefs.setString(AppConstants.keyLocationSource, 'manual');
    _saved = SavedLocation(
        latitude: lat, longitude: lon, city: cityName, source: 'manual');
    notifyListeners();
  }

  /// التحديث من GPS — يُرجع نص خطأ إن فشل، وإلا null
  Future<String?> refreshFromGps() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return 'خدمة الموقع غير مفعّلة';
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return 'الرجاء تفعيل صلاحية الموقع';
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return 'صلاحية الموقع ممنوعة نهائياً — فعّلها من إعدادات الجهاز';
      }
      Position pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 15));
      } on TimeoutException {
        final last = await Geolocator.getLastKnownPosition();
        if (last == null) {
          return 'تعذّر تحديد موقعك — تأكد من تفعيل خدمة الموقع ثم أعد المحاولة';
        }
        pos = last;
      }
      await saveGps(pos.latitude, pos.longitude);
      return null;
    } catch (_) {
      return 'فشل في تحديد الموقع';
    }
  }
}