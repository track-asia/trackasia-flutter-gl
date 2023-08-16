import 'package:flutter/services.dart';
import 'package:trackasia_gl/trackasia_gl.dart';

/// Adds an asset image to the currently displayed style
Future<void> addImageFromAsset(TrackasiaMapController controller, String name, String assetName) async {
  final ByteData bytes = await rootBundle.load(assetName);
  final Uint8List list = bytes.buffer.asUint8List();
  return controller.addImage(name, list);
}
