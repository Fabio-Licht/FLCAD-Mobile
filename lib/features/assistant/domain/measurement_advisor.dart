class MeasurementRequest {
  const MeasurementRequest({
    required this.name,
    required this.reason,
    required this.priority,
  });
  final String name;
  final String reason;
  final int priority;
}

class MeasurementAdvisor {
  const MeasurementAdvisor();
  List<MeasurementRequest> decide({
    required String scaleMethod,
    required double confidence,
    required double coverage,
  }) {
    if (scaleMethod != 'measurements') return const [];
    final requests = <MeasurementRequest>[
      const MeasurementRequest(
        name: 'Comprimento de referência',
        reason: 'Define a escala global',
        priority: 1,
      ),
    ];
    if (confidence < .65) {
      requests.add(
        const MeasurementRequest(
          name: 'Segunda dimensão independente',
          reason: 'Valida a escala estimada',
          priority: 2,
        ),
      );
    }
    if (coverage < 50) {
      requests.add(
        const MeasurementRequest(
          name: 'Dimensão da região oculta',
          reason: 'Compensa cobertura insuficiente',
          priority: 3,
        ),
      );
    }
    return requests;
  }
}
