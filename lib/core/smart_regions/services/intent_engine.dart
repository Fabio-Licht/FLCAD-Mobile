import '../models/smart_region.dart';

class EngineeringIntent {
  const EngineeringIntent(
    this.id,
    this.title,
    this.reason,
    this.confidence,
    this.action,
  );
  final String id, title, reason, action;
  final double confidence;
}

class IntentEngine {
  final Map<String, int> _patterns = {};
  List<EngineeringIntent> infer(
    SmartRegion region, {
    List<String> recentOperations = const [],
  }) {
    final result = <EngineeringIntent>[];
    final type = region.statistics.dominantType;
    if (type == 'plane') {
      result.add(
        const EngineeringIntent(
          'reference_plane',
          'Criar plano de referência',
          'A região é predominantemente plana',
          .82,
          'create_plane',
        ),
      );
    }
    if (type == 'cylinder_or_cone') {
      result.add(
        const EngineeringIntent(
          'axis_dimension',
          'Gerar eixo e diâmetro',
          'A distribuição de normais sugere geometria axial',
          .68,
          'create_axis',
        ),
      );
    }
    if (type == 'organic') {
      result.add(
        const EngineeringIntent(
          'guide_curve',
          'Criar curva guia',
          'A borda possui variação orgânica',
          .61,
          'create_guide_curve',
        ),
      );
    }
    for (final operation in recentOperations) {
      _patterns[operation] = (_patterns[operation] ?? 0) + 1;
    }
    if ((_patterns['shrink_before_surface'] ?? 0) >= 3) {
      result.add(
        const EngineeringIntent(
          'learned_shrink',
          'Aplicar Border Shrink',
          'Este fluxo foi repetido antes de criar superfícies',
          .75,
          'border_shrink',
        ),
      );
    }
    return result;
  }
}
