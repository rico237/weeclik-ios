#import "SEGBatchIntegrationFactory.h"
#import "SEGBatchIntegration.h"

@implementation SEGBatchIntegrationFactory

+ (instancetype)instance
{
    static dispatch_once_t onceToken;
    static SEGBatchIntegrationFactory *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    return self;
}

- (id<SEGIntegration>)createWithSettings:(NSDictionary *)settings forAnalytics:(SEGAnalytics *)analytics
{
    [SEGBatchIntegration saveSettings:settings];
    [SEGBatchIntegration startWithSettings:settings];
    return [SEGBatchIntegration new];
}

- (NSString *)key
{
    return @"Batch";
}

@end
