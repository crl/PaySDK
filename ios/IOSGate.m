//
//  IOSGate.m
//  Unity-iPhone
//
//  Created by crl on 16/10/31.
//
//


#import <GameKit/GameKit.h>
#import <UIKit/UIKit.h>
#import "IOSGate.h"
#import "Util.h"
#import "InAppPurchasesManager.h"

@implementation IOSGate
{
    
}

static IOSGate *_instance;

+(IOSGate *) sharedInstance{
    if(_instance==nil){
        _instance=[[self alloc]init];
    }
    
    return _instance;
}
bool isInited=false;

-(void)preInit{
    
}
-(void)doInit:(NSString *) value{
    
    if(isInited){
        return;
    }

    InAppPurchasesManager *iap = [InAppPurchasesManager sharedInstance];
    NSArray *v=@[@"ys06",@"ys30",@"ys68",@"ys128",@"ys328",@"ys648"];
    [iap requestProductData:v];
    
    isInited=true;
    
    [self login];
}


static NSString* playerID;

-(void)login{
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:[UIApplication sharedApplication]];
    
    GKLocalPlayer *localPlayer=[GKLocalPlayer localPlayer];
    
    if(localPlayer.isAuthenticated){
        [self loginBack];
    }else if(localPlayer.authenticateHandler==nil){
        
        localPlayer.authenticateHandler=^(UIViewController* uiViewController,NSError* error){
            
            if(uiViewController!=nil){
                UIViewController *rootViewController=[[[[UIApplication sharedApplication] delegate] window] rootViewController];
                [rootViewController presentViewController:uiViewController animated:YES completion:nil];
                
            }else if([GKLocalPlayer localPlayer].isAuthenticated){
                [self loginBack];
            }else if(error!=nil){
                
                NSString* uuID=[[NSUserDefaults standardUserDefaults] stringForKey:@"uuid"];
                if(uuID==nil){
                    uuID=[[UIDevice currentDevice].identifierForVendor UUIDString];
                    if(uuID==nil){
                        uuID=[[NSUUID UUID] UUIDString];
                    }
                    if (uuID!=nil) {
                        [[NSUserDefaults standardUserDefaults] setValue:uuID forKey:@"uuid"];
                    }
                }
                
                if([playerID isEqual:uuID]){
                    return;
                }
                playerID=uuID;
                [self sendLoginBack];
            }
        };
    }
}

-(void)loginBack{
    GKLocalPlayer *localPlayer=[GKLocalPlayer localPlayer];
    if(localPlayer.isAuthenticated){
        NSString* uuID=[localPlayer.playerID stringByReplacingOccurrencesOfString:@":" withString:@""];
        if([playerID isEqual:uuID]){
            return;
        }
        playerID=uuID;
    }
    
    [self sendLoginBack];
}

-(void)sendLoginBack{
    
    if(playerID==nil){
        [self send:@"login_back" Value:@"0|login fail!"];
        return;
    }
    
    NSString* msg=[[NSString alloc] initWithFormat:@"1|%@|%@|%@",playerID,playerID,@"local"];
    [self send:@"login_back" Value:msg];
}

-(void)send:(NSString *)key Value:(NSString *)value{
    const char* go=[@"UICamera" UTF8String];
    const char* method=[@"Receive" UTF8String];
    
    NSString* msg=[[NSString alloc] initWithFormat:@"%@~%@",key,value];
    UnitySendMessage(go, method, [msg UTF8String]);
}


-(void)pay:(NSString *)value{
    
    if([value length]==0){
        return;
    }
    
    NSDictionary *dict=[Util parserURLKeys:value];
    NSString *productID=[dict objectForKey:@"appID"];
    if([productID length]==0){
        productID=@"zs01";
    }
    
    NSLog(@"product: %@",productID);
    [[InAppPurchasesManager sharedInstance] purchase:productID json:dict];
}

-(void) router:(NSString *)key Value:(NSString *)value
{
    if([key isEqual:@"playad"]){
        [self playAd:value];
    }else if([key isEqual:@"step"]){
        
        if([value isEqualToString:@"10"]){
            [self showBannerAd:value];
        }
    }
}


-(void)playAd:(NSString*) v{
}

-(void)showBannerAd:(NSString*) v{
}

@end
