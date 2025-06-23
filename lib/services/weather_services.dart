// lib/services/weather_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

// Mapa de emojis para códigos de ícone
const Map<String, String> _emojiMap = {
  '1': '☀️', '2': '☀️', '3': '☀️', '4': '🌤️', '5': '🌤️',
  '6': '⛅️', '20': '⛅️','21': '⛅️','23': '⛅️',
  '7': '☁️','8': '☁️','19': '☁️','22': '☁️',
  '13': '🌦️','14': '🌦️','12': '🌧️','18': '🌧️',
  '16': '⛈️','17': '⛈️','15': '🌩️','25':'',
  '26':'❄️','29':'☃️','24':'☃️','11':'🌫️',
  '30':'🥵','31':'🥶','32':'🌬️','33':'🌔',
  '34':'🌔','35':'☁️','36':'☁️','37':'☁️',
  '38':'☁️','39':'🌧️','40':'🌧️','41':'⛈️',
  '42':'⛈️','43':'🌧️','44':'❄️',
};

// Retorna emoji pelo código
String _emojiForCode(String code) => _emojiMap[code] ?? '❓';

class WeatherService {
  final List<String> _apiKeys = [
    '4GOuMoZdG4mwaLb6XHCtlNHUG2ImfxIA',
    'oXMcfI3kHAFIQsq6xgqMjKnEtm5xYFEP',
    'ANnvthyLR5pr2nBDHOf7oMATppe6vXQm',
  ];

  Map<String, String?> _sunMoonData = {};
  Map<String, String?> get sunMoonData => _sunMoonData;

  /// Retorna os dados de nascer/pôr do sol e da lua já armazenados em _sunMoonData.
  Map<String, String?> getSunMoonData() {
    return _sunMoonData;
  }

  Future<String?> getCityCode(double lat, double lon) async {
    for (var key in _apiKeys) {
      final url = Uri.parse(
        'http://dataservice.accuweather.com/locations/v1/cities/geoposition/search'
        '?apikey=$key&q=$lat,$lon',
      );
      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['Key'];
        }
      } catch (_) {
        // tenta próxima chave
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> getCurrentConditions(String locationKey) async {
    final url = Uri.parse(
      'http://dataservice.accuweather.com/currentconditions/v1/$locationKey?apikey=${_apiKeys[0]}&language=pt-br&details=true',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final condition = data[0]['WeatherText'];
      final temp = data[0]['Temperature']['Metric']['Value'];
      final icon = data[0]['WeatherIcon'].toString();
      if (kDebugMode) {
        print('Resposta completa de getCurrentConditions: $data');
      }
      

    return {
  'text': condition,
  'temp': temp,
  'icon': icon,
  'humidity': data[0]['RelativeHumidity'],
  'uvIndex': data[0]['UVIndex'],
  'windSpeed': data[0]['Wind']['Speed']['Metric']['Value'],
  'windDirection': data[0]['Wind']['Direction']['Localized'],
  'realFeel': data[0]['RealFeelTemperature']['Metric']['Value'],
  'visibility': data[0]['Visibility']['Metric']['Value'],
  'pressure': data[0]['Pressure']['Metric']['Value'],
  'minTemp': data[0]['TemperatureSummary']?['Past24HourRange']?['Minimum']?['Metric']?['Value'],
  'maxTemp': data[0]['TemperatureSummary']?['Past24HourRange']?['Maximum']?['Metric']?['Value'],
};
    }
    return null;
  }

  Future<List<String>> getForecast(String locationKey) async {
    final url = Uri.parse(
      'http://dataservice.accuweather.com/forecasts/v1/daily/5day/$locationKey?apikey=${_apiKeys[0]}&language=pt-br&metric=true&details=true',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List forecasts = data['DailyForecasts'];
      final List<String> forecastStrings = [];
      if (kDebugMode) {
        print('Resposta completa de DailyForecasts: $data');
      }
      for (var f in forecasts) {
        final date = f['Date'].substring(8, 10);
        final min = f['Temperature']['Minimum']['Value'];
        final max = f['Temperature']['Maximum']['Value'];
        final iconCode = f['Day']['Icon'].toString();
        // Captura a probabilidade de chuva do dia
        final rainProbability = f['Day']?['RainProbability'];
        final emoji = _emojiForCode(iconCode);
        forecastStrings.add('$date $min - $max°C $emoji');

        if (forecastStrings.length == 1) {
          // Preenche os dados do primeiro dia
          final sunrise = DateTime.tryParse(f['Sun']?['Rise'] ?? '')?.toLocal().toIso8601String().substring(11, 16);
          final sunset = DateTime.tryParse(f['Sun']?['Set'] ?? '')?.toLocal().toIso8601String().substring(11, 16);
          final rawPhase = f['Moon']?['Phase'] ?? 'Unknown';
          final moonPhaseMap = {
            'New': 'Nova 🌑',
            'WaxingCrescent': 'Crescente 🌒',
            'FirstQuarter': 'Crescente 🌓',
            'WaxingGibbous': 'Crescente 🌔',
            'Full': 'Cheia 🌕',
            'WaningGibbous': 'Minguante 🌖',
            'LastQuarter': 'Minguante 🌗',
            'WaningCrescent': 'Minguante 🌘',
          };
          final moonPhase = moonPhaseMap[rawPhase] ?? 'Desconhecida 🌚';
          if (kDebugMode) {
            print('Fase da Lua recebida: $moonPhase');
          }
          this._sunMoonData = {
            'sunrise': sunrise,
            'sunset': sunset,
            'moonPhase': moonPhase,
            'rainProbability': rainProbability?.toString(),
          };
        }
      }
      return forecastStrings;
    }
    return [];
  }
Future<List<String>> getNextFiveHours(String locationKey) async {
  final url = Uri.parse(
    'http://dataservice.accuweather.com/forecasts/v1/hourly/12hour/$locationKey?apikey=${_apiKeys[0]}&language=pt-br&metric=true',
  );
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body) as List;
    if (kDebugMode) {
      print('Resposta completa de getNextFiveHours: $data');
    }

    final now = DateTime.now().subtract(Duration(minutes: DateTime.now().minute));

    return data
        .where((hour) {
          final dateTime = DateTime.parse(hour['DateTime']);
          return !dateTime.isBefore(now) && dateTime.hour % 2 == 0;
        })
        .take(5)
        .map<String>((hour) {
          final dateTime = DateTime.parse(hour['DateTime']);
          final hourFormatted = '${dateTime.hour.toString().padLeft(2, '0')}h';
          final temp = hour['Temperature']['Value'];
          final iconCode = hour['WeatherIcon'].toString();
          final emoji = _emojiForCode(iconCode);
          return '$hourFormatted - ${temp.round()}°C $emoji';
        })
        .toList();
  }

  return [];
}
}
