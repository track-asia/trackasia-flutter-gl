package com.trackasia.trackasiagl;

import android.content.Context;
import com.trackasia.android.Trackasia;

abstract class MapBoxUtils {
  private static final String TAG = "TrackasiaMapController";

  static Trackasia getMapbox(Context context) {
    return Trackasia.getInstance(context);
  }
}
