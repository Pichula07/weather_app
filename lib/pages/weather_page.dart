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

  String getWeatherAnimation(String? mainCondition){
    if (mainCondition == null) return 'assets/sunny.json';

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
        return 'assets/sunny.json';
      default:
        return 'assets/sunny.json';
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
      backgroundColor: Colors.grey[800],
      body: Center(
        child: _weather == null
            ? const CircularProgressIndicator() 
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_weather?.cityName?? "Loading City"), // AQUI SERA O NOME DA CIDADE

                  Lottie.asset(getWeatherAnimation(_weather?.mainCondition)),

                  Text('${_weather!.temperature.round()}ºC'),
                ],
              ),
      ),
    );
  }
}
