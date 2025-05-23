// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// This library contains the TrackAsia GL plugin for Flutter.
///
/// To display a map, add a [TrackAsiaMap] widget to the widget tree.
///
/// In this plugin, the map is configured through the parameters passed to the [TrackAsiaMap] constructor and through the [TrackAsiaMapController].
/// The [TrackAsiaMapController] is provided at runtime by the [TrackAsiaMap.onMapCreated] callback.
/// The controller also allows adding annotations (icons, lines etc.) to the map at runtime and provides some callbacks to get notified when the user clicks those.
///
/// The visual appearance of the map is configured through a TrackAsia style passed to the
/// [styleString] parameter of the [TrackAsiaMap] constructor.
/// The TrackAsia style is a JSON document following the specification at https://track-asia.com/trackasia-style-spec/.
/// The following is supposed to serve as a short introduction to the TrackAsia style specification:
/// The style document contains (among other things) sources and layers.
/// Sources determine which data is displayed on the map, layers determine how the data is displayed.
///
/// Typical types of sources are raster and vector tiles, as well as GeoJson data.
/// For raster and vector tiles, the entire world is divided into a set of tiles in different zoom levels.
/// Depending on the map's zoom level and viewport, the TrackAsia client libraries decide, which tiles are needed to fill the viewport and request them from the source.
///
/// The difference between raster and vector tiles is that raster tiles are images that are pre-rendered on a server, whereas vector tiles contain raw geometric information that is rendered on the client.
/// Vector tiles are in the Mapbox Vector Tile (MVT) format, the de-facto standard for vector tiles that is implemented by multiple libraries.
///
/// Vector tiles have a number of advantages over raster tiles, including (often) smaller size,
/// the possibility to style them dynamically at runtime (e.g. change the color or visibility of certain features),
/// and the possibility to rotate them and keep text labels horizontal.
/// Raster and vector tiles can be generated from a variety of sources, including OpenStreetMap data and are also available from a number of providers.
///
/// Raster sources are displayed by adding a "raster" layer to the TrackAsia GL style.
/// Vector and GeoJson sources are displayed by adding a "line", "fill", "symbol" or "circle" layer to the TrackAsia GL style and specifying
/// which source to use (by setting the "source" property of the layer to the id of the source) as well as how to style the data by setting other properties of the layer such as "line-color" or "fill-outline-color".
/// For example, a vector source layer (or a GeoJson source layer) with the outlines of countries could be displayed both by a fill layer to fill the countries with a color and by a line layer to draw the outlines of the countries.
library trackasia_gl;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:trackasia_gl_platform_interface/trackasia_gl_platform_interface.dart';

export 'package:trackasia_gl_platform_interface/trackasia_gl_platform_interface.dart'
    show
        Annotation,
        ArgumentCallbacks,
        AttributionButtonPosition,
        CameraPosition,
        CameraTargetBounds,
        CameraUpdate,
        Circle,
        CircleOptions,
        CompassViewPosition,
        Fill,
        FillOptions,
        GeojsonSourceProperties,
        ImageSourceProperties,
        LatLng,
        LatLngBounds,
        LatLngQuad,
        Line,
        LineOptions,
        LocationEngineAndroidProperties,
        LocationEnginePlatforms,
        LocationPriority,
        TrackAsiaMethodChannel,
        TrackAsiaPlatform,
        MinMaxZoomPreference,
        MyLocationRenderMode,
        MyLocationTrackingMode,
        OnPlatformViewCreatedCallback,
        RasterDemSourceProperties,
        RasterSourceProperties,
        SourceProperties,
        Symbol,
        SymbolOptions,
        UserHeading,
        UserLocation,
        VectorSourceProperties,
        VideoSourceProperties;

part 'src/controller.dart';

part 'src/trackasia_map.dart';

part 'src/global.dart';

part 'src/offline_region.dart';

part 'src/download_region_status.dart';

part 'src/layer_expressions.dart';

part 'src/layer_properties.dart';

part 'src/color_tools.dart';

part 'src/annotation_manager.dart';

part 'src/util.dart';

part 'src/trackasia_styles.dart';
