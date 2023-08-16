package com.trackasia.trackasiagl;

import android.content.Context;
import com.trackasia.android.camera.CameraPosition;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;
import java.util.Map;

public class TrackasiaMapFactory extends PlatformViewFactory {

  private final BinaryMessenger messenger;
  private final TrackasiaMapsPlugin.LifecycleProvider lifecycleProvider;

  public TrackasiaMapFactory(
      BinaryMessenger messenger, TrackasiaMapsPlugin.LifecycleProvider lifecycleProvider) {
    super(StandardMessageCodec.INSTANCE);
    this.messenger = messenger;
    this.lifecycleProvider = lifecycleProvider;
  }

  @Override
  public PlatformView create(Context context, int id, Object args) {
    Map<String, Object> params = (Map<String, Object>) args;
    final TrackasiaMapBuilder builder = new TrackasiaMapBuilder();

    Convert.interpretTrackasiaMapOptions(params.get("options"), builder, context);
    if (params.containsKey("initialCameraPosition")) {
      CameraPosition position = Convert.toCameraPosition(params.get("initialCameraPosition"));
      builder.setInitialCameraPosition(position);
    }
    if (params.containsKey("dragEnabled")) {
      boolean dragEnabled = Convert.toBoolean(params.get("dragEnabled"));
      builder.setDragEnabled(dragEnabled);
    }
    return builder.build(id, context, messenger, lifecycleProvider);
  }
}
