import 'package:flutter_showcase/domain/services/collection_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts a normal name', () {
    expect(validateCollectionName('Quick dinners'), isNull);
  });

  test('rejects blank names', () {
    expect(validateCollectionName('   '), CollectionNameError.empty);
  });

  test('rejects names over the limit after trimming', () {
    expect(
      validateCollectionName(' ${'a' * maxCollectionNameLength} '),
      isNull,
    );
    expect(
      validateCollectionName('a' * (maxCollectionNameLength + 1)),
      CollectionNameError.tooLong,
    );
  });

  test('rejects duplicates case-insensitively', () {
    expect(
      validateCollectionName(' quick DINNERS', existing: ['Quick dinners']),
      CollectionNameError.duplicate,
    );
  });
}
