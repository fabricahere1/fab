// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bekleyen_bildirim_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Cold-start bildirimi — uygulama kapalıyken tıklanan bildirim.
/// HomeScreen açılınca okur ve null'a sıfırlar.

@ProviderFor(BekleyenBildirim)
final bekleyenBildirimProvider = BekleyenBildirimProvider._();

/// Cold-start bildirimi — uygulama kapalıyken tıklanan bildirim.
/// HomeScreen açılınca okur ve null'a sıfırlar.
final class BekleyenBildirimProvider
    extends $NotifierProvider<BekleyenBildirim, RemoteMessage?> {
  /// Cold-start bildirimi — uygulama kapalıyken tıklanan bildirim.
  /// HomeScreen açılınca okur ve null'a sıfırlar.
  BekleyenBildirimProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bekleyenBildirimProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bekleyenBildirimHash();

  @$internal
  @override
  BekleyenBildirim create() => BekleyenBildirim();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RemoteMessage? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RemoteMessage?>(value),
    );
  }
}

String _$bekleyenBildirimHash() => r'd6be358d50d6af072ed829a3b53dabc209725a63';

/// Cold-start bildirimi — uygulama kapalıyken tıklanan bildirim.
/// HomeScreen açılınca okur ve null'a sıfırlar.

abstract class _$BekleyenBildirim extends $Notifier<RemoteMessage?> {
  RemoteMessage? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RemoteMessage?, RemoteMessage?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RemoteMessage?, RemoteMessage?>,
              RemoteMessage?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
