import 'package:flutter/material.dart';
import 'package:trackasia_gl/trackasia_gl.dart';

import 'page.dart';

class AttributionPage extends ExamplePage {
  const AttributionPage({super.key})
      : super(const Icon(Icons.thumb_up), 'Attribution');

  @override
  Widget build(BuildContext context) {
    return const AttributionBody();
  }
}

class AttributionBody extends StatefulWidget {
  const AttributionBody({super.key});

  @override
  State<AttributionBody> createState() => _AttributionBodyState();
}

class _AttributionBodyState extends State<AttributionBody> {
  AttributionButtonPosition? attributionButtonPosition;
  bool useDefaultAttributionPosition = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("Set attribution position"),
        Wrap(
          children: [
            buildDefaultPositionButton(),
            buildPositionButton(null),
            buildPositionButton(AttributionButtonPosition.topRight),
            buildPositionButton(AttributionButtonPosition.topLeft),
            buildPositionButton(AttributionButtonPosition.bottomRight),
            buildPositionButton(AttributionButtonPosition.bottomLeft),
          ],
        ),
        Expanded(
          child: buildMap(
            attributionButtonPosition,
            useDefaultAttributionPosition,
          ),
        ),
      ],
    );
  }

  ElevatedButton buildDefaultPositionButton() {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          attributionButtonPosition = null;
          useDefaultAttributionPosition = true;
        });
      },
      child: const Text("Default"),
    );
  }

  ElevatedButton buildPositionButton(AttributionButtonPosition? position) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          attributionButtonPosition = position;
          useDefaultAttributionPosition = false;
        });
      },
      child: Text(position?.name ?? "Null (=platform default)"),
    );
  }

  TrackAsiaMap buildMap(
    AttributionButtonPosition? attributionButtonPosition,
    bool useDefaultAttributionPosition,
  ) {
    if (useDefaultAttributionPosition) {
      return TrackAsiaMap(
        key: UniqueKey(),
        initialCameraPosition: const CameraPosition(
          target: LatLng(-33.852, 151.211),
          zoom: 11.0,
        ),
        styleString: "assets/osm_style.json",
      );
    } else {
      return TrackAsiaMap(
        key: UniqueKey(),
        initialCameraPosition: const CameraPosition(
          target: LatLng(-33.852, 151.211),
          zoom: 11.0,
        ),
        styleString: "assets/osm_style.json",
        attributionButtonPosition: attributionButtonPosition,
      );
    }
  }
}
