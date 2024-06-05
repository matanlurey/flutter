/// A copy of `flutter_driver.dart` including new experimental APIs.
@experimental
library;

import 'dart:io' as io;
import 'dart:typed_data';

import 'package:matcher/matcher.dart';
// ignore: implementation_imports
import 'package:matcher/src/expect/async_matcher.dart' show AsyncMatcher;
import 'package:meta/meta.dart';
import 'package:test_api/test_api.dart';

export 'package:flutter_driver/flutter_driver.dart';

/// Asserts that a [io.Image] matches a golden file identified by [key].
AsyncMatcher matchesGoldenFile(String key) {
  return _MatchesGoldenFile.forStringPath(key);
}

const String _kUpdateKey = 'FLUTTER_DRIVER_AUTO_UPDATE_GOLDENS';

/// Whether golden files should be automatically updated during tests rather
/// than compared to the image bytes recorded by the tests.
///
/// The Flutter tool will automatically set this to `true` when the user runs
/// `flutter drive --update-goldens`, so callers should generally never have to
/// explicitly modify this value.
bool autoUpdateGoldenFiles = io.Platform.environment[_kUpdateKey] == 'true';

final class _MatchesGoldenFile extends AsyncMatcher {
  _MatchesGoldenFile.forStringPath(String key) : key = Uri.parse(key);

  /// The [key] to the golden image.
  final Uri key;

  @override
  Future<String?> matchAsync(Object? item) async {
    if (item is! io.File) {
      return 'golden file comparison only supports File objects';
    }

    final Uint8List bytes = await item.readAsBytes();
    if (autoUpdateGoldenFiles) {
      try {
        await goldenFileComparator.update(key, bytes);
        return null;
      } catch (ex) {
        return 'failed to update golden file: $ex';
      }
    }

    try {
      final bool success = await goldenFileComparator.compare(bytes, key);
      return success ? null : 'does not match';
    } on TestFailure catch (ex) {
      return ex.message;
    }
  }

  @override
  Description describe(Description description) {
    return description.add('app screenshot image matches golden file "$key"');
  }
}

/// Compares image pixels against a golden image file.
///
/// A partial copy of `GoldenFileComparator` from `flutter_test`; the original
/// library imports `dart:ui` which is not available in this context.
abstract class GoldenFileComparator {
  /// Compares the pixels of decoded png [imageBytes] against the golden file
  /// identified by [golden].
  ///
  /// The returned future completes with a boolean value that indicates whether
  /// the pixels decoded from [imageBytes] match the golden file's pixels.
  ///
  /// The method by which [golden] is located and by which its bytes are loaded
  /// is left up to the implementation class. For instance, some implementations
  /// may load files from the local file system, whereas others may load files
  /// over the network or from a remote repository.
  Future<bool> compare(Uint8List imageBytes, Uri golden);

  /// Updates the golden file identified by [golden] with [imageBytes].
  Future<void> update(Uri golden, Uint8List imageBytes);
}

/// Compares pixels against those of a golden image file.
///
/// A partial copy of `goldenFileComparator` from `flutter_test`; the original
/// library imports `dart:ui` which is not available in this context.
GoldenFileComparator goldenFileComparator = const _ExactLocalFileComparator();

/// Compares for an exact pixel match against a golden file.
final class _ExactLocalFileComparator implements GoldenFileComparator {
  const _ExactLocalFileComparator();

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final io.File goldenFile = io.File.fromUri(golden);
    final Uint8List goldenBytes;

    try {
      goldenBytes = await goldenFile.readAsBytes();
    } on io.PathNotFoundException {
      throw TestFailure('Golden file not found: $golden');
    }

    if (goldenBytes.length != imageBytes.length) {
      return false;
    }

    for (int i = 0; i < goldenBytes.length; i++) {
      if (goldenBytes[i] != imageBytes[i]) {
        return false;
      }
    }

    return true;
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    final io.File goldenFile = io.File.fromUri(golden);

    // Create the directory if it doesn't exist.
    await goldenFile.parent.create(recursive: true);

    await goldenFile.writeAsBytes(imageBytes);
  }
}
