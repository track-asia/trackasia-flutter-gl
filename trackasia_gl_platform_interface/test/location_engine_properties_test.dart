import 'package:flutter_test/flutter_test.dart';
import 'package:trackasia_gl_platform_interface/trackasia_gl_platform_interface.dart';

void main() {
  group(LocationEnginePlatforms, () {
    test('defaultPlatform.toList() works on all platforms', () {
      expect(LocationEnginePlatforms.defaultPlatform.toList(), isList);
    });
  });
}
