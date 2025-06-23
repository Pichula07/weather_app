import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:lottie/lottie.dart';
import '../services/weather_services.dart';

// Mapa de emojis local (caso queira customizar aqui)
const Map<String, String> _emojiMap = {
  '1': '☀️',
  '2': '☀️',
  '3': '☀️',
  '4': '🌤️',
  '5': '🌤️',
  '6': '⛅️',
  '20': '⛅️',
  '21': '⛅️',
  '23': '⛅️',
  '7': '☁️',
  '8': '☁️',
  '19': '☁️',
  '22': '☁️',
  '13': '🌦️',
  '14': '🌦️',
  '12': '🌧️',
  '18': '🌧️',
  '16': '⛈️',
  '17': '⛈️',
  '15': '🌩️',
  '25': '',
  '26': '❄️',
  '29': '☃️',
  '24': '☃️',
  '11': '🌫️',
  '30': '🥵',
  '31': '🥶',
  '32': '🌬️',
  '33': '🌔',
  '34': '🌔',
  '35': '☁️',
  '36': '☁️',
  '37': '☁️',
  '38': '☁️',
  '39': '🌧️',
  '40': '🌧️',
  '41': '⛈️',
  '42': '⛈️',
  '43': '🌧️',
  '44': '❄️',
};

String _emojiForCode(String code) => _emojiMap[code] ?? '❓';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage>
    with SingleTickerProviderStateMixin {
  final weatherService = WeatherService();

  String? cityName;
  String? weatherText;
  double? temperature;
  String? weatherIconPhrase;
  List<String> forecastHours = [];
  List<String> forecastDays = [];
  String? error;
  bool isLoading = true;

  String? headlineText;
  String? sunrise;
  String? sunset;
  String? airQuality;
  String? uvCategory;
  int? averageHumidity;
  int? rainProbability;
  String? windDirection;
  double? windSpeedValue;
  double? realFeel;
  double? realFeelShade;
  double? visibility;
  String? moonPhase;
  String? minTemperature;
  String? maxTemperature;

  late AnimationController _lottieController;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    fetchWeatherData();
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  Future<void> fetchWeatherData() async {
    try {
      final position = await _determinePosition();

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      print('Placemarks: $placemarks');

      String extractedCity = "Local Desconhecido";
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        if (placemark.subAdministrativeArea != null &&
            placemark.subAdministrativeArea!.isNotEmpty) {
          extractedCity = placemark.subAdministrativeArea!;
        } else if (placemark.administrativeArea != null &&
            placemark.administrativeArea!.isNotEmpty) {
          extractedCity = placemark.administrativeArea!;
        } else if (placemark.country != null &&
            placemark.country!.isNotEmpty) {
          extractedCity = placemark.country!;
        }
      }

      final nomeLocal = extractedCity;

      final locationKey = await weatherService.getCityCode(
        position.latitude,
        position.longitude,
      );
      if (locationKey == null) {
        setState(() {
          error = 'Erro ao obter código da cidade. Tente novamente.';
          isLoading = false;
        });
        return;
      }

      final current = await weatherService.getCurrentConditions(locationKey);
      print('JSON de condições atuais: $current');
      if (current == null) {
        setState(() {
          error = 'Erro ao buscar clima atual. Tente novamente.';
          isLoading = false;
        });
        return;
      }

      final nextHours = await weatherService.getNextFiveHours(locationKey);
      final futureForecast = await weatherService.getForecast(locationKey);
      final sunMoon = weatherService.getSunMoonData();
      final sunriseValue = sunMoon['sunrise'] ?? '';
      final sunsetValue = sunMoon['sunset'] ?? '';
      final moonPhaseValue = sunMoon['moonPhase'] ?? '';
      final averageHumidityValue = current['humidity'] as int?;
      final uvCategoryValue = current['uvIndex']?.toString();
      final windDirectionValue = current['windDirection'] as String?;
      final windSpeedValueLocal = (current['windSpeed'] as num?)?.toDouble();
      final realFeelValue = (current['realFeel'] as num?)?.toDouble();
      final realFeelShadeValue = (current['realFeelShade'] as num?)?.toDouble();
      final visibilityValue = (current['visibility'] as num?)?.toDouble();
      final minTempValue = (current['minTemp'] as num?)?.toDouble();
      final maxTempValue = (current['maxTemp'] as num?)?.toDouble();
      final rainProbabilityValue =
          int.tryParse(sunMoon['rainProbability'] ?? '');

      setState(() {
        cityName = nomeLocal;
        weatherText = current['text'] as String?;
        temperature = current['temp'] as double?;
        weatherIconPhrase = current['icon'] as String?;
        forecastHours = nextHours;
        forecastDays = futureForecast.take(5).toList();
        sunrise = sunriseValue;
        sunset = sunsetValue;
        uvCategory = uvCategoryValue;
        averageHumidity = averageHumidityValue;
        windDirection = windDirectionValue;
        windSpeedValue = windSpeedValueLocal;
        error = null;
        isLoading = false;
        realFeel = realFeelValue;
        realFeelShade = realFeelShadeValue;
        visibility = visibilityValue;
        moonPhase = moonPhaseValue;
        rainProbability = rainProbabilityValue;
        minTemperature = minTempValue?.toString();
        maxTemperature = maxTempValue?.toString();
      });
    } catch (e) {
      setState(() {
        error = 'Erro ao buscar dados: $e';
        isLoading = false;
      });
      print('Erro em fetchWeatherData: $e');
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Serviço de localização desativado. Por favor, ative-o nas configurações do seu dispositivo.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Permissão de localização negada. Conceda permissão nas configurações do aplicativo.';
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw 'Permissão de localização negada permanentemente. Por favor, habilite-a nas configurações do aplicativo.';
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  String getWeatherAnimation(String? condition, String? iconCode) {
    if (condition == null) return 'assets/sunny.json';
    final lower = condition.toLowerCase();

    if (lower.contains('chuva') || lower.contains('garoa')) {
      return 'assets/rain.json';
    }
    if (lower.contains('nublado') ||
        lower.contains('neblina') ||
        lower.contains('algumas nuvens')) {
      return 'assets/cloud.json';
    }
    if (lower.contains('trovoada') || lower.contains('tempestade')) {
      return 'assets/thunder.json';
    }
    if (lower.contains('limpo') ||
        lower.contains('ensolarado') ||
        lower.contains('sol')) {
      if (iconCode != null && (int.tryParse(iconCode) ?? 0) >= 33) {
        return 'assets/clean_night.json';
      }
      return 'assets/sunny.json';
    }
    if (iconCode != null && (int.tryParse(iconCode) ?? 0) >= 33) {
      return 'assets/clean_night.json';
    }
    return 'assets/sunny.json';
  }

  /// Retorna um gradiente dinâmico baseado no horário atual, nascer e pôr do sol.
  LinearGradient getDynamicGradient() {
    final now = DateTime.now();
    DateTime? sunriseTime;
    DateTime? sunsetTime;
    try {
      if (sunrise != null && sunrise!.contains(':')) {
        final parts = sunrise!.split(':').map(int.parse).toList();
        sunriseTime = DateTime(now.year, now.month, now.day, parts[0], parts[1]);
      }
      if (sunset != null && sunset!.contains(':')) {
        final parts = sunset!.split(':').map(int.parse).toList();
        sunsetTime = DateTime(now.year, now.month, now.day, parts[0], parts[1]);
      }
    } catch (_) {}
    if (sunriseTime != null &&
        now.isAfter(sunriseTime.subtract(const Duration(hours: 2))) &&
        now.isBefore(sunriseTime.add(const Duration(hours: 2)))) {
      // Amanhecer
      return const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Color.fromARGB(255, 213, 151, 59),
          Color.fromARGB(255, 195, 127, 110),
          Color.fromARGB(255, 171, 83, 152),
          Color.fromARGB(255, 76, 52, 115),
          Color.fromARGB(255, 6, 30, 42),
        ],
      );
    } else if (sunsetTime != null &&
        now.isAfter(sunsetTime.subtract(const Duration(hours: 1))) &&
        now.isBefore(sunsetTime.add(const Duration(minutes: 30)))) {
      // Anoitecer
      return const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Color.fromARGB(255, 90, 120, 171),
          Color.fromARGB(222, 116, 150, 207),
          Color.fromARGB(255, 195, 155, 81),
          Color.fromARGB(255, 197, 112, 20),
        ],
      );
    } else if (now.hour >= 8 && now.hour < 16) {
      // Dia
      return const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Color.fromARGB(255, 45, 140, 195),
          Color.fromARGB(255, 0, 3, 5),
        ],
      );
    } else {
      // Noite
      return const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Color.fromARGB(255, 25, 42, 86),
          Color.fromARGB(255, 0, 19, 34)
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Container(
        decoration: BoxDecoration(gradient: getDynamicGradient()),
        child: Center(
          child: isLoading
              ? _buildLoading()
              : error != null
                  ? _buildError()
                  : _buildContent(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(40),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              cityName ?? "Localização...",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w600,
                color: Color.fromARGB(180, 255, 255, 255),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.search, color: Color.fromARGB(180, 255, 255, 255)),
              onPressed: () {
                // implementar ação de pesquisa
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Color.fromARGB(180, 255, 255, 255)),
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
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const CircularProgressIndicator(color: Colors.white);
  }

  Widget _buildError() {
    return Text(
      error!,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.red, fontSize: 16),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildWeatherDescription(),
          _buildAnimation(),
          _buildCurrentWeather(),
          _buildDetailsSection(),
          _buildForecastSection(),
          _buildSunMoonSection(),
        ],
      ),
    );
  }

  Widget _buildWeatherDescription() {
    return weatherText != null
        ? Padding(
            padding: const EdgeInsets.only(top: 60, bottom: 6),
            child: Text(
              weatherText ?? "Clima...",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color.fromARGB(170, 255, 255, 255),
              ),
            ),
          )
        : const SizedBox.shrink();
  }

  Widget _buildAnimation() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Lottie.asset(
          getWeatherAnimation(weatherText, weatherIconPhrase),
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          controller: _lottieController,
          onLoaded: (composition) {
            _lottieController
              ..duration = composition.duration * 1.75
              ..repeat();
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCurrentWeather() {
    return Column(
      children: [
        Text(
          '${temperature?.round() ?? '--'}ºC',
          style: const TextStyle(
            fontSize: 60,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(180, 255, 255, 255),
          ),
        ),
        if (realFeel != null)
          Text(
            'Sensação térmica de ${realFeel!.round()}ºC',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color.fromARGB(160, 255, 255, 255),
            ),
          ),
        if (minTemperature != null && maxTemperature != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Mínima de ${minTemperature}ºC e Máxima de ${maxTemperature}ºC',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color.fromARGB(160, 255, 255, 255),
              ),
            ),
          ),
        if (headlineText != null)
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color.fromARGB(10, 255, 255, 255),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                headlineText!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color.fromARGB(220, 255, 255, 86),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    if (!(airQuality != null ||
        uvCategory != null ||
        averageHumidity != null ||
        rainProbability != null ||
        windDirection != null ||
        minTemperature != null ||
        maxTemperature != null)) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'Detalhes do Clima',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  if (airQuality != null)
                    _buildInfoTile('🍃✅', airQuality!),
                  if (uvCategory != null)
                    _buildInfoTile('🌞📈', uvCategory!),
                  if (rainProbability != null)
                    _buildInfoTile('☔️🤷', '$rainProbability%'),
                  if (visibility != null)
                    _buildInfoTile('🏞️🔭', '${visibility!.round()} km'),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  if (averageHumidity != null)
                    _buildInfoTile('🍃💧', '$averageHumidity%'),
                  if (windDirection != null && windSpeedValue != null)
                    _buildInfoTile('🌬️', '$windDirection, ${windSpeedValue!.round()} km/h'),
                  if (moonPhase != null)
                    _buildInfoTile('🌙', moonPhase ?? '--'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
Widget _buildForecastSection() {
  if (forecastDays.isEmpty && forecastHours.isEmpty) {
    return const Padding(
      padding: EdgeInsets.only(top: 10),
      child: Text(
        "Sem dados de previsão",
        style: TextStyle(
          color: Color.fromARGB(170, 255, 255, 255),
        ),
      ),
    );
  }
  
  return Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Coluna: Previsão por Horas
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Próximas Horas',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(170, 255, 255, 255),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ...List.generate(5, (index) {
                final item = forecastHours.length > index ? forecastHours[index] : '';
                String boldPart = '';
                String rest = item;
                final match = RegExp(r'^([^\s\-]+)[\s\-]+(.*)$').firstMatch(item);
                if (match != null) {
                  boldPart = match.group(1) ?? '';
                  rest = (match.group(2) ?? '').replaceAllMapped(
                    RegExp(r'(\d+\.\d+)'),
                    (m) => double.parse(m.group(1)!).round().toString(),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(10, 255, 255, 255),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          boldPart,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(170, 255, 255, 255),
                          ),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            rest,
                            style: const TextStyle(
                              color: Color.fromARGB(170, 255, 255, 255),
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Coluna: Previsão por Dias
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Próximos Dias',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(170, 255, 255, 255),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ...List.generate(5, (index) {
                final item = forecastDays.length > index ? forecastDays[index] : '';
                String boldPart = '';
                String rest = item;
                final match = RegExp(r'^([^\s\-]+)[\s\-]+(.*)$').firstMatch(item);
                if (match != null) {
                  boldPart = match.group(1) ?? '';
                  rest = (match.group(2) ?? '').replaceAllMapped(
                    RegExp(r'(\d+\.\d+)'),
                    (m) => double.parse(m.group(1)!).round().toString(),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(10, 255, 255, 255),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          boldPart,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(170, 255, 255, 255),
                          ),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            rest,
                            style: const TextStyle(
                              color: Color.fromARGB(170, 255, 255, 255),
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    ),
  );
}
  Widget _buildSunMoonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.only(
            right: 5,
            left: 5,
            top: 5,
            bottom: 5,
          ),
          child: Text(
            'Nascer e Pôr do Sol',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(170, 255, 255, 255),
              ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Color.fromARGB(10, 255, 255, 255),
            borderRadius: BorderRadius.circular(20),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          constraints: const BoxConstraints(minHeight: 200),
          width: double.infinity,
          height: 200,
          child: Padding(
            padding: const EdgeInsets.only(
              right: 5,
              left: 5,
              top: 5,
              bottom: 45,
            ),
            child: CustomPaint(
              painter: SunPathPainter(
                sunriseTime: sunrise,
                sunsetTime: sunset,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color.fromARGB(10, 255, 255, 255),
          borderRadius: BorderRadius.circular(20),
        ),
        width: double.infinity,
        child: Center(
          child: Text(
            '$title: $value',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class SunPathPainter extends CustomPainter {
  final String? sunriseTime;
  final String? sunsetTime;

  SunPathPainter({this.sunriseTime, this.sunsetTime});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white30
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 20;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, 3.14, 3.14, false, paint);

    DateTime? sunriseDateTime;
    DateTime? sunsetDateTime;
    try {
      final now = DateTime.now();
      if (sunriseTime != null && sunsetTime != null) {
        final sunriseParts = sunriseTime!.split(':').map(int.parse).toList();
        final sunsetParts = sunsetTime!.split(':').map(int.parse).toList();
        sunriseDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          sunriseParts[0],
          sunriseParts[1],
        );
        sunsetDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          sunsetParts[0],
          sunsetParts[1],
        );
      }
    } catch (_) {}

    final isNight = sunriseDateTime != null &&
        sunsetDateTime != null &&
        (DateTime.now().isAfter(sunsetDateTime) ||
            DateTime.now().isBefore(sunriseDateTime));

    final celestialPaint = Paint()
      ..color = isNight
          ? const Color.fromARGB(255, 156, 156, 156)
          : Colors.amber;

    if (sunriseDateTime != null &&
        sunsetDateTime != null &&
        sunsetDateTime.isAfter(sunriseDateTime)) {
      final now = DateTime.now();
      final totalMinutes = sunsetDateTime.difference(sunriseDateTime).inMinutes;
      final elapsedMinutes =
          now.difference(sunriseDateTime).inMinutes.clamp(0, totalMinutes);
      double angle;
      if (isNight) {
        final nightElapsed = now.isAfter(sunsetDateTime)
            ? now.difference(sunsetDateTime).inMinutes.clamp(0, totalMinutes)
            : 0;
        angle = pi * (1 - (nightElapsed / totalMinutes));
      } else {
        angle = (elapsedMinutes / totalMinutes) * pi;
      }
      final celestialX = center.dx + radius * cos(angle + pi);
      final celestialY = center.dy + radius * sin(angle + pi);
      canvas.drawCircle(Offset(celestialX, celestialY), 8, celestialPaint);
    }

    final textPainter1 = TextPainter(
      text: TextSpan(
        text: sunriseTime ?? '--:--',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    final textPainter2 = TextPainter(
      text: TextSpan(
        text: sunsetTime ?? '--:--',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter1.layout();
    textPainter2.layout();
    textPainter1.paint(canvas, Offset(center.dx - radius - 15, center.dy + 10));
    textPainter2.paint(canvas, Offset(center.dx + radius - 15, center.dy + 10));

    if (sunriseDateTime != null && sunsetDateTime != null) {
      final now = DateTime.now();
      String message = '';
      if (now.isBefore(sunsetDateTime) && now.isAfter(sunriseDateTime)) {
        final diff = sunsetDateTime.difference(now);
        final hours = diff.inHours;
        final minutes = diff.inMinutes % 60;
        message = 'Faltam ${hours}h ${minutes}min para o pôr do sol';
      } else {
        DateTime nextSunrise = sunriseDateTime;
        if (now.isAfter(sunsetDateTime)) {
          nextSunrise = sunriseDateTime.add(const Duration(days: 1));
        }
        final diff = nextSunrise.difference(now);
        final hours = diff.inHours;
        final minutes = diff.inMinutes % 60;
        message = 'Faltam ${hours}h ${minutes}min para o nascer do sol';
      }
      final messagePainter = TextPainter(
        text: TextSpan(
          text: message,
          style: const TextStyle(
            color: Color.fromARGB(180, 255, 255, 255),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      messagePainter.layout();
      final offset = Offset(
        (size.width - messagePainter.width) / 2,
        size.height - 20,
      );
      messagePainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
