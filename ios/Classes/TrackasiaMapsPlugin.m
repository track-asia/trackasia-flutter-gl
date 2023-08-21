#import "TrackasiaMapsPlugin.h"
#import <trackasia_gl/trackasia_gl-Swift.h>

@implementation TrackasiaMapsPlugin 
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftTrackasiaGlFlutterPlugin registerWithRegistrar:registrar];
}
@end
