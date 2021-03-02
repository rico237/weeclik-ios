#import "SEGBatchIntegration.h"
#import <Analytics/SEGAnalyticsUtils.h>
#import <Batch/Batch.h>

@implementation SEGBatchIntegration
{
    NSRegularExpression *eventNameSnakeCaseRegexp;
    NSRegularExpression *eventNameSlugifyRegexp;
    NSRegularExpression *eventNameDoubleUnderscoreRegexp;
}

BOOL SEGBatchIntegrationEnableAutomaticStart = true;

NSString *const SEGBatchIntegrationDefaultsKey = @"SEGBatchIntegrationSettings";

NSString *const SEGBatchIntegrationSettingsApiKey = @"apiKey";
NSString *const SEGBatchIntegrationSettingsIDFA = @"canUseAdvertisingID";
NSString *const SEGBatchIntegrationSettingsAdvancedDeviceInformation = @"canUseAdvancedDeviceInformation";

+ (void)load
{
    [[NSNotificationCenter defaultCenter] addObserver:[SEGBatchIntegration class]
                                             selector:@selector(applicationDidFinishLaunching)
                                                 name:UIApplicationDidFinishLaunchingNotification
                                               object:nil];
    
    setenv("BATCH_PLUGIN_VERSION", [@"Segment/1.1.0" cStringUsingEncoding:NSUTF8StringEncoding], 1);
}

+ (BOOL)enableAutomaticStart
{
    return SEGBatchIntegrationEnableAutomaticStart;
}

+ (void)setEnableAutomaticStart:(BOOL)enable
{
    SEGBatchIntegrationEnableAutomaticStart = enable;
}

+ (void)applicationDidFinishLaunching
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id settings = [defaults valueForKey:SEGBatchIntegrationDefaultsKey];
    
    if ([settings isKindOfClass:[NSDictionary class]]) {
        [self startWithSettings:(NSDictionary*)settings];
    }
}

+ (void)saveSettings:(NSDictionary *)settings
{
    if ([settings isKindOfClass:[NSDictionary class]]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:settings forKey:SEGBatchIntegrationDefaultsKey];
    }
}

+ (void)startWithSettings:(NSDictionary *)settings
{
    if (SEGBatchIntegrationEnableAutomaticStart) {
        id apiKey = settings[SEGBatchIntegrationSettingsApiKey];
        if (![apiKey isKindOfClass:[NSString class]] || [apiKey length] == 0) {
            // Return if no API Key to match Android's behavior, which cannot change
            // the settings with no API Key
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            id canUseAdvertisingID = settings[SEGBatchIntegrationSettingsIDFA];
            if ([canUseAdvertisingID isKindOfClass:[NSNumber class]] && [canUseAdvertisingID boolValue] == NO) {
                [Batch setUseIDFA:NO];
                SEGLog(@"[Batch setUseIDFA:NO];");
                
            }
            
            id canUseAdvancedDeviceInformation = settings[SEGBatchIntegrationSettingsAdvancedDeviceInformation];
            if ([canUseAdvancedDeviceInformation isKindOfClass:[NSNumber class]] && [canUseAdvancedDeviceInformation boolValue] == NO) {
                [Batch setUseAdvancedDeviceInformation:NO];
                SEGLog(@"[Batch setUseAdvancedDeviceInformation:NO];");
                
            }
            
            [Batch startWithAPIKey:(NSString*)apiKey];
            SEGLog(@"[Batch startWithAPIKey:%@];", apiKey);
        });
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        eventNameSnakeCaseRegexp = [NSRegularExpression regularExpressionWithPattern:@"(?<!^|[A-Z])[A-Z]" options:0 error:nil];
        eventNameSlugifyRegexp = [NSRegularExpression regularExpressionWithPattern:@"[^a-zA-Z0-9]" options:0 error:nil];
        eventNameDoubleUnderscoreRegexp = [NSRegularExpression regularExpressionWithPattern:@"_+" options:0 error:nil];
    }
    return self;
}

- (NSString*)formatEventName:(NSString*)name
{
    if (!name) {
        return nil;
    }
    
    NSMutableString *mutableName = [name mutableCopy];
    
    [eventNameSnakeCaseRegexp replaceMatchesInString:mutableName
                                             options:0
                                               range:NSMakeRange(0, [mutableName length])
                                        withTemplate:@"_$0"];
    
    [eventNameSlugifyRegexp replaceMatchesInString:mutableName
                                           options:0
                                             range:NSMakeRange(0, [mutableName length])
                                      withTemplate:@"_"];
    
    [eventNameDoubleUnderscoreRegexp replaceMatchesInString:mutableName
                                                    options:0
                                                      range:NSMakeRange(0, [mutableName length])
                                               withTemplate:@"_"];
    
    // We don't need to take Unicode into account as we're down to single char characters
    NSRange range = {0, MIN([mutableName length], 30)};
    name = [mutableName substringWithRange:range];
    
    return [name uppercaseString];
}

- (void)trackTransactionIfAny:(SEGTrackPayload *)payload
{
    double amount = [self amountFromTransaction:payload];
    if (amount > 0) {
        [BatchUser trackTransactionWithAmount:amount];
        SEGLog(@"[BatchUser trackTransactionWithAmount:d%];", amount);
    }
}

- (double)amountFromTransaction:(SEGTrackPayload *)payload
{
    NSDictionary *props = payload.properties;
    NSNumber *total = props[@"total"];
    if ([total isKindOfClass:[NSNumber class]])
    {
        double dTotal = [total doubleValue];
        if (dTotal > 0) {
            return dTotal;
        }
    }
    
    NSNumber *revenue = props[@"revenue"];
    if ([revenue isKindOfClass:[NSNumber class]])
    {
        double dRevenue = [revenue doubleValue];
        if (dRevenue > 0) {
            return dRevenue;
        }
    }
    
    NSNumber *value = props[@"value"];
    if ([value isKindOfClass:[NSNumber class]])
    {
        double dValue = [value doubleValue];
        if (dValue > 0) {
            return dValue;
        }
    }
    
    return 0;
}

#pragma mark Segment methods

- (void)identify:(SEGIdentifyPayload *)payload
{
    BatchUserDataEditor *editor = [BatchUser editor];
    [editor setIdentifier:payload.userId];
    [editor save];
    SEGLog(@"[BatchUser %@];", editor);
}

- (void)track:(SEGTrackPayload *)payload
{
    NSString *titleKey = @"title";
    NSString *eventName = [self formatEventName:payload.event];
    
    if (eventName && [eventName length] > 0) {
        NSString *title = payload.properties[titleKey];
        if (![title isKindOfClass:[NSString class]]) {
            title = nil;
        }
        
        NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
        NSDictionary *properties = payload.properties;
        if (properties != nil) {
            for (NSString *key in properties) {
                if (![key isEqualToString:titleKey]) {
                    NSObject *value = payload.properties[key];
                    if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]]) {
                        [data setValue:value forKey:key];
                    }
                }
            }
        }
        
        if ([data count] == 0) {
            [BatchUser trackEvent:eventName withLabel:title];
            SEGLog(@"[BatchUser trackEvent:%@ withLabel:%@];", eventName, title);
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [BatchUser trackEvent:eventName withLabel:title data:data];
#pragma clang diagnostic pop
            SEGLog(@"[BatchUser trackEvent:%@ withLabel:%@ and data: %@];", eventName, title, data);
        }
    }
    
    [self trackTransactionIfAny:payload];
}

- (void)screen:(SEGScreenPayload *)payload
{
    [BatchUser trackEvent:@"SEGMENT_SCREEN" withLabel:payload.name];
    SEGLog(@"[BatchUser trackEvent:SEGMENT_SCREEN withLabel:%@];", payload.name);
}

- (void)group:(SEGGroupPayload *)payload
{
    BatchUserDataEditor *editor = [BatchUser editor];
    [editor setAttribute:payload.groupId forKey:@"SEGMENT_GROUP"];
    [editor save];
}

- (void)reset
{
    BatchUserDataEditor *editor = [BatchUser editor];
    [editor setIdentifier:nil];
    [editor clearTags];
    [editor clearAttributes];
    [editor save];
}

@end
