import 'package:flutter/material.dart';
import '../widgets/capture_view.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nova Sessão"),
      ),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: CaptureView(),
      ),
    );
  }
}