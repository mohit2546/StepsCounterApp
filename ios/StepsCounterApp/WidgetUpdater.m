#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(WidgetUpdater, NSObject)

RCT_EXTERN_METHOD(reloadAllWidgets)
RCT_EXTERN_METHOD(reloadStepsWidgets)

+ (BOOL)requiresMainQueueSetup
{
    return NO;
}

@end 