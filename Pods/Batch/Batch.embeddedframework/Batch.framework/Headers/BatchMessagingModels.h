//
//  BatchMessagingModels.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2019 Batch SDK. All rights reserved.
//

FOUNDATION_EXPORT NSInteger const BatchMessageGlobalActionIndex;

/**
 Represents an In-App Message content
 This protocol itself isn't really useful: you will need to safely cast it to an instance, such as BatchInterstitialMessageContent or BatchAlertMessageContent
 */
@protocol BatchInAppMessageContent <NSObject>

@end

/**
 Model describing an alert message's CTA
 */
@interface BatchAlertMessageCTA : NSObject

@property (nullable, readonly) NSString* label;
@property (nullable, readonly) NSString* action;
@property (nullable, readonly) NSDictionary* args;

@end

/**
 Model describing the content of an alert message
 */
@interface BatchAlertMessageContent : NSObject <BatchInAppMessageContent>

@property (nullable, readonly) NSString* trackingIdentifier;
@property (nullable, readonly) NSString* title;
@property (nullable, readonly) NSString* body;
@property (nullable, readonly) NSString* cancelLabel;
@property (nullable, readonly) BatchAlertMessageCTA* acceptCTA;

@end

/**
 Model describing an interstitial message's CTA
 */
@interface BatchInterstitialMessageCTA : NSObject

@property (nullable, readonly) NSString* label;
@property (nullable, readonly) NSString* action;
@property (nullable, readonly) NSDictionary* args;

@end

/**
 Model describing the content of an interstitial message
 */
@interface BatchInterstitialMessageContent : NSObject <BatchInAppMessageContent>

@property (nullable, readonly) NSString* trackingIdentifier;
@property (nullable, readonly) NSString* header;
@property (nullable, readonly) NSString* title;
@property (nullable, readonly) NSString* body;
@property (nullable, readonly) NSArray<BatchInterstitialMessageCTA*>* ctas;
@property (nullable, readonly) NSString* mediaURL;
@property (nullable, readonly) NSString* mediaAccessibilityDescription;
@property (readonly) BOOL showCloseButton;

@end


@interface BatchMessageAction : NSObject

@property (nullable, readonly) NSString * action;
@property (nullable, readonly) NSDictionary<NSString *, id> * args;

- (BOOL)isDismissAction;

@end

@interface BatchMessageCTA: BatchMessageAction

@property (readonly, nullable)  NSString *label;

@end

/**
 Model describing a banner message's global tap action
 */
@interface BatchBannerMessageAction : BatchMessageAction
@end

/**
 Model describing an image message's global tap action
 */
@interface BatchImageMessageAction : BatchMessageAction
@end

/**
 Model describing a banner message's CTA
 */
@interface BatchBannerMessageCTA : NSObject

@property (nullable, readonly) NSString* label;
@property (nullable, readonly) NSString* action;
@property (nullable, readonly) NSDictionary* args;

@end

/**
 Model describing the content of a banner message
 */
@interface BatchBannerMessageContent : NSObject <BatchInAppMessageContent>

@property (nullable, readonly) NSString* trackingIdentifier;
@property (nullable, readonly) NSString* title;
@property (nullable, readonly) NSString* body;
@property (nullable, readonly) NSArray<BatchBannerMessageCTA*>* ctas;
@property (nullable, readonly) BatchBannerMessageAction* globalTapAction;
@property (nullable, readonly) NSString* mediaURL;
@property (nullable, readonly) NSString* mediaAccessibilityDescription;
@property (readonly) BOOL showCloseButton;

// Expressed in seconds, 0 if should not automatically dismiss
@property (readonly) NSTimeInterval automaticallyDismissAfter;

@end

/**
 Model describing the content of an image message
 */
@interface BatchMessageImageContent : NSObject <BatchInAppMessageContent>

@property            CGSize imageSize;
@property (nullable) NSString *imageURL;
@property            NSTimeInterval globalTapDelay;
@property (nonnull)  BatchImageMessageAction *globalTapAction;
@property            BOOL isFullscreen;
@property (nullable) NSString *imageDescription;
@property            NSTimeInterval autoClose;
@property            BOOL allowSwipeToDismiss;

@end

/**
 Model describing the content of a modal message
 */
@interface BatchMessageModalContent : NSObject <BatchInAppMessageContent>

@property (nullable, readonly) NSString* trackingIdentifier;
@property (nullable, readonly) NSString* title;
@property (nullable, readonly) NSString* body;
@property (nullable, readonly) NSArray<BatchBannerMessageCTA*>* ctas;
@property (nullable, readonly) BatchBannerMessageAction* globalTapAction;
@property (nullable, readonly) NSString* mediaURL;
@property (nullable, readonly) NSString* mediaAccessibilityDescription;
@property (readonly) BOOL showCloseButton;

// Expressed in seconds, 0 if should not automatically dismiss
@property (readonly) NSTimeInterval automaticallyDismissAfter;

@end

/**
 Protocol representing a Batch Messaging VC.
 */
@protocol BatchMessagingViewController <NSObject>

@property (readonly) BOOL shouldDisplayInSeparateWindow;

@end

/**
 Represents a Batch Messaging message
 */
@interface BatchMessage : NSObject <NSCopying, BatchUserActionSource>

@end

/**
 Represents a Batch Messaging message coming from an In-App Campaign
 */
@interface BatchInAppMessage : BatchMessage

/**
 User defined custom payload
 */
@property (nullable, readonly) NSDictionary<NSString*, NSObject*>* customPayload;

/**
 In-App message's visual contents
 
 Since the content can greatly change between formats, you will need to cast it to one of the classes
 confirming to the BatchInAppMessageContent protocol, such as BatchAlertMessageContent or BatchInterstitialMessageContent.
 
 More types might be added in the future, so don't make any assuptions on the kind of class returned by this property.
 
 Can be nil if an error occurred or if not applicable
 */
@property (nullable, readonly) id<BatchInAppMessageContent> content;

/**
 Get the campaign token. This is the same token as you see when opening the In-App Campaign in your browser, when on the dashboard.
 Can be nil.
 */
@property (nullable, readonly) NSString *campaignToken;

@end

/**
 Represents a Batch Messaging message coming from a push
 */
@interface BatchPushMessage : BatchMessage

/**
 Original push payload
 */
@property (nonnull, readonly) NSDictionary<NSString*, NSObject*>* pushPayload;

@end
