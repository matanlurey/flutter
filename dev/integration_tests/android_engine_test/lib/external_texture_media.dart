import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'src/plugins/draw_noogler_hat.dart';

void main() async {
  enableFlutterDriverExtension();
  WidgetsFlutterBinding.ensureInitialized();
  final int textureId = await DrawNooglerHatPlugin.draw(256, 256);
  runApp(MainApp(textureId: textureId));
}

class MainApp extends StatelessWidget {
  const MainApp({
    required this.textureId,
    super.key,
  });

  final int textureId;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 256,
            height: 256,
            child: Texture(
              textureId: textureId,
              key: const ValueKey<String>('checkerboard'),
            ),
          ),
        ),
      ),
    );
  }
}
