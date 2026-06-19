import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final String username;

  const HomeScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EnRuta'),
      ),
      body: Center(
        child: Text('Bienvenido, $username'),
      ),
    );
  }
}
