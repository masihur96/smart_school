import 'dart:developer';
import 'package:dio/dio.dart';

class GeocodingService {
  static final GeocodingService _instance = GeocodingService._internal();
  factory GeocodingService() => _instance;
  GeocodingService._internal();

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  // In-memory cache: "lat,lon" → place name
  final Map<String, String> _cache = {};

  /// Returns a human-readable place name for the given coordinates.
  /// Falls back to "lat, lon" if lookup fails.
  Future<String> getPlaceName(String lat, String lon) async {
    final key = '$lat,$lon';
    if (_cache.containsKey(key)) return _cache[key]!;

    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'json',
          'lat': lat,
          'lon': lon,
          'zoom': 14,          // neighbourhood level
          'addressdetails': 1,
        },
        options: Options(headers: {
          'User-Agent': 'SmartSchoolApp/1.0',
          'Accept-Language': 'en',
        }),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        final address = data['address'] as Map?;
        final suburb = address?['suburb'] ??
            address?['neighbourhood'] ??
            address?['town'] ??
            address?['village'] ??
            address?['city_district'] ??
            address?['county'] ??
            '';
        final city = address?['city'] ??
            address?['district'] ??
            address?['state_district'] ??
            '';
        String name = [suburb, city]
            .where((s) => s.toString().isNotEmpty)
            .join(', ');
        if (name.isEmpty) name = data['display_name']?.toString().split(',').first ?? key;
        _cache[key] = name;
        return name;
      }
    } catch (e) {
      log('Geocoding error for $key: $e');
    }

    // Fallback
    final fallback =
        '${double.tryParse(lat)?.toStringAsFixed(3) ?? lat}, ${double.tryParse(lon)?.toStringAsFixed(3) ?? lon}';
    _cache[key] = fallback;
    return fallback;
  }
}
