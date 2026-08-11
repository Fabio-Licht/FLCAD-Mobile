import 'package:flutter/material.dart';

class NewProjectScreen extends StatelessWidget {
  const NewProjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Projeto'),
      ),
      body: const Center(
        child: Text('Tela Novo Projeto'),
      ),
    );
  }
}