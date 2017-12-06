//
//  Util.h
//  ndExtension
//
//  Created by crl on 13-8-23.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

@interface Util : NSObject<SKStoreProductViewControllerDelegate>

+(Util*)sharedInstance;

+(NSDictionary*) parserURLKeys:(NSString*) value;

+(UIViewController*)getRoot;
+(void)openHome:(NSString*)appID;

+(void)openUserReviews:(NSString*)appID;

+(void)loading:(BOOL)b;
+(BOOL)hasLoading;
@end
