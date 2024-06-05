import 'dart:io' as io;

import 'package:flutter_driver/src/experimental/flutter_driver.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() async {
  late FlutterDriver driver;

  setUpAll(() async {
    driver = await FlutterDriver.connect();
  });

  tearDownAll(() async {
    await driver.close();
  });

  late io.Directory tempDir;

  setUp(() async {
    tempDir = await io.Directory.systemTemp.createTemp('flutter_driver');
  });

  tearDown(() async {
    // await tempDir.delete(recursive: true);
  });

  test('should render a checkerboard', () async {
    final SerializableFinder texture = find.byValueKey('checkerboard');
    await driver.waitFor(texture);

    // Wait 2s to "stabilize" the checkerboard.
    await Future<void>.delayed(const Duration(seconds: 2));

    // Use ADB to take a screenshot.
    final io.ProcessResult result = await io.Process.run(
      'adb',
      <String>['shell', 'screencap', '-p', '/sdcard/screenshot.png'],
    );
    if (result.exitCode != 0) {
      fail('Failed to take screenshot: ${result.stderr}');
    }

    // Pull the screenshot from the device to the temp directory.
    final io.ProcessResult pullResult = await io.Process.run(
      'adb',
      <String>['pull', '/sdcard/screenshot.png', tempDir.path],
    );

    if (pullResult.exitCode != 0) {
      fail('Failed to pull screenshot: ${pullResult.stderr}');
    }

    // Verify the screenshot.
    final io.File file = io.File(p.join(tempDir.path, 'screenshot.png'));
    expect(
      file,
      matchesGoldenFile(p.join('test_driver', 'golden', 'checkerboard.png')),
    );
  });
}
