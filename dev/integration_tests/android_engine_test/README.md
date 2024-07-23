# Android Engine Test

An experimental fork of the [Android Scenario App][] tested using
`flutter_driver`.

See <https://github.com/flutter/flutter/issues/148028> for more information.

[android scenario app]: https://github.com/flutter/engine/tree/main/testing/scenario_app/android

## Usage

To run a test, assuming you're in `dev/integration_tests/android_engine_test`:

```sh
flutter run <lib/external_texture_canvas.dart>
```

To run the integration tests:

```sh
flutter drive <lib/external_texture_canvas.dart>
```

To update the golden files:

```sh
flutter drive <lib/external_texture_canvas.dart> --update-goldens
```

To run with Impeller enabled:

```sh
flutter drive <lib/external_texture_canvas.dart> --enable-impeller
```

To make it easier to view the end-state, use `--keep-app-running`:

```sh
flutter drive <lib/external_texture_canvas.dart> --keep-app-running
```

Note that the golden files are currently stored in the
[`test_driver/golden`](./test_driver/golden/) directory for simplicity; for a
production release we would use Skia Gold and/or support multiple platforms as
well as multiple configurations similar to `flutter_test`.

## Tests

Where `<lib/main.dart>` is one of the following:

### `lib/external_texture_canvas.dart`

Uses a `Texture` rendered from an Android `Canvas` to render a checkerboard:

<img src="test_driver/golden/checkerboard.png" width="200">

### `lib/external_texture_media.dart`

WIP.

## Limitations

### Platforms

- Only Android is supported, and:
  - The driver script disables animations, and does not reenable them after the
    test is complete.
  - There is no way to force the usage of Surface Textures on >= API 29.

### Screenshots

- The comparator is currently a simple pixel-by-pixel comparison without any
  tolerance or thresholding.
- No suffixes (i.e. "Impeller Enabled") are supported.

## Changes

Changes required to `flutter/flutter` to make this work:

### `flutter_driver`

No changes are made _directly_ to `flutter_driver` so far.

New experimental APIs were added to [`src/experimental/flutter_driver.dart`](../../../packages/flutter_driver/lib/src/experimental/flutter_driver.dart) which added the
following:

- `matchesGoldenFile` and related classes; similar to what exists in `flutter_test`.

### `flutter_tools`

- Added `--update-goldens` flag to `flutter drive` command.
