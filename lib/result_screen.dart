import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final String text;
  const ResultScreen({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(' Metin Tanıma Örneği '),
      ),
      body: Container(
        padding: const EdgeInsets.all(30.0),
        child: SingleChildScrollView(child: Text(text)),
      ),
    );
  }
}
