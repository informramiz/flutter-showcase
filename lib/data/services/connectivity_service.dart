import 'package:connectivity_plus/connectivity_plus.dart';

/// Service: wraps `connectivity_plus` behind a plain boolean stream.
class ConnectivityService {
  ConnectivityService([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Emits the current state first, then every change. `true` while the
  /// device has some network interface.
  Stream<bool> onlineChanges() async* {
    yield _isOnline(await _connectivity.checkConnectivity());
    yield* _connectivity.onConnectivityChanged.map(_isOnline);
  }

  static bool _isOnline(List<ConnectivityResult> results) =>
      !results.contains(ConnectivityResult.none);
}
