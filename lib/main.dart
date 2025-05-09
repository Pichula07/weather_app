import 'package:flutter/material.dart';
import 'package:weather_app/pages/Cidades.dart'; // importa o arquivo com a classe 'Cidades'

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Cidades(), // ✅ agora ok
    );

  }
}
