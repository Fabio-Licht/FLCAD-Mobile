enum ProjectStatus {
  created,
  capturing,
  processing,
  reconstructed,
  exported,
  archived,
}

extension ProjectStatusLabel on ProjectStatus {
  String get label => switch (this) {
    ProjectStatus.created => 'Criado',
    ProjectStatus.capturing => 'Capturando',
    ProjectStatus.processing => 'Processando',
    ProjectStatus.reconstructed => 'Reconstruído',
    ProjectStatus.exported => 'Exportado',
    ProjectStatus.archived => 'Arquivado',
  };
}
