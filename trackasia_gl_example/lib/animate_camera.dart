// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:trackasia_gl/trackasia_gl.dart';

import 'page.dart';

class AnimateCameraPage extends ExamplePage {
  const AnimateCameraPage({super.key})
      : super(const Icon(Icons.map), 'Camera control, animated');

  @override
  Widget build(BuildContext context) {
    return const AnimateCamera();
  }
}

class AnimateCamera extends StatefulWidget {
  const AnimateCamera({super.key});

  @override
  State createState() => AnimateCameraState();
}

class AnimateCameraState extends State<AnimateCamera> {
  late TrackAsiaMapController mapController;

  void _onMapCreated(TrackAsiaMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: SizedBox(
            width: 300.0,
            height: 200.0,
            child: TrackAsiaMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition:
                  const CameraPosition(target: LatLng(0.0, 0.0)),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Column(
              children: <Widget>[
                TextButton(
                  onPressed: () {
                    mapController
                        .animateCamera(
                          CameraUpdate.newCameraPosition(
                            const CameraPosition(
                              bearing: 270.0,
                              target: LatLng(51.5160895, -0.1294527),
                              tilt: 30.0,
                              zoom: 17.0,
                            ),
                          ),
                        )
                        .then(
                          (result) => debugPrint(
                              "mapController.animateCamera() returned $result"),
                        );
                  },
                  child: const Text('newCameraPosition'),
                ),
                TextButton(
                  onPressed: () {
                    mapController
                        .animateCamera(
                          CameraUpdate.newLatLng(
                            const LatLng(56.1725505, 10.1850512),
                          ),
                          duration: const Duration(seconds: 5),
                        )
                        .then((result) => debugPrint(
                            "mapController.animateCamera() returned $result"));
                  },
                  child: const Text('newLatLng'),
                ),
                TextButton(
                  onPressed: () {
                    mapController.animateCamera(
                      CameraUpdate.newLatLngBounds(
                        LatLngBounds(
                          southwest: const LatLng(-38.483935, 113.248673),
                          northeast: const LatLng(-8.982446, 153.823821),
                        ),
                        left: 10,
                        top: 5,
                        bottom: 25,
                      ),
                    );
                  },
                  child: const Text('newLatLngBounds'),
                ),
                TextButton(
                  onPressed: () {
                    mapController.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        const LatLng(37.4231613, -122.087159),
                        11.0,
                      ),
                    );
                  },
                  child: const Text('newLatLngZoom'),
                ),
                TextButton(
                  onPressed: () {
                    mapController.animateCamera(
                      CameraUpdate.scrollBy(150.0, -225.0),
                    );
                  },
                  child: const Text('scrollBy'),
                ),
              ],
            ),
            Column(
              children: <Widget>[
                TextButton(
                  onPressed: () {
                    mapController.animateCamera(
                      CameraUpdate.zoomBy(
                        -0.5,
                        const Offset(30.0, 20.0),
                      ),
                    );
                  },
                  child: const Text('zoomBy with focus'),
                ),
                TextButton(
                  onPressed: () {
                    mapController.animateCamera(
                      CameraUpdate.newLatLngZoom(const LatLng(48, 11), 5),
                      duration: const Duration(milliseconds: 300),
                    );
                  },
                  child: const Text('latlngZoom'),
                ),
                TextButton(
                  onPressed: () {
                    mapController.animateCamera(
                      CameraUpdate.zoomBy(-0.5),
                    );
                  },
                  child: const Text('zoomBy'),
                ),
                TextButton(
                  onPressed: () {
                    mapController.animateCamera(
                      CameraUpdate.zoomIn(),
                    );
                  },
                  child: const Text('zoomIn'),
                ),
                TextButton(
                  onPressed: () {
                    mapController.animateCamera(
                      CameraUpdate.zoomOut(),
                    );
                  },
                  child: const Text('zoomOut'),
                ),
                TextButton(
                  onPressed: () {
                    mapController.animateCamera(
                      CameraUpdate.zoomTo(16.0),
                    );
                  },
                  child: const Text('zoomTo'),
                ),
                TextButton(
                  onPressed: () {
                    mapController.animateCamera(
                      CameraUpdate.bearingTo(45.0),
                    );
                  },
                  child: const Text('bearingTo'),
                ),
                TextButton(
                  onPressed: () {
                    mapController.animateCamera(
                      CameraUpdate.tiltTo(30.0),
                    );
                  },
                  child: const Text('tiltTo'),
                ),
              ],
            ),
          ],
        )
      ],
    );
  }
}
