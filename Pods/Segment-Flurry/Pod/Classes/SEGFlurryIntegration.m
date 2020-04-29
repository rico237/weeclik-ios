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
        
        FlurrySessionBuilder* builder = [FlurrySessionBuilder new];
        
        NSNumber *sessionContinueSeconds = settings[@"sessionContinueSeconds"];
        if (sessionContinueSeconds) {
            int s = [sessionContinueSeconds intValue];
            [builder withSessionContinueSeconds:s];
            SEGLog(@"Flurry setSessionContinueSeconds:%d", s);
        }

        NSString *apiKey = self.settings[@"apiKey"];
        [Flurry startSession:apiKey withSessionBuilder:builder];
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
}

- (void)track:(SEGTrackPayload *)payload
{
    NSMutableDictionary *properties = [self truncateProperties:payload.properties];

    [Flurry logEvent:payload.event withParameters:properties];
    SEGLog(@"Flurry logEvent:%@ withParameters:%@", payload.event, properties);
}

- (void)screen:(SEGScreenPayload *)payload
{
    if ([self screenTracksEvents]) {
        NSString *event = [[NSString alloc] initWithFormat:@"Viewed %@ Screen", payload.name];
        NSMutableDictionary *properties = [self truncateProperties:payload.properties];
        [Flurry logEvent:event withParameters:properties];
        SEGLog(@"Flurry logEvent:%@ withParameters:%@", event, properties);
    }
}

// Return true if all screen should be tracked as event.
- (BOOL)screenTracksEvents
{
    return [(NSNumber *)[self.settings objectForKey:@"screenTracksEvents"] boolValue];
}

// Returns NSDictionary truncated to 10 entries

-(NSMutableDictionary *)truncateProperties:(NSDictionary *) properties
{
    NSMutableDictionary *truncatedProperties = [NSMutableDictionary dictionaryWithCapacity:10];
    for (NSString *property in properties) {
        truncatedProperties[property] = properties[property];
        if ([truncatedProperties count] == 10) {
            break;
        }
    }
    return truncatedProperties;
}

@end
