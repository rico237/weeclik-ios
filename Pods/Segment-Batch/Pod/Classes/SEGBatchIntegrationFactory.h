#import <Foundation/Foundation.h>
#import <Analytics/SEGIntegrationFactory.h>

@interface SEGBatchIntegrationFactory : NSObject <SEGIntegrationFactory>

+ (instancetype)instance;

@end
