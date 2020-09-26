#import <Foundation/Foundation.h>
#import <Analytics/SEGIntegrationFactory.h>

@interface SEGFlurryIntegrationFactory : NSObject<SEGIntegrationFactory>

+ (id)instance;

@end