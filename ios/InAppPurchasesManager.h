
#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>



@interface InAppPurchasesManager : NSObject <UIAlertViewDelegate,SKProductsRequestDelegate, SKPaymentTransactionObserver> {
    NSDictionary *gameData;
}

@property (nonatomic,strong)NSString *orderID;

+ (InAppPurchasesManager *)sharedInstance;
- (void)requestProductData:(NSArray *) v;
- (BOOL)canMakePurchases;
- (void)purchase:(NSString *)productID json:(NSDictionary *)json;
- (void)sendFailedIapFiles;

@end
