import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:lottie/lottie.dart';
import '../services/weather_services.dart';

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

  // Novas variáveis para detalhes extras
  String? airQuality;
  String? uvCategory;
  int? averageHumidity;
  int? rainProbability;
  String? windDirection;
  double? windSpeedValue;

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

      // --- INÍCIO DA CORREÇÃO DA LOCALIZAÇÃO: Priorizar Cidade, depois Bairro/Distrito, etc. ---
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      print('Placemarks: $placemarks'); // Log para depuração

      String extractedCity =
          "Local Desconhecido"; // Valor padrão caso nada seja encontrado

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        // Prioridade 4: subAdministrativeArea (região administrativa menor que o estado, mas maior que o bairro)
        if (placemark.subAdministrativeArea != null &&
            placemark.subAdministrativeArea!.isNotEmpty) {
          extractedCity = placemark.subAdministrativeArea!;
        }
        // Prioridade 5: administrativeArea (estado/região, como último recurso antes do país)
        else if (placemark.administrativeArea != null &&
            placemark.administrativeArea!.isNotEmpty) {
          extractedCity = placemark.administrativeArea!;
        }
        // Prioridade 6: country (país, o menos específico)
        else if (placemark.country != null && placemark.country!.isNotEmpty) {
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

      final futureForecast = await weatherService.getForecast(locationKey);
      final headline = futureForecast.isNotEmpty ? futureForecast[0] : '';

      // CORREÇÃO: buscar os dados assíncronos ANTES do setState
      final firstForecast = await weatherService.getRawForecast(locationKey);
      String? sunriseValue;
      String? sunsetValue;
      String? headlineValue;
      String? airQualityValue;
      String? uvCategoryValue;
      int? averageHumidityValue;
      int? rainProbabilityValue;
      String? windDirectionValue;
      double? windSpeedValueLocal;
      if (firstForecast != null &&
          firstForecast['DailyForecasts']?.isNotEmpty == true) {
        final today = firstForecast['DailyForecasts'][0];
        sunriseValue = today['Sun']['Rise']?.substring(11, 16);
        sunsetValue = today['Sun']['Set']?.substring(11, 16);
        headlineValue = firstForecast['Headline']['Text'];
        final day = today['Day'];
        final airPollen = today['AirAndPollen'];
        final humidity = day['RelativeHumidity']?['Average'];
        final rainProb = day['RainProbability'];
        final uvIndex = airPollen?.firstWhere(
          (e) => e['Name'] == 'UVIndex',
          orElse: () => null,
        );
        final wind = day['Wind'];
        final windDir = wind?['Direction']?['English'];
        final windSpeed = wind?['Speed']?['Value'];

        airQualityValue = airPollen?[0]?['Category'];
        uvCategoryValue = uvIndex?['Category'];
        averageHumidityValue = humidity;
        rainProbabilityValue = rainProb;
        windDirectionValue = windDir;
        windSpeedValueLocal = windSpeed?.toDouble();
      }

      setState(() {
        cityName = nomeLocal;
        weatherText = current['text'] as String?;
        temperature = current['temp'] as double?;
        weatherIconPhrase = current['icon'] as String?;
        forecastHours = futureForecast.take(5).toList();
        forecastDays = futureForecast.skip(5).take(5).toList();
        sunrise = sunriseValue;
        sunset = sunsetValue;
        headlineText = headlineValue;
        airQuality = airQualityValue;
        uvCategory = uvCategoryValue;
        averageHumidity = averageHumidityValue;
        rainProbability = rainProbabilityValue;
        windDirection = windDirectionValue;
        windSpeedValue = windSpeedValueLocal;
        error = null;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Erro ao buscar dados: $e';
        isLoading = false;
      });
      print('Erro em fetchWeatherData: $e'); // Log para depuração
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
    ); // Aumentar precisão
  }

  String getWeatherAnimation(String? condition, String? iconCode) {
    if (condition == null) return 'assets/sunny.json';
    final lower = condition.toLowerCase();

    if (lower.contains('chuva') || lower.contains('garoa'))
      return 'assets/rain.json';
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

  LinearGradient getDynamicGradient() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 5 && hour < 8) {
      // Amanhecer
      return const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color.fromARGB(255, 213, 151, 59), Color.fromARGB(255, 195, 127, 110), Color.fromARGB(255, 134, 83, 147), Color.fromARGB(255, 90, 63, 135), Color.fromARGB(255, 6, 30, 42)],
      );
    } else if (hour >= 8 && hour < 18) {
      // Dia
      return const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color.fromARGB(255, 91, 136, 163), Color.fromARGB(255, 8, 31, 44)],
      );
    } else if (hour >= 18 && hour < 19) {
      // Anoitecer
      return const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color.fromARGB(255, 1, 18, 48), Color.fromARGB(255, 26, 49, 67), Color.fromARGB(255, 124, 108, 64), Color.fromARGB(255, 240, 164, 32)],
      );
    } else {
      // Noite
      return const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
       colors: [Color.fromARGB(255, 91, 136, 163), Color.fromARGB(255, 8, 31, 44)],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(gradient: getDynamicGradient()),
        child: Center(
          child:
              isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : error != null
                  ? Text(
                    error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  )
                  : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 1. Cidade
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 25,
                            bottom: 35,
                          ),
                          child: Text(
                            cityName ?? "Localização...",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w600,
                              color: Color.fromARGB(210, 255, 255, 255),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // 2. GIF (animação)
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
                        // 3. Temperatura
                        Text(
                          '${temperature?.round() ?? '--'}ºC',
                          style: const TextStyle(
                            fontSize: 45,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(200, 255, 255, 255),
                          ),
                        ),
                        Text(
                          weatherText ?? "Clima...",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(200, 255, 255, 255),
                          ),
                        ),
                        // 4. Aviso (headline)
                        if (headlineText != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10, bottom: 16),
                            child: Text(
                              headlineText!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color.fromARGB(220, 255, 255, 86),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        // 5. Previsões próximas (dias e horas)
                        const SizedBox(height: 30),
                        const SizedBox(height: 10),
                        forecastDays.isEmpty && forecastHours.isEmpty
                            ? const Text(
                              "Sem dados de previsão",
                              style: TextStyle(color: Color.fromARGB(200, 255, 255, 255)),
                            )
                            : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Coluna da PREVISÃO POR HORAS (usando forecastHours) - TÍTULO CENTRALIZADO
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Center(
                                        child: Text(
                                          'Próximos Dias',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromARGB(200, 255, 255, 255),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      ...List.generate(5, (index) {
                                        final item =
                                            forecastHours.length > index
                                                ? forecastHours[index]
                                                : '';
                                        // Extrai a parte em negrito (hora) e o restante (descrição)
                                        String boldPart = '';
                                        String rest = item;
                                        // Tenta dividir pelo primeiro espaço ou hífen
                                        final match = RegExp(
                                          r'^([^\s\-]+)[\s\-]+(.*)$',
                                        ).firstMatch(item);
                                        if (match != null) {
                                          boldPart = match.group(1) ?? '';
                                          // Substitui valores numéricos decimais por inteiros arredondados em rest
                                          rest = (match.group(2) ?? '')
                                              .replaceAllMapped(
                                                RegExp(r'(\d+\.\d+)'),
                                                (m) {
                                                  return double.parse(
                                                    m.group(1)!,
                                                  ).round().toString();
                                                },
                                              );
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Container(
                                            height: 48,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white12,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              children: [
                                                Text(
                                                  boldPart,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Color.fromARGB(200, 255, 255, 255),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    rest,
                                                    style: const TextStyle(
                                                      color: Color.fromARGB(200, 255, 255, 255),
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                // Coluna da PREVISÃO POR DIAS (usando forecastDays) - TÍTULO CENTRALIZADO
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Center(
                                        child: Text(
                                          'Próximas Horas',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      ...List.generate(5, (index) {
                                        final item =
                                            forecastDays.length > index
                                                ? forecastDays[index]
                                                : '';
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Container(
                                            height: 48,
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white12,

                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: Text(
                                                item,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Color.fromARGB(200, 255, 255, 255),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        // 6. Dados climáticos (qualidade do ar, umidade, etc.)
                        if (airQuality != null ||
                            uvCategory != null ||
                            averageHumidity != null ||
                            rainProbability != null ||
                            windDirection != null)
                          Column(
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
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        if (averageHumidity != null)
                                          _buildInfoTile(
                                            '🌫️💧',
                                            '$averageHumidity%',
                                          ),
                                        if (rainProbability != null)
                                          _buildInfoTile(
                                            '☔️🤷',
                                            '$rainProbability%',
                                          ),
                                        if (windDirection != null &&
                                            windSpeedValue != null)
                                          _buildInfoTile(
                                            '🌬️',
                                            '$windDirection, ${windSpeedValue!.round()} km/h',
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              // 7. Nascer e pôr do sol (gráfico semicircular)
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
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                              SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                constraints: const BoxConstraints(
                                  minHeight: 200,
                                ),
                                width: double.infinity,
                                height: 200,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    right: 5,
                                    left: 5,
                                    top: 5,
                                    bottom: 50,
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
                          ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white12,
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
    final paint =
        Paint()
          ..color = Colors.white30
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 20;

    // Desenha semicírculo voltado para cima
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, 3.14, 3.14, false, paint);

    // Parse horários de nascer e pôr do sol
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

    // Sol em posição dinâmica ao longo do arco
    final sunPaint = Paint()..color = Colors.amber;
    if (sunriseDateTime != null && sunsetDateTime != null) {
      final now = DateTime.now();
      final totalMinutes = sunsetDateTime.difference(sunriseDateTime).inMinutes;
      final elapsedMinutes = now
          .difference(sunriseDateTime)
          .inMinutes
          .clamp(0, totalMinutes);
      final angle = (elapsedMinutes / totalMinutes) * 3.14;

      final sunX = center.dx + radius * cos(angle + 3.14);
      final sunY = center.dy + radius * sin(angle + 3.14);

      canvas.drawCircle(Offset(sunX, sunY), 8, sunPaint);
    }

    // Marcas de horário ajustadas abaixo das pontas do arco
    final textPainter1 = TextPainter(
      text: TextSpan(
        text: sunriseTime ?? '--:--',
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    final textPainter2 = TextPainter(
      text: TextSpan(
        text: sunsetTime ?? '--:--',
        style: const TextStyle(color: Colors.white, fontSize: 12,fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter1.layout();
    textPainter2.layout();

    textPainter1.paint(canvas, Offset(center.dx - radius - 15, center.dy + 10));
    textPainter2.paint(canvas, Offset(center.dx + radius - 15, center.dy + 10));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
