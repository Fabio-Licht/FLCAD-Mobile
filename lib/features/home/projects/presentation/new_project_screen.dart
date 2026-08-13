import 'package:flutter/material.dart';
import '../../../../models/project.dart';
import '../data/project_repository.dart';

class NewProjectScreen extends StatefulWidget {
  const NewProjectScreen({super.key});

  @override
  State<NewProjectScreen> createState() => _NewProjectScreenState();
}

class _NewProjectScreenState extends State<NewProjectScreen> {
  final _nameController = TextEditingController();
  final _clientController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _clientController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Novo Projeto")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Nome do Projeto"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _clientController,
              decoration: const InputDecoration(labelText: "Cliente"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: "Descrição"),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () {
                final name = _nameController.text;
                final client = _clientController.text;
                final description = _descriptionController.text;

                if (name.isEmpty || client.isEmpty || description.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Preencha todos os campos")),
                  );
                  return;
                }

                final newProject = Project(
                  id: DateTime.now().toString(),
                  name: name,
                  client: client,
                  description: description,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  status: ProjectStatus.created,
                );

                ProjectRepository.instance.create(newProject);

                Navigator.pop(context);
              },
              child: const Text("Criar Projeto"),
            ),
          ],
        ),
      ),
    );
  }
}
