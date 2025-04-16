import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:weather_app/models/weather_models.dart';
import 'package:weather_app/services/weather_services.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final _weatherService = WeatherService('a8927c82d2d1e95d743012e56c2231c0');
  Weather? _weather;

  _fetchWeather() async {
    try {
      String cityName = await _weatherService.getCurrentCity();
      final weather = await _weatherService.getWeather(cityName);
      setState(() {
        _weather = weather;
      });
    } catch (e) {
      print('Erro ao buscar clima: $e');
    }
  }

  String getWeatherAnimation(String? mainCondition, String? icon){
  if (mainCondition == null || icon == null) return 'assets/sunny.json';

  bool isNight = icon.contains("n"); // Verifica se é noite

  switch(mainCondition.toLowerCase()){
    case 'clouds':
    case 'mist':
    case 'smoke':
    case 'haze':
    case 'dust':
    case 'fog':
      return 'assets/cloud.json';
    case 'rain':
    case 'drizzle':
    case 'shower rain':
      return 'assets/rain.json';
    case 'thunderstorm':
      return 'assets/thunder.json';
    case 'clear':
      return isNight ? 'assets/clean_night.json' : 'assets/sunny.json'; 
    default:
      return isNight ? 'assets/clean_night.json' : 'assets/sunny.json';
  }
}

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      body: Center(
        child: _weather == null
            ? const CircularProgressIndicator(color: Colors.white) 
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Nome da cidade
                  Text(
                    _weather?.cityName ?? "Carregando...",
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Animação do clima
                  Lottie.asset(
                    getWeatherAnimation(_weather?.mainCondition, _weather?.icon),
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 20),

                  Text(
                    _weather?.description ?? "Carregando...",
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  // Temperatura
                  Text(
                    '${_weather!.temperature.round()}ºC',
                    style: const TextStyle(
                      fontSize: 45,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
