import 'package:trackasia_gl_web/src/interop/style/sources/vector_source_interop.dart';
import 'package:trackasia_gl_web/src/style/sources/source.dart';

class VectorSource extends Source<VectorSourceJsImpl> {
  String? get url => jsObject.url;

  List<String>? get tiles => jsObject.tiles;

  factory VectorSource({
    String? url,
    List<String>? tiles,
  }) {
    if (url != null && tiles != null) {
      throw Exception('Specify only one between url and tiles');
    }
    if (url != null) {
      return VectorSource.fromJsObject(VectorSourceJsImpl(
        type: 'vector',
        url: url,
      ));
    }
    return VectorSource.fromJsObject(VectorSourceJsImpl(
      type: 'vector',
      tiles: tiles,
    ));
  }

  /// Creates a new VectorSource from a [jsObject].
  VectorSource.fromJsObject(super.jsObject) : super.fromJsObject();

  @override
  get dict {
    final dict = <String, dynamic>{
      'type': 'vector',
    };
    if (url != null) {
      dict['url'] = url;
    }
    if (tiles != null) {
      dict['tiles'] = tiles;
    }
    return dict;
  }
}
