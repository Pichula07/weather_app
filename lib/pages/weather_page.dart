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

      setState(() {
        cityName = nomeLocal;
        weatherText = current['text'] as String?;
        temperature = current['temp'] as double?;
        weatherIconPhrase = current['icon'] as String?;
        forecastHours = futureForecast.take(5).toList();
        forecastDays = futureForecast.skip(5).take(5).toList();
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF58839E), Color(0xFF061E2A)],
          ),
        ),
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
                        Text(
                          cityName ?? "Localização...",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 25,
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
                          controller: _lottieController,
                          onLoaded: (composition) {
                            _lottieController
                              ..duration = composition.duration * 1.75
                              ..repeat();
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          weatherText ?? "Clima...",
                          style: const TextStyle(
                            fontSize: 15,
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
                        const SizedBox(height: 10),
                        forecastDays.isEmpty && forecastHours.isEmpty
                            ? const Text(
                              "Sem dados de previsão",
                              style: TextStyle(color: Colors.white),
                            )
                            : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                        final item = forecastDays.length > index ? forecastDays[index] : '';
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Container(
                                            height: 48,
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white12,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: Text(
                                                item,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
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
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      ...List.generate(5, (index) {
                                        final item = forecastHours.length > index ? forecastHours[index] : '';
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Container(
                                            height: 48,
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white12,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: Text(
                                                item,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(color: Colors.white),
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
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}
