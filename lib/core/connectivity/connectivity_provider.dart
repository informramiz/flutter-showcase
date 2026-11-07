import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

/// Emits `true` while the device has some network interface.
@riverpod
Stream<bool> isOnline(Ref ref) async* {
  final connectivity = Connectivity();
  bool online(List<ConnectivityResult> r) =>
      !r.contains(ConnectivityResult.none);
  yield online(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(online);
}
