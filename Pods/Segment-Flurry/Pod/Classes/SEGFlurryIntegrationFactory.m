#import "SEGFlurryIntegrationFactory.h"
#import "SEGFlurryIntegration.h"

@implementation SEGFlurryIntegrationFactory

+ (id)instance
{
    static dispatch_once_t once;
    static SEGFlurryIntegrationFactory *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    return self;
}

- (id<SEGIntegration>)createWithSettings:(NSDictionary *)settings forAnalytics:(SEGAnalytics *)analytics
{
    return [[SEGFlurryIntegration alloc] initWithSettings:settings];
}

- (NSString *)key
{
    return @"Flurry";
}

@end
