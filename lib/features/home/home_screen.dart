import 'package:flutter/material.dart';

import 'projects/data/project_repository.dart';
import '../../shared/widgets/dashboard_grid.dart';
import '../../shared/widgets/dashboard_header.dart';
import '../../shared/widgets/flcad_bottom_navigation.dart';
import '../../theme/flcad_colors.dart';
import 'projects/data/demo_project.dart';
import 'projects/widgets/project_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final project =
    ProjectRepository.instance.currentProject ?? demoProject;
    return Scaffold(
      backgroundColor: FLCADColors.background,
      bottomNavigationBar: const FLCADBottomNavigation(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DashboardHeader(),

              const SizedBox(height: 24),

              ProjectCard(
                project: project,
              ),

              const SizedBox(height: 28),

              const DashboardGrid(),

              const SizedBox(height: 32),

              const Text(
                "Última atividade",
                style: TextStyle(
                  color: FLCADColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              const Card(
                color: FLCADColors.surface,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "Nenhum projeto aberto.",
                    style: TextStyle(
                      color: FLCADColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}