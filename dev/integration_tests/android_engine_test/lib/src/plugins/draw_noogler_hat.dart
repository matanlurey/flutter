import 'package:flutter/services.dart';

final class DrawNooglerHatPlugin {
  static const MethodChannel _channel = MethodChannel('draw_noogler_hat');

  /// Returns the texture ID of a drawn checkerboard of [width] and [height].
  ///
  /// ## Example
  ///
  /// ```dart
  /// final int textureId = await DrawNooglerHatPlugin.draw(256, 256);
  ///
  /// // ...
  ///
  /// Widget build(BuildContext context) {
  ///   return Texture(textureId: textureId);
  /// }
  /// ```
  static Future<int> draw(int width, int height) async {
    final int? result = await _channel.invokeMethod('draw', <String, Object?>{
      'width': width,
      'height': height,
    });
    if (result == null) {
      throw PlatformException(
        code: 'UNEXPECTED_NULL_RESULT',
        message: "The 'draw' method failed to return a result",
      );
    }
    return result;
  }
}
