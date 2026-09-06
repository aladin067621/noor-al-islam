import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
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
    {'name': 'القاهرة', 'lat': '30.0444', 'lon': '31.2357'},
    {'name': 'الإسكندرية', 'lat': '31.2001', 'lon': '29.9187'},
    {'name': 'دبي', 'lat': '25.2048', 'lon': '55.2708'},
    {'name': 'أبوظبي', 'lat': '24.4539', 'lon': '54.3773'},
    {'name': 'الدوحة', 'lat': '25.2854', 'lon': '51.5310'},
    {'name': 'المنامة', 'lat': '26.2285', 'lon': '50.5860'},
    {'name': 'الكويت العاصمة', 'lat': '29.3759', 'lon': '47.9774'},
    {'name': 'مسقط', 'lat': '23.5880', 'lon': '58.3829'},
    {'name': 'عمّان', 'lat': '31.9539', 'lon': '35.9106'},
    {'name': 'القدس', 'lat': '31.7683', 'lon': '35.2137'},
    {'name': 'بغداد', 'lat': '33.3128', 'lon': '44.3615'},
    {'name': 'دمشق', 'lat': '33.5138', 'lon': '36.2765'},
    {'name': 'إسطنبول', 'lat': '41.0082', 'lon': '28.9784'},
    {'name': 'لندن', 'lat': '51.5074', 'lon': '-0.1278'},
    {'name': 'باريس', 'lat': '48.8566', 'lon': '2.3522'},
    {'name': 'نيويورك', 'lat': '40.7128', 'lon': '-74.0060'},
    {'name': 'تورونتو', 'lat': '43.6532', 'lon': '-79.3832'},
    {'name': 'الدار البيضاء', 'lat': '33.5731', 'lon': '-7.5898'},
    {'name': 'تونس العاصمة', 'lat': '36.8065', 'lon': '10.1815'},
    {'name': 'الجزائر العاصمة', 'lat': '36.7538', 'lon': '3.0588'},
    {'name': 'الخرطوم', 'lat': '15.5007', 'lon': '32.5599'},
    {'name': 'كوالالمبور', 'lat': '3.1390', 'lon': '101.6869'},
    {'name': 'جاكرتا', 'lat': '-6.2088', 'lon': '106.8456'},
  ];

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