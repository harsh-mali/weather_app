import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  static const String apiKey = 'dbaaa2c5f5b18989ccc9a936dc5c0d0b'; // Replace with your API key
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5';
  
  final Map<String, CachedWeather> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 30);

  Future<Map<String, List<WeatherData>>> getWeatherForecast(String city) async {
    // Check cache first
    if (_cache.containsKey(city)) {
      final cached = _cache[city]!;
      if (DateTime.now().difference(cached.timestamp) < _cacheDuration) {
        return cached.data;
      }
      _cache.remove(city);
    }

    final response = await http.get(
      Uri.parse('$baseUrl/forecast?q=$city&units=metric&appid=$apiKey'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final result = _processWeatherData(data);
      
      // Cache the result
      _cache[city] = CachedWeather(
        data: result,
        timestamp: DateTime.now(),
      );
      
      return result;
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  Map<String, List<WeatherData>> _processWeatherData(Map<String, dynamic> data) {
    final List<WeatherData> hourlyForecast = [];
    final List<WeatherData> dailyForecast = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetHours = [0, 3, 6, 9, 12, 15, 18, 21];
    final Map<String, dynamic> dailyData = {};

    for (var item in data['list']) {
      final date = DateTime.parse(item['dt_txt']);
      final hour = date.hour;
      
      if (date.day == today.day && targetHours.contains(hour)) {
        hourlyForecast.add(WeatherData.fromJson(item));
      }
      
      String dateKey = date.toString().split(' ')[0];
      if (!dailyData.containsKey(dateKey)) {
        dailyData[dateKey] = item;
        dailyForecast.add(WeatherData.fromJson(item));
      }
    }

    return {
      'hourly': hourlyForecast,
      'daily': dailyForecast.take(7).toList(),
    };
  }
}

class CachedWeather {
  final Map<String, List<WeatherData>> data;
  final DateTime timestamp;

  CachedWeather({required this.data, required this.timestamp});
} 