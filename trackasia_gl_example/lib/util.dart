import 'package:flutter/services.dart';
import 'package:trackasia_gl/trackasia_gl.dart';

/// Adds an asset image to the currently displayed style
Future<void> addImageFromAsset(
    TrackAsiaMapController controller, String name, String assetName) async {
  final bytes = await rootBundle.load(assetName);
  final list = bytes.buffer.asUint8List();
  return controller.addImage(name, list);
}
