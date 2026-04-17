// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$auditPlansNotifierHash() =>
    r'6642c84ce1b3eb817bc8b3ad3a0dd82f3fd60d25';

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

abstract class _$AuditPlansNotifier
    extends BuildlessAutoDisposeStreamNotifier<List<AuditPlan>> {
  late final String? statusFilter;

  Stream<List<AuditPlan>> build({String? statusFilter});
}

/// See also [AuditPlansNotifier].
@ProviderFor(AuditPlansNotifier)
const auditPlansNotifierProvider = AuditPlansNotifierFamily();

/// See also [AuditPlansNotifier].
class AuditPlansNotifierFamily extends Family<AsyncValue<List<AuditPlan>>> {
  /// See also [AuditPlansNotifier].
  const AuditPlansNotifierFamily();

  /// See also [AuditPlansNotifier].
  AuditPlansNotifierProvider call({String? statusFilter}) {
    return AuditPlansNotifierProvider(statusFilter: statusFilter);
  }

  @override
  AuditPlansNotifierProvider getProviderOverride(
    covariant AuditPlansNotifierProvider provider,
  ) {
    return call(statusFilter: provider.statusFilter);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'auditPlansNotifierProvider';
}

/// See also [AuditPlansNotifier].
class AuditPlansNotifierProvider
    extends
        AutoDisposeStreamNotifierProviderImpl<
          AuditPlansNotifier,
          List<AuditPlan>
        > {
  /// See also [AuditPlansNotifier].
  AuditPlansNotifierProvider({String? statusFilter})
    : this._internal(
        () => AuditPlansNotifier()..statusFilter = statusFilter,
        from: auditPlansNotifierProvider,
        name: r'auditPlansNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$auditPlansNotifierHash,
        dependencies: AuditPlansNotifierFamily._dependencies,
        allTransitiveDependencies:
            AuditPlansNotifierFamily._allTransitiveDependencies,
        statusFilter: statusFilter,
      );

  AuditPlansNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.statusFilter,
  }) : super.internal();

  final String? statusFilter;

  @override
  Stream<List<AuditPlan>> runNotifierBuild(
    covariant AuditPlansNotifier notifier,
  ) {
    return notifier.build(statusFilter: statusFilter);
  }

  @override
  Override overrideWith(AuditPlansNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: AuditPlansNotifierProvider._internal(
        () => create()..statusFilter = statusFilter,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        statusFilter: statusFilter,
      ),
    );
  }

  @override
  AutoDisposeStreamNotifierProviderElement<AuditPlansNotifier, List<AuditPlan>>
  createElement() {
    return _AuditPlansNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AuditPlansNotifierProvider &&
        other.statusFilter == statusFilter;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, statusFilter.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AuditPlansNotifierRef
    on AutoDisposeStreamNotifierProviderRef<List<AuditPlan>> {
  /// The parameter `statusFilter` of this provider.
  String? get statusFilter;
}

class _AuditPlansNotifierProviderElement
    extends
        AutoDisposeStreamNotifierProviderElement<
          AuditPlansNotifier,
          List<AuditPlan>
        >
    with AuditPlansNotifierRef {
  _AuditPlansNotifierProviderElement(super.provider);

  @override
  String? get statusFilter =>
      (origin as AuditPlansNotifierProvider).statusFilter;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
