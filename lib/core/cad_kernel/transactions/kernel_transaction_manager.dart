import '../api/geometry_kernel_api.dart';
import '../ids/persistent_id_service.dart';
import '../models/kernel_models.dart';

class KernelTransactionManager {
  KernelTransactionManager(
    this.kernel, {
    PersistentIdService ids = const PersistentIdService(),
  }) : ids = ids;
  final GeometryKernelAPI kernel;
  final PersistentIdService ids;
  final Map<String, KernelTransaction> _transactions = {};
  Future<KernelTransaction> begin(String projectId) async {
    final value = KernelTransaction(
      ids.create(projectId, 'transaction'),
      projectId,
      kernel.descriptor.id,
      DateTime.now(),
      TransactionStatus.active,
      const [],
    );
    _transactions[value.id] = value;
    await kernel.begin(value);
    return value;
  }

  KernelTransaction addOperation(String id, String operationId) {
    final current = _active(id),
        updated = current.copyWith(
          operationIds: [...current.operationIds, operationId],
        );
    _transactions[id] = updated;
    return updated;
  }

  Future<KernelTransaction> commit(String id) async {
    final current = _active(id);
    await kernel.commit(current);
    final value = current.copyWith(status: TransactionStatus.committed);
    _transactions[id] = value;
    return value;
  }

  Future<KernelTransaction> rollback(String id) async {
    final current = _active(id);
    await kernel.rollback(current);
    final value = current.copyWith(status: TransactionStatus.rolledBack);
    _transactions[id] = value;
    return value;
  }

  KernelTransaction _active(String id) {
    final value =
        _transactions[id] ?? (throw StateError('Transaction $id not found'));
    if (value.status != TransactionStatus.active) {
      throw StateError('Transaction $id is ${value.status.name}');
    }
    return value;
  }
}
