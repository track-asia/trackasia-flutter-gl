# Flutter TrackAsia GL Workspace

[![Pub Version](https://img.shields.io/pub/v/trackasia_gl)](https://pub.dev/packages/trackasia_gl)
[![License](https://img.shields.io/badge/license-BSD-blue.svg)](LICENSE)

A Flutter plugin for embedding interactive, highly customizable vector maps powered by TrackAsia Native on Android, iOS, and Web.

## 📦 Packages in this Repository

| Package | Version | Description |
| :--- | :--- | :--- |
| [`trackasia_gl`](trackasia_gl/) | `2.0.4` | Core Flutter plugin for TrackAsia maps |
| [`trackasia_gl_platform_interface`](trackasia_gl_platform_interface/) | `2.0.2` | Common platform interface |
| [`trackasia_gl_web`](trackasia_gl_web/) | `2.0.1` | Web implementation using TrackAsia GL JS |
| [`trackasia_gl_example`](trackasia_gl_example/) | - | Example Flutter test app |

## 🚀 Quick Start

Add `trackasia_gl` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  trackasia_gl: ^2.0.4
```

### Basic Map Widget

```dart
import 'package:flutter/material.dart';
import 'package:trackasia_gl/trackasia_gl.dart';

class MapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TrackasiaMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(10.728073, 106.624054), // Ho Chi Minh City
          zoom: 12.0,
        ),
        styleString: "https://maps.track-asia.com/styles/v2/streets.json?key=public",
        onMapCreated: (TrackasiaMapController controller) {
          // Map ready
        },
      ),
    );
  }
}
```

## 📱 Platform Requirements

- **Flutter**: >= 3.22.0 (khuyến nghị Flutter 3.24+)
- **Android**: `minSdkVersion 26`, `compileSdkVersion 35`, Android NDK `27.0.12077973`
- **iOS**: iOS 14.0+ (deployment target)

## 📚 Full Documentation & Showcase Demo

For full integration guides, turn-by-turn navigation, geocoding autocomplete, clustering, and 5-country multi-style support:
👉 **[TrackAsia Flutter Document & Demo App](https://github.com/track-asia/trackasia-flutter-document)**
