import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:weather_app/models/weather_models.dart';

class WeatherService {
  static const BASE_URL = "https://api.openweathermap.org/data/2.5/weather";
  final String apiKey;

  WeatherService(this.apiKey);

  Future<Weather> getWeather(String cityName) async {
    final url = Uri.parse('$BASE_URL?q=$cityName&appid=$apiKey&units=metric');
    print("Fazendo requisição para: $url");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return Weather.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  Future<String> getCurrentCity() async {
    try {
      print("Verificando permissão...");
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Permissão de localização negada.");
        }
      }

      print("Obtendo posição...");
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      print("Latitude: ${position.latitude}, Longitude: ${position.longitude}");

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      print("Placemarks encontrados: $placemarks");

      String? city = placemarks[0].locality;

      if (city == null || city.isEmpty) {
        city = placemarks[0].subAdministrativeArea ??
               placemarks[0].administrativeArea;
      }

      if (city == null || city.isEmpty) {
        throw Exception("Cidade não detectada");
      }

      print("Cidade detectada: $city");
      return city;
    } catch (e) {
      print("Erro ao obter a cidade: $e");
      throw Exception("Erro ao obter a cidade: $e");
    }
  }
}
