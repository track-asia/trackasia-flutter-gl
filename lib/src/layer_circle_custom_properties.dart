part of trackasia_gl;

abstract class LayerProperties {
  Map<String, dynamic> toJson();
}

class CircleLayerCustomProperties implements LayerProperties {
  // Paint Properties
  /// Circle radius.
  ///
  /// Type: number
  ///   default: 5
  ///   minimum: 0
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic circleRadius;

  /// The fill color of the circle.
  ///
  /// Type: color
  ///   default: #000000
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic circleColor;

  /// Amount to blur the circle. 1 blurs the circle such that only the
  /// centerpoint is full opacity.
  ///
  /// Type: number
  ///   default: 0
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic circleBlur;

  /// The opacity at which the circle will be drawn.
  ///
  /// Type: number
  ///   default: 1
  ///   minimum: 0
  ///   maximum: 1
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic circleOpacity;

  /// The geometry's offset. Values are [x, y] where negatives indicate left
  /// and up, respectively.
  ///
  /// Type: array
  ///   default: [0, 0]
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic circleTranslate;

  /// Controls the frame of reference for `circle-translate`.
  ///
  /// Type: enum
  ///   default: map
  /// Options:
  ///   "map"
  ///      The circle is translated relative to the map.
  ///   "viewport"
  ///      The circle is translated relative to the viewport.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic circleTranslateAnchor;

  /// Controls the scaling behavior of the circle when the map is pitched.
  ///
  /// Type: enum
  ///   default: map
  /// Options:
  ///   "map"
  ///      Circles are scaled according to their apparent distance to the
  ///      camera.
  ///   "viewport"
  ///      Circles are not scaled.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic circlePitchScale;

  /// Orientation of circle when map is pitched.
  ///
  /// Type: enum
  ///   default: viewport
  /// Options:
  ///   "map"
  ///      The circle is aligned to the plane of the map.
  ///   "viewport"
  ///      The circle is aligned to the plane of the viewport.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic circlePitchAlignment;

  /// The width of the circle's stroke. Strokes are placed outside of the
  /// `circle-radius`.
  ///
  /// Type: number
  ///   default: 0
  ///   minimum: 0
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic circleStrokeWidth;

  /// The stroke color of the circle.
  ///
  /// Type: color
  ///   default: #000000
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic circleStrokeColor;

  /// The opacity of the circle's stroke.
  ///
  /// Type: number
  ///   default: 1
  ///   minimum: 0
  ///   maximum: 1
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  ///   data-driven styling with js, android, ios, macos
  final dynamic circleStrokeOpacity;

  // Layout Properties
  /// Sorts features in ascending order based on this value. Features with a
  /// higher sort key will appear above features with a lower sort key.
  ///
  /// Type: number
  ///
  /// Sdk Support:
  ///   basic functionality with js
  ///   data-driven styling with js
  final dynamic circleSortKey;

  /// Whether this layer is displayed.
  ///
  /// Type: enum
  ///   default: visible
  /// Options:
  ///   "visible"
  ///      The layer is shown.
  ///   "none"
  ///      The layer is not shown.
  ///
  /// Sdk Support:
  ///   basic functionality with js, android, ios, macos
  final dynamic visibility;

  const CircleLayerCustomProperties({
    this.circleRadius,
    this.circleColor,
    this.circleBlur,
    this.circleOpacity,
    this.circleTranslate,
    this.circleTranslateAnchor,
    this.circlePitchScale,
    this.circlePitchAlignment,
    this.circleStrokeWidth,
    this.circleStrokeColor,
    this.circleStrokeOpacity,
    this.circleSortKey,
    this.visibility,
  });

  CircleLayerCustomProperties copyWith(CircleLayerCustomProperties changes) {
    return CircleLayerCustomProperties(
      circleRadius: changes.circleRadius ?? circleRadius,
      circleColor: changes.circleColor ?? circleColor,
      circleBlur: changes.circleBlur ?? circleBlur,
      circleOpacity: changes.circleOpacity ?? circleOpacity,
      circleTranslate: changes.circleTranslate ?? circleTranslate,
      circleTranslateAnchor:
          changes.circleTranslateAnchor ?? circleTranslateAnchor,
      circlePitchScale: changes.circlePitchScale ?? circlePitchScale,
      circlePitchAlignment:
          changes.circlePitchAlignment ?? circlePitchAlignment,
      circleStrokeWidth: changes.circleStrokeWidth ?? circleStrokeWidth,
      circleStrokeColor: changes.circleStrokeColor ?? circleStrokeColor,
      circleStrokeOpacity: changes.circleStrokeOpacity ?? circleStrokeOpacity,
      circleSortKey: changes.circleSortKey ?? circleSortKey,
      visibility: changes.visibility ?? visibility,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    void addIfPresent(String fieldName, dynamic value) {
      if (value != null) {
        json[fieldName] = value;
      }
    }

    addIfPresent('circle-radius', circleRadius);
    addIfPresent('circle-color', circleColor);
    addIfPresent('circle-blur', circleBlur);
    addIfPresent('circle-opacity', circleOpacity);
    addIfPresent('circle-translate', circleTranslate);
    addIfPresent('circle-translate-anchor', circleTranslateAnchor);
    addIfPresent('circle-pitch-scale', circlePitchScale);
    addIfPresent('circle-pitch-alignment', circlePitchAlignment);
    addIfPresent('circle-stroke-width', circleStrokeWidth);
    addIfPresent('circle-stroke-color', circleStrokeColor);
    addIfPresent('circle-stroke-opacity', circleStrokeOpacity);
    addIfPresent('circle-sort-key', circleSortKey);
    addIfPresent('visibility', visibility);
    return json;
  }

  factory CircleLayerCustomProperties.fromJson(Map<String, dynamic> json) {
    return CircleLayerCustomProperties(
      circleRadius: json['circle-radius'],
      circleColor: json['circle-color'],
      circleBlur: json['circle-blur'],
      circleOpacity: json['circle-opacity'],
      circleTranslate: json['circle-translate'],
      circleTranslateAnchor: json['circle-translate-anchor'],
      circlePitchScale: json['circle-pitch-scale'],
      circlePitchAlignment: json['circle-pitch-alignment'],
      circleStrokeWidth: json['circle-stroke-width'],
      circleStrokeColor: json['circle-stroke-color'],
      circleStrokeOpacity: json['circle-stroke-opacity'],
      circleSortKey: json['circle-sort-key'],
      visibility: json['visibility'],
    );
  }
}