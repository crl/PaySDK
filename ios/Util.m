//
//  Util.m
//  ndExtension
//
//  Created by crl on 13-8-23.
//
//

#import "Util.h"

@implementation Util

static Util* _instance=nil;
+(Util*)sharedInstance{
    if(_instance==nil){
        _instance=[[self alloc] init];
    }
    return _instance;
}

+(NSDictionary*) parserURLKeys:(NSString*) value{
    NSArray *temp=[value componentsSeparatedByString:@"&"];
    
    NSLog(@"%@:%lu",value,(unsigned long)[temp count]);
    
    NSMutableDictionary *dict=[[NSMutableDictionary alloc] init];
    
    NSCharacterSet *doNotWant = [NSCharacterSet characterSetWithCharactersInString:@"\'\""];
    
    for(NSString *keyValuePair in temp)
    {
        NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
        if (pairComponents.count !=2) {
            continue;
        }
        
        NSString *key = [pairComponents objectAtIndex:0];
        NSString *value = [pairComponents objectAtIndex:1];
        
        key = [[key componentsSeparatedByCharactersInSet: doNotWant] componentsJoinedByString: @""];
        value = [[value componentsSeparatedByCharactersInSet: doNotWant] componentsJoinedByString: @""];
        
        [dict setObject:value forKey:key];
    }
    

    return dict;
}


+(UIViewController*)getRoot{
    UIViewController *rootViewController=[[[[UIApplication sharedApplication] delegate] window] rootViewController];
    return rootViewController;
}

static UIActivityIndicatorView* loadingBar;
static bool _hasLoading=false;

+(void)loading:(BOOL)b{
    _hasLoading=b;
    if(loadingBar==nil){
        
        loadingBar=[[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0,0,50,50)];
        loadingBar.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        loadingBar.color=[UIColor yellowColor];
        
        UIColor* clr=[[UIColor blackColor] colorWithAlphaComponent:0.5f];
        loadingBar.backgroundColor=clr;
    }
    
    UIView* view=[Util getRoot].view;
    if(view != nil){
        [view addSubview:loadingBar];
    }
    
    if(b){
        CGRect rect=[UIScreen mainScreen].bounds;
        loadingBar.center=CGPointMake(rect.size.width/2,rect.size.height/2);
        [loadingBar startAnimating];
    }else{
        [loadingBar stopAnimating];
        if(loadingBar.superview != nil){
            [loadingBar removeFromSuperview];
        }
    }
    
}
+(BOOL)hasLoading{
    return _hasLoading;
}

+(void)openUserReviews:(NSString*)appID{
    NSString *str = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/app/viewContentsUserReviews?id=%@", appID];
    NSURL *url = [NSURL URLWithString:str];
    [[UIApplication sharedApplication] openURL:url];
}


+(void)openHome:(NSString*)appID{
    //内部弹出应用下载页
    SKStoreProductViewController* storeView=[[SKStoreProductViewController alloc] init];
    
    storeView.delegate=[Util sharedInstance];
    [storeView loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier:appID} completionBlock:^(BOOL result, NSError * _Nullable error) {
        if(result){
            UIViewController *rootViewController=[[[[UIApplication sharedApplication] delegate] window] rootViewController];
            [rootViewController presentViewController:storeView animated:YES completion:nil];
        }else if(error){
            [Util openUserReviews:appID];
            NSLog(@"Error %@ with User Info %@.", error, [error userInfo]);
        }
    }];
}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController{
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

@end
