#import <Foundation/Foundation.h>

#import <Analytics/SEGIntegration.h>

@interface SEGBatchIntegration : NSObject <SEGIntegration>

+ (void)saveSettings:(NSDictionary *)settings;
+ (void)startWithSettings:(NSDictionary *)settings;

@property (class) BOOL enableAutomaticStart;

@end
