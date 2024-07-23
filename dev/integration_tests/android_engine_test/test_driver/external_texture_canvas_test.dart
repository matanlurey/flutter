import 'dart:io' as io;

import 'package:flutter_driver/src/experimental/flutter_driver.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() async {
  late final FlutterDriver driver;

  setUpAll(() async {
    driver = await FlutterDriver.connect();

    // Enter immersive mode to hide the system UI.
    {
      final io.ProcessResult result = await io.Process.run(
      'adb',
      <String>[
        'shell',
        'settings',
        'put',
        'global',
        'sysui_demo_allowed',
        '1'
      ],
    );

      if (result.exitCode != 0) {
        fail('Failed to enter immersive mode: ${result.stderr}');
      }

      // Hide all notification icons.
      final io.ProcessResult hideIconsResult = await io.Process.run(
        'adb',
        <String>[
          'shell',
          'cmd',
          'statusbar',
          'icon',
          'disable',
        ],
      );

      if (hideIconsResult.exitCode != 0) {
        fail('Failed to hide notification icons: ${hideIconsResult.stderr}');
      }

      // Hide the status bar.
      final io.ProcessResult hideStatusBarResult = await io.Process.run(
        'adb',
        <String>[
          'shell',
          'cmd',
          'statusbar',
          'disable',
        ],
      );

      if (hideStatusBarResult.exitCode != 0) {
        fail('Failed to hide the status bar: ${hideStatusBarResult.stderr}');
      }

      // Set the clock to 13:37.
      final io.ProcessResult setClockResult = await io.Process.run(
        'adb',
        <String>[
          'shell',
          'am',
          'broadcast',
          '-a',
          'com.android.systemui.demo',
          '-e',
          'command',
          'clock',
          '13:37',
        ],
      );

      if (setClockResult.exitCode != 0) {
        fail('Failed to set the clock: ${setClockResult.stderr}');
      }
    }

    // Disable animations to make the test more stable.
    await Future.wait(const <String>[
      'animator_duration_scale',
      'transition_animation_scale',
      'window_animation_scale',
    ].map((String key) async {
      final io.ProcessResult result = await io.Process.run(
        'adb',
        <String>[
          'shell',
          'settings',
          'put',
          'global',
          key,
          '0.0',
        ],
      );

      if (result.exitCode != 0) {
        fail('Failed to disable animations: ${result.stderr}');
      }
    }));

    await driver.waitUntilFirstFrameRasterized();
  });

  tearDownAll(() async {
    await driver.close();
  });

  late io.Directory tempDir;

  setUp(() async {
    tempDir = await io.Directory.systemTemp.createTemp('flutter_driver');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('should render a checkerboard', () async {
    final SerializableFinder texture = find.byValueKey('checkerboard');
    await driver.waitFor(texture);

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

  test('should stay rendered after background/resume', () async {
    final SerializableFinder texture = find.byValueKey('checkerboard');
    await driver.waitFor(texture);

    // Simulate home button press.
    final io.ProcessResult result = await io.Process.run(
      'adb',
      <String>['shell', 'input', 'keyevent', 'KEYCODE_HOME'],
    );

    if (result.exitCode != 0) {
      fail('Failed to simulate home button press: ${result.stderr}');
    }

    // Wait 2s. Ideally there would be a better way to wait for this;
    // perhaps something like polling until the app is in the background.
    await Future<void>.delayed(const Duration(seconds: 2));

    // Force a trim memory.
    final io.ProcessResult trimResult = await io.Process.run(
      'adb',
      <String>[
        'shell',
        'am',
        'send-trim-memory',
        'com.example.android_engine_test',
        'MODERATE',
      ],
    );

    if (trimResult.exitCode != 0) {
      fail('Failed to force a trim memory: ${trimResult.stderr}');
    }

    // Switch back to the app (com.example.android_engine_test/.MainActivity).
    final io.ProcessResult resumeResult = await io.Process.run(
      'adb',
      <String>[
        'shell',
        'am',
        'start',
        '-n',
        'com.example.android_engine_test/.MainActivity',
      ],
    );

    if (resumeResult.exitCode != 0) {
      fail('Failed to resume the app: ${resumeResult.stderr}');
    }

    // Verify the checkerboard is still rendered.
    await driver.waitFor(texture);

    // Use ADB to take a screenshot.
    await Future<void>.delayed(const Duration(seconds: 1));
    final io.ProcessResult screenshotResult = await io.Process.run(
      'adb',
      <String>['shell', 'screencap', '-p', '/sdcard/screenshot.png'],
    );

    if (screenshotResult.exitCode != 0) {
      fail('Failed to take screenshot: ${screenshotResult.stderr}');
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
      matchesGoldenFile(
        p.join(
          'test_driver',
          'golden',
          'checkerboard-after-resume.png',
        ),
      ),
    );
  });
}
