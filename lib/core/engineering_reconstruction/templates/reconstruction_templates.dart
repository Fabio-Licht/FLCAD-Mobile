class ReconstructionTemplate {
  const ReconstructionTemplate(
    this.id,
    this.name,
    this.partKinds,
    this.sequence,
    this.guidance,
  );
  final String id, name, guidance;
  final List<String> partKinds, sequence;
}

class ReconstructionTemplateLibrary {
  const ReconstructionTemplateLibrary();
  static const values = [
    ReconstructionTemplate(
      'flange',
      'Flange',
      ['flange'],
      [
        'base-plane',
        'master-axis',
        'profile-sketch',
        'revolution-plan',
        'hole-pattern',
      ],
      'Priorize datum e padrão circular.',
    ),
    ReconstructionTemplate(
      'shaft',
      'Eixo',
      ['eixo'],
      ['master-axis', 'profile-sketch', 'revolution-plan', 'detail-features'],
      'Preserve coaxialidade.',
    ),
    ReconstructionTemplate(
      'bracket',
      'Suporte',
      ['suporte'],
      ['base-plane', 'mounting-datums', 'sketches', 'feature-plans'],
      'Priorize interfaces de montagem.',
    ),
    ReconstructionTemplate(
      'housing',
      'Carcaça',
      ['carcaça'],
      ['datums', 'critical-bores', 'surface-plans', 'feature-plans'],
      'Modele alojamentos antes de detalhes.',
    ),
    ReconstructionTemplate(
      'sheet',
      'Chapa',
      ['chapa'],
      ['base-plane', 'thickness', 'bend-lines', 'feature-plans'],
      'Planeje espessura e dobras.',
    ),
    ReconstructionTemplate(
      'casting',
      'Fundido',
      ['fundido'],
      ['datums', 'stock-surfaces', 'machined-features', 'fillets-later'],
      'Adie raios de fundição.',
    ),
    ReconstructionTemplate(
      'machined',
      'Peça usinada',
      ['usinado'],
      ['datums', 'primary-features', 'secondary-features', 'inspection'],
      'Maximize referências reutilizadas.',
    ),
    ReconstructionTemplate(
      'mold',
      'Molde',
      ['molde'],
      ['parting-reference', 'draft-analysis', 'surface-plans', 'details'],
      'Priorize partição e extração.',
    ),
    ReconstructionTemplate(
      'automotive',
      'Peça automotiva',
      ['automotiva'],
      [
        'functional-datums',
        'interface-features',
        'surface-plans',
        'validation',
      ],
      'Priorize interfaces funcionais.',
    ),
    ReconstructionTemplate(
      'plastic',
      'Componente plástico',
      ['plástico'],
      ['parting-reference', 'wall-plan', 'rib-plans', 'boss-plans'],
      'Planeje paredes, nervuras e bosses.',
    ),
  ];
  ReconstructionTemplate? select(Iterable<String> kinds) {
    final normalized = kinds.map((e) => e.toLowerCase());
    return values
        .where((t) => t.partKinds.any(normalized.contains))
        .firstOrNull;
  }
}
