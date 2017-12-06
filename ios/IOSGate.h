//
//  IOSGate.h
//  Unity-iPhone
//
//  Created by crl on 16/10/31.
//
//

#ifndef IOSGate_h
#define IOSGate_h

#import <Foundation/Foundation.h>
#import "UnityInterface.h"
/*#import <UnityAds/UnityAds.h>
#import <VungleSDK/VungleSDK.h>
#import <InMobiSDK/InMobiSDK.h>*/

@interface IOSGate : NSObject//<UnityAdsDelegate,IMBannerDelegate,IMInterstitialDelegate,VungleSDKDelegate>

//@property (nonatomic, strong) IMBanner *banner;

//@property (nonatomic, strong) IMInterstitial *interstitial;


+(IOSGate *) sharedInstance;

-(void)preInit;
-(void)doInit:(NSString*)value;

-(void)login;

-(void)pay:(NSString *)value;

-(void)router:(NSString *)key Value:(NSString *)value;

-(void)send:(NSString *)key Value:(NSString *)value;

@end



#endif /* IOSGate_h */
