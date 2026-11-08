import 'dart:async';

/// Holds the newest subscription to a repository stream: starting a new one
/// cancels the old, so a slow, superseded query can never overwrite newer
/// state.
class LatestSubscription<T> {
  StreamSubscription<T>? _subscription;
  Completer<void>? _done;

  /// Subscribes to [stream]. The returned future completes when the stream
  /// ends or is superseded, which is what a pull-to-refresh waits on.
  Future<void> listen(
    Stream<T> stream,
    void Function(T value) onData, {
    required void Function(Object error, StackTrace stack) onError,
  }) {
    cancel();
    final done = _done = Completer<void>();
    _subscription = stream.listen(
      onData,
      onError: onError,
      onDone: () => _complete(done),
    );
    return done.future;
  }

  void cancel() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    if (_done case final done?) _complete(done);
    _done = null;
  }

  static void _complete(Completer<void> done) {
    if (!done.isCompleted) done.complete();
  }
}
