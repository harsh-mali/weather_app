import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _cityKey = 'selected_city';
  static const String _savedCitiesKey = 'saved_cities';
  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> saveCity(String city) async {
    final preferences = await prefs;
    await preferences.setString(_cityKey, city);
    
    // Save to saved cities list
    final savedCities = await getSavedCities();
    if (!savedCities.contains(city)) {
      savedCities.add(city);
      await preferences.setStringList(_savedCitiesKey, savedCities);
    }
  }

  Future<String?> getSavedCity() async {
    final preferences = await prefs;
    return preferences.getString(_cityKey);
  }

  Future<List<String>> getSavedCities() async {
    final preferences = await prefs;
    return preferences.getStringList(_savedCitiesKey) ?? [];
  }

  Future<void> removeCity(String city) async {
    final preferences = await prefs;
    final savedCities = await getSavedCities();
    savedCities.remove(city);
    await preferences.setStringList(_savedCitiesKey, savedCities);
  }
} 