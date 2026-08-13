class EngineeringKernelCapabilities {
  const EngineeringKernelCapabilities(this.values);
  final Set<String> values;
  bool supports(String value) => values.contains(value);
}

abstract interface class EngineeringKernel {
  String get id;
  EngineeringKernelCapabilities get capabilities;
  Future<Object> execute(String operation, Map<String, dynamic> parameters);
}

class NoEngineeringKernel implements EngineeringKernel {
  const NoEngineeringKernel();
  @override
  String get id => 'none';
  @override
  EngineeringKernelCapabilities get capabilities =>
      const EngineeringKernelCapabilities({});
  @override
  Future<Object> execute(String operation, Map<String, dynamic> parameters) =>
      throw UnsupportedError('Engineering kernel not installed: $operation');
}
