import 'package:trackasia_gl_web/src/interop/interop.dart';

class StyleImage extends JsObjectWrapper<StyleImageJsImpl> {
  dynamic get data => jsObject.data;
  num get pixelRatio => jsObject.pixelRatio;
  bool get sdf => jsObject.sdf;
  num get version => jsObject.version;
  bool get hasRenderCallback => jsObject.hasRenderCallback;
  StyleImageInterface get userImage =>
      StyleImageInterface.fromJsObject(jsObject.userImage);

  /// Creates a new EvaluationParameters from a [jsObject].
  StyleImage.fromJsObject(super.jsObject) : super.fromJsObject();
}

class StyleImageInterface extends JsObjectWrapper<StyleImageInterfaceJsImpl> {
  num get width => jsObject.width;
  num get height => jsObject.height;
  dynamic get data => jsObject.data;
  Function get render => jsObject.render;
  Function(TrackAsiaMapJsImpl map, String id) get onAdd =>
      jsObject.onAdd; //TODO: Remove JsImpl
  Function get onRemove => jsObject.onRemove;

  /// Creates a new EvaluationParameters from a [jsObject].
  StyleImageInterface.fromJsObject(super.jsObject) : super.fromJsObject();
}
