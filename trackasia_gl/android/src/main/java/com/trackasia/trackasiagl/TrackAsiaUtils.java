package com.trackasia.trackasiagl;

import android.content.Context;
import com.trackasia.android.TrackAsia;

abstract class TrackAsiaUtils {
  private static final String TAG = "TrackAsiaMapController";

  static TrackAsia getTrackAsia(Context context) {
    return TrackAsia.getInstance(context);
  }
}
