#import "SEGFlurryIntegration.h"
#import <Analytics/SEGAnalyticsUtils.h>
#if defined(__has_include) && __has_include(<Flurry_iOS_SDK/Flurry.h>)
#import <Flurry_iOS_SDK/Flurry.h>
#else
#import <Flurry-iOS-SDK/Flurry.h>
#endif

@implementation SEGFlurryIntegration

- (id)initWithSettings:(NSDictionary *)settings
{
    if (self = [super init]) {
        self.settings = settings;

        NSNumber *sessionContinueSeconds = settings[@"sessionContinueSeconds"];
        if (sessionContinueSeconds) {
            int s = [sessionContinueSeconds intValue];
            [Flurry setSessionContinueSeconds:[sessionContinueSeconds intValue]];
            SEGLog(@"Flurry setSessionContinueSeconds:%d", s);
        }

        NSString *apiKey = self.settings[@"apiKey"];
        [Flurry startSession:apiKey];
        SEGLog(@"Flurry startSession:%@", apiKey);
    }
    return self;
}

- (void)identify:(SEGIdentifyPayload *)payload
{
    [Flurry setUserID:payload.userId];

    NSDictionary *traits = payload.traits;
    if (!traits) {
        return;
    }

    NSString *gender = traits[@"gender"];
    if (gender) {
        [Flurry setGender:[gender substringToIndex:1]];
    }

    NSString *age = traits[@"age"];
    if (age) {
        [Flurry setAge:[age intValue]];
    }

    NSDictionary *location = traits[@"location"];
    if (location) {
        float latitude = [location[@"latitude"] floatValue];
        float longitude = [location[@"longitude"] floatValue];
        float horizontalAccuracy = [location[@"horizontalAccuracy"] floatValue];
        float verticalAccuracy = [location[@"verticalAccuracy"] floatValue];
        [Flurry setLatitude:latitude longitude:longitude horizontalAccuracy:horizontalAccuracy verticalAccuracy:verticalAccuracy];
    }
}

- (void)track:(SEGTrackPayload *)payload
{
    [Flurry logEvent:payload.event withParameters:payload.properties];
}

- (void)screen:(SEGScreenPayload *)payload
{
    if ([self screenTracksEvents]) {
        NSString *event = [[NSString alloc] initWithFormat:@"Viewed %@ Screen", payload.name];
        [Flurry logEvent:event withParameters:payload.properties];
    }

    // Flurry just counts the number of page views
    // http://stackoverflow.com/questions/5404513/tracking-page-views-with-the-help-of-flurry-sdk

    [Flurry logPageView];
}

// Return true if all screen should be tracked as event.
- (BOOL)screenTracksEvents
{
    return [(NSNumber *)[self.settings objectForKey:@"screenTracksEvents"] boolValue];
}

@end
