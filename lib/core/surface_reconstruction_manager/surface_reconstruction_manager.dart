import '../cad_document/cad_document.dart';
import '../feature_lifecycle/feature_lifecycle.dart';
import '../recognition_engine/recognition_result.dart';

enum ReconstructionRegionStatus { reconstructed, inProgress, pending, ignored }

class ReconstructionHistoryEntry {
  const ReconstructionHistoryEntry({
    required this.timestamp,
    required this.status,
    required this.recognitionResultId,
    this.surfaceId,
  });

  final DateTime timestamp;
  final ReconstructionRegionStatus status;
  final String recognitionResultId;
  final String? surfaceId;

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toUtc().toIso8601String(),
    'status': status.name,
    'recognitionResultId': recognitionResultId,
    'surfaceId': surfaceId,
  };

  factory ReconstructionHistoryEntry.fromJson(Map<String, dynamic> json) =>
      ReconstructionHistoryEntry(
        timestamp: DateTime.parse(json['timestamp'] as String),
        status: ReconstructionRegionStatus.values.byName(
          json['status'] as String,
        ),
        recognitionResultId: json['recognitionResultId'] as String,
        surfaceId: json['surfaceId'] as String?,
      );
}

class ReconstructionRegionState {
  const ReconstructionRegionState({
    required this.regionId,
    required this.meshId,
    required this.recognitionResultId,
    required this.area,
    required this.confidence,
    required this.status,
    required this.surfaceIds,
    required this.triangleIndices,
    required this.history,
  });

  final String regionId, meshId, recognitionResultId;
  final double area, confidence;
  final ReconstructionRegionStatus status;
  final List<String> surfaceIds;
  final List<int> triangleIndices;
  final List<ReconstructionHistoryEntry> history;

  String get color => switch (status) {
    ReconstructionRegionStatus.reconstructed => 'green',
    ReconstructionRegionStatus.inProgress => 'yellow',
    ReconstructionRegionStatus.pending => 'red',
    ReconstructionRegionStatus.ignored => 'gray',
  };

  Map<String, dynamic> toJson() => {
    'regionId': regionId,
    'meshId': meshId,
    'recognitionResultId': recognitionResultId,
    'area': area,
    'confidence': confidence,
    'status': status.name,
    'surfaceIds': surfaceIds,
    'triangleIndices': triangleIndices,
    'color': color,
    'history': history.map((item) => item.toJson()).toList(),
  };

  factory ReconstructionRegionState.fromJson(Map<String, dynamic> json) =>
      ReconstructionRegionState(
        regionId: json['regionId'] as String,
        meshId: json['meshId'] as String,
        recognitionResultId: json['recognitionResultId'] as String,
        area: (json['area'] as num).toDouble(),
        confidence: (json['confidence'] as num).toDouble(),
        status: ReconstructionRegionStatus.values.byName(
          json['status'] as String,
        ),
        surfaceIds: (json['surfaceIds'] as List? ?? const []).cast<String>(),
        triangleIndices: (json['triangleIndices'] as List? ?? const [])
            .cast<num>()
            .map((item) => item.toInt())
            .toList(growable: false),
        history: (json['history'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (item) => ReconstructionHistoryEntry.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false),
      );
}

class MeshReconstructionCoverage {
  const MeshReconstructionCoverage({
    required this.meshId,
    required this.totalArea,
    required this.reconstructedArea,
    required this.pendingArea,
    required this.surfaceCount,
    required this.regions,
    required this.nextRegionId,
  });

  final String meshId;
  final double totalArea, reconstructedArea, pendingArea;
  final int surfaceCount;
  final List<ReconstructionRegionState> regions;
  final String? nextRegionId;

  double get reconstructedPercent =>
      totalArea <= 0 ? 0 : reconstructedArea / totalArea * 100;
  double get pendingPercent =>
      totalArea <= 0 ? 0 : pendingArea / totalArea * 100;
  int get pendingRegionCount => regions
      .where(
        (item) =>
            item.status == ReconstructionRegionStatus.pending ||
            item.status == ReconstructionRegionStatus.inProgress,
      )
      .length;

  Map<String, dynamic> toJson() => {
    'meshId': meshId,
    'totalArea': totalArea,
    'reconstructedArea': reconstructedArea,
    'pendingArea': pendingArea,
    'reconstructedPercent': reconstructedPercent,
    'pendingPercent': pendingPercent,
    'surfaceCount': surfaceCount,
    'pendingRegionCount': pendingRegionCount,
    'regions': regions.map((item) => item.toJson()).toList(),
    'nextRegionId': nextRegionId,
  };

  factory MeshReconstructionCoverage.fromJson(Map<String, dynamic> json) =>
      MeshReconstructionCoverage(
        meshId: json['meshId'] as String,
        totalArea: (json['totalArea'] as num).toDouble(),
        reconstructedArea: (json['reconstructedArea'] as num).toDouble(),
        pendingArea: (json['pendingArea'] as num).toDouble(),
        surfaceCount: (json['surfaceCount'] as num).toInt(),
        regions: (json['regions'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (item) => ReconstructionRegionState.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false),
        nextRegionId: json['nextRegionId'] as String?,
      );
}

class SurfaceReconstructionState {
  const SurfaceReconstructionState(this.meshes);
  final List<MeshReconstructionCoverage> meshes;

  Map<String, dynamic> toJson() => {
    'schema': 'flcad.surface-reconstruction-manager',
    'version': 1,
    'meshes': meshes.map((item) => item.toJson()).toList(),
  };

  factory SurfaceReconstructionState.fromJson(Map<String, dynamic> json) {
    if (json['schema'] != 'flcad.surface-reconstruction-manager') {
      throw const FormatException('Unsupported reconstruction manager state.');
    }
    return SurfaceReconstructionState(
      (json['meshes'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => MeshReconstructionCoverage.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false),
    );
  }
}

/// Global, read-only reconstruction observer. It never invokes Recognition,
/// Sketch, Surface, or Solver operations.
class SurfaceReconstructionManager {
  const SurfaceReconstructionManager();

  SurfaceReconstructionState evaluate(
    Iterable<CadDocumentEntity> source, {
    Map<String, ReconstructionRegionStatus> overrides = const {},
    SurfaceReconstructionState? previous,
  }) {
    final entities = {
      for (final entity in source.where((item) => item.data['deleted'] != true))
        entity.id: entity,
    };
    final recognitions = entities.values
        .where((item) => item.kind == CadDocumentEntityKind.recognition)
        .map((entity) {
          final raw = entity.data['recognitionResult'];
          return raw is Map
              ? RecognitionResult.fromJson(Map<String, dynamic>.from(raw))
              : null;
        })
        .whereType<RecognitionResult>()
        .toList(growable: false);
    final surfaces = entities.values
        .where((item) => item.kind == CadDocumentEntityKind.surface)
        .toList(growable: false);
    final previousRegions = <String, ReconstructionRegionState>{
      for (final mesh
          in previous?.meshes ?? const <MeshReconstructionCoverage>[])
        for (final region in mesh.regions) region.recognitionResultId: region,
    };
    final meshIds = {
      ...entities.values
          .where((item) => item.kind == CadDocumentEntityKind.import)
          .map((item) => item.id),
      ...recognitions.map((item) => item.meshId),
    };
    return SurfaceReconstructionState([
      for (final meshId in meshIds)
        _coverage(
          meshId,
          recognitions.where((item) => item.meshId == meshId),
          surfaces,
          entities,
          overrides,
          previousRegions,
        ),
    ]);
  }

  MeshReconstructionCoverage _coverage(
    String meshId,
    Iterable<RecognitionResult> recognitions,
    List<CadDocumentEntity> surfaces,
    Map<String, CadDocumentEntity> entities,
    Map<String, ReconstructionRegionStatus> overrides,
    Map<String, ReconstructionRegionState> previous,
  ) {
    final regions = <ReconstructionRegionState>[];
    for (final recognition in recognitions) {
      final linkedSurfaces = surfaces
          .where(
            (surface) => _ancestry(surface, entities).contains(recognition.id),
          )
          .map((item) => item.id)
          .toList(growable: false);
      final downstream = entities.values.any(
        (entity) =>
            entity.kind != CadDocumentEntityKind.surface &&
            _references(entity).contains(recognition.id),
      );
      final status =
          overrides[recognition.id] ??
          (linkedSurfaces.isNotEmpty
              ? ReconstructionRegionStatus.reconstructed
              : downstream
              ? ReconstructionRegionStatus.inProgress
              : ReconstructionRegionStatus.pending);
      final old = previous[recognition.id];
      final history = <ReconstructionHistoryEntry>[...?old?.history];
      if (old == null ||
          old.status != status ||
          old.surfaceIds.join('|') != linkedSurfaces.join('|')) {
        history.add(
          ReconstructionHistoryEntry(
            timestamp: DateTime.now().toUtc(),
            status: status,
            recognitionResultId: recognition.id,
            surfaceId: linkedSurfaces.firstOrNull,
          ),
        );
      }
      regions.add(
        ReconstructionRegionState(
          regionId: recognition.regionId,
          meshId: meshId,
          recognitionResultId: recognition.id,
          area: (recognition.parameters['area'] as num? ?? 0).toDouble(),
          confidence: recognition.confidence,
          status: status,
          surfaceIds: linkedSurfaces,
          triangleIndices: _triangleIndices(recognition.regionId),
          history: history,
        ),
      );
    }
    final total = regions.fold<double>(0, (sum, item) => sum + item.area);
    final reconstructed = regions
        .where(
          (item) => item.status == ReconstructionRegionStatus.reconstructed,
        )
        .fold<double>(0, (sum, item) => sum + item.area);
    final pending = regions
        .where(
          (item) =>
              item.status == ReconstructionRegionStatus.pending ||
              item.status == ReconstructionRegionStatus.inProgress,
        )
        .fold<double>(0, (sum, item) => sum + item.area);
    final candidates =
        regions
            .where(
              (item) =>
                  item.status == ReconstructionRegionStatus.pending ||
                  item.status == ReconstructionRegionStatus.inProgress,
            )
            .toList()
          ..sort((a, b) {
            final confidence = b.confidence.compareTo(a.confidence);
            return confidence != 0 ? confidence : b.area.compareTo(a.area);
          });
    return MeshReconstructionCoverage(
      meshId: meshId,
      totalArea: total,
      reconstructedArea: reconstructed,
      pendingArea: pending,
      surfaceCount: regions.expand((item) => item.surfaceIds).toSet().length,
      regions: regions,
      nextRegionId: candidates.firstOrNull?.recognitionResultId,
    );
  }

  Set<String> _ancestry(
    CadDocumentEntity root,
    Map<String, CadDocumentEntity> entities,
  ) {
    final result = <String>{}, pending = <String>[root.id];
    while (pending.isNotEmpty) {
      final id = pending.removeLast();
      if (!result.add(id)) continue;
      final entity = entities[id];
      if (entity != null) pending.addAll(_references(entity));
    }
    return result;
  }

  Set<String> _references(CadDocumentEntity entity) {
    final lifecycle = entity.data[FeatureLifecycleContract.dataKey] as Map?;
    return <String>{
      ...(entity.data['references'] as List? ?? const []).whereType<String>(),
      ...(entity.data['sourceEntityIds'] as List? ?? const [])
          .whereType<String>(),
      ...(lifecycle?['references'] as List? ?? const []).whereType<String>(),
      ...(lifecycle?['dependencyIds'] as List? ?? const []).whereType<String>(),
      if (entity.data['parameters'] case final Map parameters) ...[
        if (parameters['sourceRecognitionId'] is String)
          parameters['sourceRecognitionId'] as String,
        ...(parameters['sourceEntityIds'] as List? ?? const [])
            .whereType<String>(),
      ],
    };
  }

  List<int> _triangleIndices(String regionId) {
    final parts = regionId.split(':');
    if (parts.length < 4 || parts.first != 'region') return const [];
    return parts[parts.length - 2]
        .split(',')
        .map(int.tryParse)
        .whereType<int>()
        .toList(growable: false);
  }
}
