import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const SkyCastApp());

class DayForecast {
  final DateTime date;
  final int code;
  final double max;
  final double min;
  DayForecast(this.date, this.code, this.max, this.min);
}

class Weather {
  final String city;
  final double temp;
  final double feelsLike;
  final double wind;
  final int humidity;
  final int code;
  final List<DayForecast> days;
  Weather({
    required this.city,
    required this.temp,
    required this.feelsLike,
    required this.wind,
    required this.humidity,
    required this.code,
    required this.days,
  });
}

class WeatherService {
  static Future<Weather> fetch(String query) async {
    final geoRes = await http.get(Uri.https(
      'geocoding-api.open-meteo.com',
      '/v1/search',
      {'name': query, 'count': '1'},
    ));
    if (geoRes.statusCode != 200) throw Exception('City search failed');
    final results = jsonDecode(geoRes.body)['results'] as List?;
    if (results == null || results.isEmpty) {
      throw Exception('City "$query" not found');
    }
    final place = results.first;

    final res = await http.get(Uri.https(
      'api.open-meteo.com',
      '/v1/forecast',
      {
        'latitude': '${place['latitude']}',
        'longitude': '${place['longitude']}',
        'current':
            'temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m',
        'daily': 'weather_code,temperature_2m_max,temperature_2m_min',
        'timezone': 'auto',
        'forecast_days': '7',
      },
    ));
    if (res.statusCode != 200) throw Exception('Weather request failed');

    final data = jsonDecode(res.body);
    final cur = data['current'];
    final daily = data['daily'];
    final times = daily['time'] as List;

    final days = List.generate(times.length, (i) {
      return DayForecast(
        DateTime.parse(times[i]),
        daily['weather_code'][i] as int,
        (daily['temperature_2m_max'][i] as num).toDouble(),
        (daily['temperature_2m_min'][i] as num).toDouble(),
      );
    });

    final country = place['country'] ?? '';
    return Weather(
      city: country.isEmpty ? place['name'] : '${place['name']}, $country',
      temp: (cur['temperature_2m'] as num).toDouble(),
      feelsLike: (cur['apparent_temperature'] as num).toDouble(),
      wind: (cur['wind_speed_10m'] as num).toDouble(),
      humidity: (cur['relative_humidity_2m'] as num).toInt(),
      code: cur['weather_code'] as int,
      days: days,
    );
  }
}

String emojiFor(int c) {
  if (c == 0) return '☀️';
  if (c <= 2) return '⛅';
  if (c == 3) return '☁️';
  if (c == 45 || c == 48) return '🌫️';
  if (c >= 51 && c <= 57) return '🌦️';
  if (c >= 61 && c <= 67) return '🌧️';
  if (c >= 71 && c <= 77) return '❄️';
  if (c >= 80 && c <= 82) return '🌧️';
  if (c == 85 || c == 86) return '🌨️';
  if (c >= 95) return '⛈️';
  return '🌡️';
}

String labelFor(int c) {
  if (c == 0) return 'Clear sky';
  if (c <= 2) return 'Partly cloudy';
  if (c == 3) return 'Overcast';
  if (c == 45 || c == 48) return 'Foggy';
  if (c >= 51 && c <= 57) return 'Drizzle';
  if (c >= 61 && c <= 67) return 'Rain';
  if (c >= 71 && c <= 77) return 'Snow';
  if (c >= 80 && c <= 82) return 'Rain showers';
  if (c == 85 || c == 86) return 'Snow showers';
  if (c >= 95) return 'Thunderstorm';
  return 'Unknown';
}

List<Color> gradientFor(int? c) {
  if (c == null) return const [Color(0xFF283048), Color(0xFF859398)];
  if (c <= 2) return const [Color(0xFF2193B0), Color(0xFF6DD5ED)];
  if (c == 3) return const [Color(0xFF606C88), Color(0xFF3F4C6B)];
  if (c == 45 || c == 48) return const [Color(0xFF757F9A), Color(0xFFD7DDE8)];
  if ((c >= 51 && c <= 67) || (c >= 80 && c <= 82)) {
    return const [Color(0xFF373B44), Color(0xFF4286F4)];
  }
  if ((c >= 71 && c <= 77) || c == 85 || c == 86) {
    return const [Color(0xFF83A4D4), Color(0xFFB6FBFF)];
  }
  return const [Color(0xFF141E30), Color(0xFF243B55)];
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class SkyCastApp extends StatelessWidget {
  const SkyCastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkyCast',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: Colors.lightBlue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();
  Weather? _weather;
  bool _loading = false;
  String? _error;
  bool _celsius = true;

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final w = await WeatherService.fetch(q);
      setState(() => _weather = w);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  String _t(double c) {
    final v = _celsius ? c : c * 9 / 5 + 32;
    return '${v.round()}°';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientFor(_weather?.code),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _searchBar(),
                    const SizedBox(height: 12),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('°C')),
                        ButtonSegment(value: false, label: Text('°F')),
                      ],
                      selected: {_celsius},
                      onSelectionChanged: (s) =>
                          setState(() => _celsius = s.first),
                    ),
                    const SizedBox(height: 24),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      )
                    else if (_error != null)
                      _message('😕', _error!)
                    else if (_weather == null)
                      _message('🔎', 'Search for a city to see the weather')
                    else
                      _weatherView(_weather!),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchBar() {
    return TextField(
      controller: _controller,
      onSubmitted: (_) => _search(),
      decoration: InputDecoration(
        hintText: 'Search city...',
        filled: true,
        fillColor: Colors.white24,
        prefixIcon: const Icon(Icons.location_city),
        suffixIcon: IconButton(
          icon: const Icon(Icons.search),
          onPressed: _search,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _message(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _weatherView(Weather w) {
    return Column(
      children: [
        Text(w.city,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(emojiFor(w.code), style: const TextStyle(fontSize: 90)),
        Text(_t(w.temp),
            style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w300)),
        Text(labelFor(w.code), style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _info('Feels like', _t(w.feelsLike)),
            _info('Humidity', '${w.humidity}%'),
            _info('Wind', '${w.wind.round()} km/h'),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          color: Colors.white24,
          elevation: 0,
          child: Column(
            children: w.days.map((d) {
              return ListTile(
                leading: Text(emojiFor(d.code),
                    style: const TextStyle(fontSize: 28)),
                title: Text(_weekdays[d.date.weekday - 1]),
                subtitle: Text(labelFor(d.code)),
                trailing: Text('${_t(d.max)} / ${_t(d.min)}',
                    style: const TextStyle(fontSize: 16)),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _info(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
