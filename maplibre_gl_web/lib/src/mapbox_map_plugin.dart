part of trackasia_gl_web;

class MapboxMapPlugin {
  /// Registers this class as the default instance of [MapboxGlPlatform].
  static void registerWith(Registrar registrar) {
    trackasiaGlPlatform.createInstance = () => trackasiaMapController();
  }
}
