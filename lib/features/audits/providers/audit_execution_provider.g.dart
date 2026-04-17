// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_execution_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$auditQuestionsNotifierHash() =>
    r'b0054fb5d6ace5b9ca3577154bef6de1135fed91';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$AuditQuestionsNotifier
    extends BuildlessAutoDisposeStreamNotifier<List<AuditQuestion>> {
  late final String auditPlanId;

  Stream<List<AuditQuestion>> build(String auditPlanId);
}

/// See also [AuditQuestionsNotifier].
@ProviderFor(AuditQuestionsNotifier)
const auditQuestionsNotifierProvider = AuditQuestionsNotifierFamily();

/// See also [AuditQuestionsNotifier].
class AuditQuestionsNotifierFamily
    extends Family<AsyncValue<List<AuditQuestion>>> {
  /// See also [AuditQuestionsNotifier].
  const AuditQuestionsNotifierFamily();

  /// See also [AuditQuestionsNotifier].
  AuditQuestionsNotifierProvider call(String auditPlanId) {
    return AuditQuestionsNotifierProvider(auditPlanId);
  }

  @override
  AuditQuestionsNotifierProvider getProviderOverride(
    covariant AuditQuestionsNotifierProvider provider,
  ) {
    return call(provider.auditPlanId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'auditQuestionsNotifierProvider';
}

/// See also [AuditQuestionsNotifier].
class AuditQuestionsNotifierProvider
    extends
        AutoDisposeStreamNotifierProviderImpl<
          AuditQuestionsNotifier,
          List<AuditQuestion>
        > {
  /// See also [AuditQuestionsNotifier].
  AuditQuestionsNotifierProvider(String auditPlanId)
    : this._internal(
        () => AuditQuestionsNotifier()..auditPlanId = auditPlanId,
        from: auditQuestionsNotifierProvider,
        name: r'auditQuestionsNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$auditQuestionsNotifierHash,
        dependencies: AuditQuestionsNotifierFamily._dependencies,
        allTransitiveDependencies:
            AuditQuestionsNotifierFamily._allTransitiveDependencies,
        auditPlanId: auditPlanId,
      );

  AuditQuestionsNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.auditPlanId,
  }) : super.internal();

  final String auditPlanId;

  @override
  Stream<List<AuditQuestion>> runNotifierBuild(
    covariant AuditQuestionsNotifier notifier,
  ) {
    return notifier.build(auditPlanId);
  }

  @override
  Override overrideWith(AuditQuestionsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: AuditQuestionsNotifierProvider._internal(
        () => create()..auditPlanId = auditPlanId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        auditPlanId: auditPlanId,
      ),
    );
  }

  @override
  AutoDisposeStreamNotifierProviderElement<
    AuditQuestionsNotifier,
    List<AuditQuestion>
  >
  createElement() {
    return _AuditQuestionsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AuditQuestionsNotifierProvider &&
        other.auditPlanId == auditPlanId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, auditPlanId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AuditQuestionsNotifierRef
    on AutoDisposeStreamNotifierProviderRef<List<AuditQuestion>> {
  /// The parameter `auditPlanId` of this provider.
  String get auditPlanId;
}

class _AuditQuestionsNotifierProviderElement
    extends
        AutoDisposeStreamNotifierProviderElement<
          AuditQuestionsNotifier,
          List<AuditQuestion>
        >
    with AuditQuestionsNotifierRef {
  _AuditQuestionsNotifierProviderElement(super.provider);

  @override
  String get auditPlanId =>
      (origin as AuditQuestionsNotifierProvider).auditPlanId;
}

String _$auditResponsesNotifierHash() =>
    r'4692e7ad3e8ca3e2e52e59ce467ac1cef8a00588';

abstract class _$AuditResponsesNotifier
    extends BuildlessAutoDisposeStreamNotifier<List<AuditResponse>> {
  late final String auditPlanId;

  Stream<List<AuditResponse>> build(String auditPlanId);
}

/// See also [AuditResponsesNotifier].
@ProviderFor(AuditResponsesNotifier)
const auditResponsesNotifierProvider = AuditResponsesNotifierFamily();

/// See also [AuditResponsesNotifier].
class AuditResponsesNotifierFamily
    extends Family<AsyncValue<List<AuditResponse>>> {
  /// See also [AuditResponsesNotifier].
  const AuditResponsesNotifierFamily();

  /// See also [AuditResponsesNotifier].
  AuditResponsesNotifierProvider call(String auditPlanId) {
    return AuditResponsesNotifierProvider(auditPlanId);
  }

  @override
  AuditResponsesNotifierProvider getProviderOverride(
    covariant AuditResponsesNotifierProvider provider,
  ) {
    return call(provider.auditPlanId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'auditResponsesNotifierProvider';
}

/// See also [AuditResponsesNotifier].
class AuditResponsesNotifierProvider
    extends
        AutoDisposeStreamNotifierProviderImpl<
          AuditResponsesNotifier,
          List<AuditResponse>
        > {
  /// See also [AuditResponsesNotifier].
  AuditResponsesNotifierProvider(String auditPlanId)
    : this._internal(
        () => AuditResponsesNotifier()..auditPlanId = auditPlanId,
        from: auditResponsesNotifierProvider,
        name: r'auditResponsesNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$auditResponsesNotifierHash,
        dependencies: AuditResponsesNotifierFamily._dependencies,
        allTransitiveDependencies:
            AuditResponsesNotifierFamily._allTransitiveDependencies,
        auditPlanId: auditPlanId,
      );

  AuditResponsesNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.auditPlanId,
  }) : super.internal();

  final String auditPlanId;

  @override
  Stream<List<AuditResponse>> runNotifierBuild(
    covariant AuditResponsesNotifier notifier,
  ) {
    return notifier.build(auditPlanId);
  }

  @override
  Override overrideWith(AuditResponsesNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: AuditResponsesNotifierProvider._internal(
        () => create()..auditPlanId = auditPlanId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        auditPlanId: auditPlanId,
      ),
    );
  }

  @override
  AutoDisposeStreamNotifierProviderElement<
    AuditResponsesNotifier,
    List<AuditResponse>
  >
  createElement() {
    return _AuditResponsesNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AuditResponsesNotifierProvider &&
        other.auditPlanId == auditPlanId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, auditPlanId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AuditResponsesNotifierRef
    on AutoDisposeStreamNotifierProviderRef<List<AuditResponse>> {
  /// The parameter `auditPlanId` of this provider.
  String get auditPlanId;
}

class _AuditResponsesNotifierProviderElement
    extends
        AutoDisposeStreamNotifierProviderElement<
          AuditResponsesNotifier,
          List<AuditResponse>
        >
    with AuditResponsesNotifierRef {
  _AuditResponsesNotifierProviderElement(super.provider);

  @override
  String get auditPlanId =>
      (origin as AuditResponsesNotifierProvider).auditPlanId;
}

String _$actionPlansNotifierHash() =>
    r'b959c4c9e52ae5cc70cedcbdefb7af51ed29059e';

abstract class _$ActionPlansNotifier
    extends BuildlessAutoDisposeStreamNotifier<List<ActionPlan>> {
  late final String auditPlanId;

  Stream<List<ActionPlan>> build(String auditPlanId);
}

/// See also [ActionPlansNotifier].
@ProviderFor(ActionPlansNotifier)
const actionPlansNotifierProvider = ActionPlansNotifierFamily();

/// See also [ActionPlansNotifier].
class ActionPlansNotifierFamily extends Family<AsyncValue<List<ActionPlan>>> {
  /// See also [ActionPlansNotifier].
  const ActionPlansNotifierFamily();

  /// See also [ActionPlansNotifier].
  ActionPlansNotifierProvider call(String auditPlanId) {
    return ActionPlansNotifierProvider(auditPlanId);
  }

  @override
  ActionPlansNotifierProvider getProviderOverride(
    covariant ActionPlansNotifierProvider provider,
  ) {
    return call(provider.auditPlanId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'actionPlansNotifierProvider';
}

/// See also [ActionPlansNotifier].
class ActionPlansNotifierProvider
    extends
        AutoDisposeStreamNotifierProviderImpl<
          ActionPlansNotifier,
          List<ActionPlan>
        > {
  /// See also [ActionPlansNotifier].
  ActionPlansNotifierProvider(String auditPlanId)
    : this._internal(
        () => ActionPlansNotifier()..auditPlanId = auditPlanId,
        from: actionPlansNotifierProvider,
        name: r'actionPlansNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$actionPlansNotifierHash,
        dependencies: ActionPlansNotifierFamily._dependencies,
        allTransitiveDependencies:
            ActionPlansNotifierFamily._allTransitiveDependencies,
        auditPlanId: auditPlanId,
      );

  ActionPlansNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.auditPlanId,
  }) : super.internal();

  final String auditPlanId;

  @override
  Stream<List<ActionPlan>> runNotifierBuild(
    covariant ActionPlansNotifier notifier,
  ) {
    return notifier.build(auditPlanId);
  }

  @override
  Override overrideWith(ActionPlansNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: ActionPlansNotifierProvider._internal(
        () => create()..auditPlanId = auditPlanId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        auditPlanId: auditPlanId,
      ),
    );
  }

  @override
  AutoDisposeStreamNotifierProviderElement<
    ActionPlansNotifier,
    List<ActionPlan>
  >
  createElement() {
    return _ActionPlansNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ActionPlansNotifierProvider &&
        other.auditPlanId == auditPlanId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, auditPlanId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ActionPlansNotifierRef
    on AutoDisposeStreamNotifierProviderRef<List<ActionPlan>> {
  /// The parameter `auditPlanId` of this provider.
  String get auditPlanId;
}

class _ActionPlansNotifierProviderElement
    extends
        AutoDisposeStreamNotifierProviderElement<
          ActionPlansNotifier,
          List<ActionPlan>
        >
    with ActionPlansNotifierRef {
  _ActionPlansNotifierProviderElement(super.provider);

  @override
  String get auditPlanId => (origin as ActionPlansNotifierProvider).auditPlanId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
