class Weather {
  final String cityName;
  final double temperature;
  final String mainCondition;
  final String icon; 
  final String description;

  Weather({
    required this.cityName,
    required this.temperature,
    required this.mainCondition,
    required this.icon,
    required this.description
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      cityName: json['name'],
      temperature: json['main']['temp'].toDouble(),
      mainCondition: json['weather'][0]['main'],
      icon: json['weather'][0]['icon'], 
      description: json['weather'][0]['description'],
    );
  }
}
