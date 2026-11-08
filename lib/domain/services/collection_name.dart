/// Why a collection name was rejected.
enum CollectionNameError { empty, tooLong, duplicate }

/// Longest collection name, in characters, after trimming.
const maxCollectionNameLength = 40;

/// Validates a collection name typed by the user. Returns `null` when the
/// trimmed [name] is usable. [existing] names are compared case-insensitively.
CollectionNameError? validateCollectionName(
  String name, {
  Iterable<String> existing = const [],
}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return CollectionNameError.empty;
  if (trimmed.length > maxCollectionNameLength) {
    return CollectionNameError.tooLong;
  }
  final lower = trimmed.toLowerCase();
  if (existing.any((e) => e.trim().toLowerCase() == lower)) {
    return CollectionNameError.duplicate;
  }
  return null;
}
