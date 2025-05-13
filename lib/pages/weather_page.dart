import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart';
import '../services/weather_services.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final weatherService = WeatherService();

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

      final locationKey = await weatherService.getCityCode(position.latitude, position.longitude);
      if (locationKey == null) {
        setState(() => error = 'Erro ao obter código da cidade');
        return;
      }

      final current = await weatherService.getCurrentConditions(locationKey);
      if (current == null) {
        setState(() => error = 'Erro ao buscar clima atual');
        return;
      }

      final futureForecast = await weatherService.getForecast(locationKey);

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
              forecast.isEmpty
                  ? const Text(
                "Sem dados de previsão",
                style: TextStyle(color: Colors.white),
              )
                  : Column(
                children: forecast
                    .map((f) => Text(f, style: const TextStyle(color: Colors.white)))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
