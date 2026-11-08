/// Returns the current time. Injected wherever freshness or scheduling
/// depends on "now", so tests can pin it.
typedef Clock = DateTime Function();
