// lib/services/weather_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey = '4GOuMoZdG4mwaLb6XHCtlNHUG2ImfxIA';

  Future<String?> getCityCode(double lat, double lon) async {
    final url = Uri.parse(
        'http://dataservice.accuweather.com/locations/v1/cities/geoposition/search?apikey=$apiKey&q=$lat,$lon');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
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
        final date = f['Date'].substring(8, 10);
        final min = f['Temperature']['Minimum']['Value'];
        final max = f['Temperature']['Maximum']['Value'];
        return '$date: $min°C - $max°C';
      }).toList();
    }
    return [];
  }
}
