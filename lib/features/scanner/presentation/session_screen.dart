import 'package:flutter/material.dart';

class SessionScreen extends StatelessWidget {
  const SessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sessões")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Projeto Atual",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Card(
              child: ListTile(
                leading: Icon(Icons.folder),
                title: Text("Motor VW EA888"),
                subtitle: Text("Volkswagen"),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Sessões",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                children: const [
                  ListTile(
                    leading: Icon(Icons.photo_camera),
                    title: Text("Cabeçote Superior"),
                    subtitle: Text("85 fotos"),
                    trailing: Icon(Icons.check_circle, color: Colors.green),
                  ),

                  ListTile(
                    leading: Icon(Icons.photo_camera),
                    title: Text("Bloco"),
                    subtitle: Text("42 fotos"),
                    trailing: Icon(Icons.timelapse, color: Colors.orange),
                  ),
                ],
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {},
                icon: Icon(Icons.add),
                label: Text("Nova Sessão"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
