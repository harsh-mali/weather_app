import 'package:flutter/material.dart';
import 'models/weather_model.dart';
import 'services/weather_service.dart';
import 'package:intl/intl.dart';
import 'screens/weather_detail_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/animated_background.dart';
import 'services/location_service.dart';
import 'services/preferences_service.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFB74D), // Orange accent for buttons
          background: Colors.black,
          surface: Color(0xFF1E1E1E),
          secondary: Colors.white,
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> with SingleTickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();
  final PreferencesService _preferencesService = PreferencesService();
  List<WeatherData> _hourlyForecast = [];
  List<WeatherData> _dailyForecast = [];
  bool _isLoading = true;
  String _selectedCity = 'Loading...';
  late AnimationController _controller;
  late Animation<double> _animation;
  final Map<String, Image> _cachedImages = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _loadSavedCity();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCity() async {
    final savedCity = await _preferencesService.getSavedCity();
    if (savedCity != null) {
      setState(() {
        _selectedCity = savedCity;
      });
      await _loadWeatherData();
    } else {
      _showCityInputDialog();
    }
  }

  Future<void> _showCityInputDialog() async {
    final TextEditingController controller = TextEditingController();
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter Your City'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g., London'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final city = controller.text.trim();
              if (city.isNotEmpty) {
                await _preferencesService.saveCity(city);
                if (mounted) {
                  setState(() {
                    _selectedCity = city;
                  });
                  Navigator.of(context).pop();
                  await _loadWeatherData();
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadWeatherData() async {
    setState(() => _isLoading = true);
    try {
      final forecast = await _weatherService.getWeatherForecast(_selectedCity);
      setState(() {
        _hourlyForecast = forecast['hourly'] ?? [];
        _dailyForecast = forecast['daily'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading weather data: $e')),
        );
      }
    }
  }

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          16.0,
          16.0,
          16.0,
          MediaQuery.of(context).viewInsets.bottom + 16.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select City',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter city name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (value) async {
                if (value.isNotEmpty) {
                  await _preferencesService.saveCity(value);
                  if (mounted) {
                    setState(() => _selectedCity = value);
                    _loadWeatherData();
                    Navigator.pop(context);
                  }
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FutureBuilder<List<String>>(
        future: _preferencesService.getSavedCities(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final cities = snapshot.data!;
          
          return ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Saved Cities',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              ...cities.map((city) => ListTile(
                title: Text(city),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    await _preferencesService.removeCity(city);
                    Navigator.pop(context);
                    _showMenu(); // Refresh the menu
                  },
                ),
                onTap: () {
                  setState(() => _selectedCity = city);
                  _loadWeatherData();
                  Navigator.pop(context);
                },
              )),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Licenses'),
                onTap: () {
                  Navigator.pop(context);
                  showLicensePage(
                    context: context,
                    applicationName: 'Weather App',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2024 Your Name',
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddCityDialog() async {
    final TextEditingController controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New City'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter city name',
            prefixIcon: Icon(Icons.location_city),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final city = controller.text.trim();
              if (city.isNotEmpty) {
                await _preferencesService.saveCity(city);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$city added to saved cities')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        weatherCondition: _hourlyForecast.isNotEmpty 
          ? _hourlyForecast.first.condition 
          : 'clear',
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadWeatherData,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      expandedHeight: MediaQuery.of(context).size.height * 0.7,
                      floating: false,
                      pinned: true,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.search, color: Colors.white),
                          onPressed: _showCityPicker,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: () => _showAddCityDialog(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: _showMenu,
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Weather info
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _selectedCity,
                                        style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w300,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_hourlyForecast.first.temperature.round()}°',
                                    style: const TextStyle(
                                      fontSize: 96,
                                      fontWeight: FontWeight.w200,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    _hourlyForecast.first.condition,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w300,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildWeatherDetail(
                                          Icons.thermostat_outlined,
                                          'Feels like',
                                          '${_hourlyForecast.first.feelsLike.round()}°',
                                        ),
                                        _buildWeatherDetail(
                                          Icons.water_drop_outlined,
                                          'Humidity',
                                          '${_hourlyForecast.first.humidity}%',
                                        ),
                                        _buildWeatherDetail(
                                          Icons.air_outlined,
                                          'Wind',
                                          '${_hourlyForecast.first.windSpeed} m/s',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Hourly forecast
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Today',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _hourlyForecast.length,
                                itemBuilder: (context, index) {
                                  final weather = _hourlyForecast[index];
                                  return Container(
                                    width: 80,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          DateFormat('ha').format(weather.date).toLowerCase(),
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _getWeatherIcon(weather.icon),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${weather.temperature.round()}°',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Next 7 Days',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Weekly forecast
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final weather = _dailyForecast[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              title: Text(
                                DateFormat('EEEE').format(weather.date),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                weather.condition,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _getWeatherIcon(weather.icon),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${weather.temperature.round()}°',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: _dailyForecast.length,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    if (!_isLoading) {
      _controller.forward(from: 0.0);
    }
  }

  Widget _buildWeatherDetail(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _getWeatherIcon(String iconCode) {
    if (!_cachedImages.containsKey(iconCode)) {
      _cachedImages[iconCode] = Image.network(
        'https://openweathermap.org/img/w/$iconCode.png',
        width: 32,
        height: 32,
        cacheWidth: 64,
        filterQuality: FilterQuality.medium,
      );
    }
    return _cachedImages[iconCode]!;
  }
}
