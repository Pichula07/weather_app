import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart';

class Cidades extends StatefulWidget {
  const Cidades({super.key});

  @override
  _CidadesState createState() => _CidadesState();
}

class _CidadesState extends State<Cidades> {
  final String apiKey = '4GOuMoZdG4mwaLb6XHCtlNHUG2ImfxIA';

  String? cityName;
  String? weatherText;
  double? temperature;
  String? weatherIconPhrase;
  List<String> forecast = [];
  String? error;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWeatherData();
  }

  Future<void> fetchWeatherData() async {
    try {
      final position = await _determinePosition();

      final locationKey = await getCityCode(position.latitude, position.longitude);
      if (locationKey == null) {
        setState(() => error = 'Erro ao obter código da cidade');
        return;
      }

      final current = await getCurrentConditions(locationKey);
      if (current == null) {
        setState(() => error = 'Erro ao buscar clima atual');
        return;
      }

      final futureForecast = await getForecast(locationKey);

      setState(() {
        cityName = current['city'];
        weatherText = current['text'];
        temperature = current['temp'];
        weatherIconPhrase = current['icon'];
        forecast = futureForecast;
      });
    } catch (e) {
      setState(() => error = 'Erro: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw 'Serviço de localização desativado.';

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw 'Permissão negada';
    }
    if (permission == LocationPermission.deniedForever) throw 'Permissão permanente negada';

    return await Geolocator.getCurrentPosition();
  }

  Future<String?> getCityCode(double lat, double lon) async {
    final url = Uri.parse(
        'http://dataservice.accuweather.com/locations/v1/cities/geoposition/search?apikey=$apiKey&q=$lat,$lon');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      cityName = data['LocalizedName'];
      return data['Key'];
    }
    return null;
  }

  Future<Map<String, dynamic>?> getCurrentConditions(String locationKey) async {
    final url = Uri.parse(
        'http://dataservice.accuweather.com/currentconditions/v1/$locationKey?apikey=$apiKey&language=pt-br');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final condition = data[0]['WeatherText'];
      final temp = data[0]['Temperature']['Metric']['Value'];
      final icon = data[0]['WeatherIcon'].toString();

      return {
        'city': cityName,
        'text': condition,
        'temp': temp,
        'icon': icon,
      };
    }
    return null;
  }

  Future<List<String>> getForecast(String locationKey) async {
    final url = Uri.parse(
        'http://dataservice.accuweather.com/forecasts/v1/daily/5day/$locationKey?apikey=$apiKey&language=pt-br&metric=true');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List forecasts = data['DailyForecasts'];
      return forecasts.map<String>((f) {
        final date = f['Date'].substring(0, 10);
        final min = f['Temperature']['Minimum']['Value'];
        final max = f['Temperature']['Maximum']['Value'];
        return '$date: $min°C - $max°C';
      }).toList();
    }
    return [];
  }

  String getWeatherAnimation(String? condition, String? iconCode) {
    if (condition == null) return 'assets/sunny.json';
    final lower = condition.toLowerCase();

    if (lower.contains('chuva')) return 'assets/rain.json';
    if (lower.contains('nublado') || lower.contains('neblina') || lower.contains('nuvens')) {
      return 'assets/cloud.json';
    }
    if (lower.contains('trovoada') || lower.contains('tempestade')) {
      return 'assets/thunder.json';
    }
    if (lower.contains('limpo') || lower.contains('ensolarado')) {
      return iconCode?.endsWith('n') == true ? 'assets/clean_night.json' : 'assets/sunny.json';
    }
    return iconCode?.endsWith('n') == true ? 'assets/clean_night.json' : 'assets/sunny.json';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                isLoading = true;
                error = null;
              });
              fetchWeatherData();
            },
          ),
        ],
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : error != null
            ? Text(error!, style: const TextStyle(color: Colors.red))
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                cityName ?? "Localização...",
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Lottie.asset(
                getWeatherAnimation(weatherText, weatherIconPhrase),
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 20),
              Text(
                weatherText ?? "Clima...",
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                '${temperature?.round() ?? '--'}ºC',
                style: const TextStyle(
                  fontSize: 45,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Próximos 5 dias:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 10),
              for (var f in forecast)
                Text(
                  f,
                  style: const TextStyle(color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
