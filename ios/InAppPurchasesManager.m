
#import "InAppPurchasesManager.h"
#import "IOSGate.h"
#import "Util.h"

@implementation InAppPurchasesManager
static InAppPurchasesManager *_instance = nil;
+ (InAppPurchasesManager *)sharedInstance{
    if (!_instance) {
        _instance = [[super allocWithZone:NULL] init];
    }
    return _instance;
}

NSMutableDictionary* productDic;

- (id)init {
    if (self == [super init]) {
        productDic=[[NSMutableDictionary alloc] init];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        return self;
    }
    return nil;
}

NSArray* productKeys=nil;
- (void)requestProductData:(NSArray*) v {
    productKeys=v;
    [self reloadProductData];
}

-(void)reloadProductData{
    if(productKeys==nil){
        return;
    }
    NSSet * set = [NSSet setWithArray:productKeys];
    SKProductsRequest * request = [[SKProductsRequest alloc] initWithProductIdentifiers:set];
    request.delegate = self;
    [request start];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSArray *products = response.products;
    if (products.count == 0) {
        NSLog(@"无法获取产品信息");
        for (NSString* invalidProductId in response.invalidProductIdentifiers) {
            NSLog(@"Invalid: %@", invalidProductId);
        }
        return;
    }
    for (SKProduct *product in products) {
        NSLog(@"the product key: %@ is have",product.productIdentifier);
        [productDic setObject:product forKey:product.productIdentifier];
    }
    for (NSString *key in response.invalidProductIdentifiers) {
        NSLog(@"the product key: %@ is error",key);
    }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"In-App Store unavailable" message:@"The In-App Store is currently unavailable, please try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}

- (BOOL)canMakePurchases {
    return [SKPaymentQueue canMakePayments];
}

int pCount=0;
- (void)purchase:(NSString *)productID json:(NSDictionary *)json{
    
    if([Util hasLoading]){
        return;
    }
    pCount=0;
    gameData=[[NSDictionary alloc] initWithDictionary:json copyItems:TRUE];
    //NSString *postURL=[gameData objectForKey:@"sid"];
    SKProduct *product =[productDic objectForKey:productID];
    if(product==nil){
        NSString *msg=[[NSString alloc] initWithFormat:@"%@ not exist!",productID];
        [self showAlert:msg];
        
        [self reloadProductData];
        return;
    }
    
    [Util loading:true];
    SKPayment *payment=[SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

#pragma mark -
#pragma mark SKPaymentTransactionObserver methods
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        NSString *msg=[[NSString alloc] initWithFormat:@"Transaction state: %ld",(long)transaction.transactionState];
        NSLog(@"%@",msg);
        
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
                break;
            default:
                break;
        }
    }
}

- (void)finishTransaction:(SKPaymentTransaction *)transaction wasSuccessful:(BOOL)wasSuccessful {
    [Util loading:false];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    [self finishTransaction:transaction wasSuccessful:YES];
    
    NSString *productIdentifier = transaction.payment.productIdentifier;
    
    //error;
    //NSURL *appStoreReceiptURL=[[NSBundle mainBundle] appStoreReceiptURL];
    //NSData *data=[NSData dataWithContentsOfURL:appStoreReceiptURL];

    NSData *data=transaction.transactionReceipt;
    NSString *receipt =[data base64EncodedStringWithOptions:0];
    
    //向自己的服务器验证购买凭证
    NSString *postURL=[gameData objectForKey:@"vurl"];
    if ([postURL length]<5) {
        NSLog(@"%@",productIdentifier);
        return;
    }
    
    //test;
    //postURL=@"http://192.168.2.163:9001/charge/apple/pay.aspx";
    
    NSLog(@"postURL:%@",postURL);
    
    NSString *userInfo=[gameData objectForKey:@"userInfo"];
    NSString *productID=[gameData objectForKey:@"productID"];
    NSString *appID=[gameData objectForKey:@"appID"];
    NSString *productName=[gameData objectForKey:@"productName"];
    
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
    long long now = [[NSNumber numberWithDouble:time] longLongValue];
    NSString *orderID=[[NSString alloc] initWithFormat:@"lingyu_%lld",now];
    
    NSString *post=[[NSString alloc] initWithFormat:@"receipt=%@&userInfo=%@&orderID=%@&productID=%@&appID=%@&productName=%@",receipt,userInfo,orderID,productID,appID,productName];
    [self requestGameServer:postURL post:post failSave:YES deletePath:nil retryCount:2];
}


-(void)requestGameServer:(NSString*)postURL post:(NSString*)post failSave:(BOOL) failSave deletePath:(NSString*) deletePath retryCount:(int) retryCount
{
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%lu",(unsigned long)[postData length]];
    NSURL *serverURL = [[NSURL alloc] initWithString: postURL];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:serverURL];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    NSURLSession* session=[NSURLSession sharedSession];
    NSURLSessionTask* task=[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(error!=nil){
           
            if(retryCount>0){
                int v=retryCount-1;
                [self requestGameServer:postURL post:post failSave:YES deletePath:nil retryCount:v];
                return;
            }
            
            if(failSave){
                NSString *msg=[[NSString alloc] initWithFormat:@"验证服务器错误返回:%@",[error localizedDescription]];
                [self showAlert:msg];
                [self saveIapReceipt:postURL post:post];
            }
            return;
        }
        
        NSDictionary *json=nil;
        NSString *msg=nil;
        NSString *jsonString=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([jsonString length]<3) {
            
            if(failSave){
                [self saveIapReceipt:postURL post:post];
            }
            return;
        }
        
        NSLog(@"remote:%@",jsonString);
        
        NSData* jsonData = [jsonString dataUsingEncoding: NSUTF8StringEncoding];
        json= [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];
        IOSGate* gate=[IOSGate sharedInstance];
        if (json == nil) {
            NSLog(@"json parse failed:%@ \r\n",jsonString);
            msg=[[NSString alloc] initWithFormat:@"0|支付失败:%@",jsonString];
            [gate send:@"pay_back" Value:msg];
            
            if(failSave){
                [self saveIapReceipt:postURL post:post];
            }
            return;
        }
        
        if(failSave==false){
            [self deleteIapReceipt:deletePath];
        }
        
        int code=[[json objectForKey:@"code"] intValue];
        NSString *remoteData=[json objectForKey:@"data"];
        
        if (code==1) {
            NSDictionary* dic=[Util parserURLKeys:post];
            NSString* productName=@"内支付补偿回调!";
            if(dic!=nil){
                productName=[dic objectForKey:@"productName"];
            }
            msg=[[NSString alloc] initWithFormat:@"1|成功购买:%@",productName];
        }else{
            msg=@"0|支付失败!";
            if(remoteData==nil){
               remoteData=[json objectForKey:@"message"];
            }
            if([remoteData length]>0){
                msg=[[NSString alloc] initWithFormat:@"0|支付失败:%@",remoteData];
            }else{
                msg=[[NSString alloc] initWithFormat:@"0|支付失败code:%d",code];
            }
        }
        [gate send:@"pay_back" Value:msg];
    }];
    
    [task resume];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    [self finishTransaction:transaction wasSuccessful:NO];
    
    NSInteger code=transaction.error.code;
    
    NSString * productIdentifier =transaction.payment.productIdentifier;
    
    SKProduct *product =[productDic objectForKey:productIdentifier];
    
    NSMutableString *v = [[NSMutableString alloc] initWithString:@""];
    if (product!=nil) {
        [v appendString:product.localizedTitle];
    }
    
    if(code!=SKErrorPaymentCancelled){
        [v appendString:@"购买失败!"];
        [v appendFormat:@"code:%ld",(long)code];
    }else{
        [v appendString:@"取消购买!"];
    }
    [self showAlert:v];
    NSLog(@"Error: %@", transaction.error);
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    // 对于已购商品，处理恢复购买的逻辑
    [self finishTransaction:transaction wasSuccessful:NO];
}


+ (NSString *)getUUIDString
{
    CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef strRef = CFUUIDCreateString(kCFAllocatorDefault , uuidRef);
    NSString *uuidString = [(__bridge NSString*)strRef stringByReplacingOccurrencesOfString:@"-" withString:@""];
    CFRelease(strRef);
    CFRelease(uuidRef);
    return uuidString;
}
+(NSString*)AppStoreInfoLocalFilePath{
    return [NSString stringWithFormat:@"%@/%@/", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],@"iap"];
}

//持久化存储用户购买凭证(这里最好还要存储当前日期，用户id等信息，用于区分不同的凭证)
-(void)saveIapReceipt:(NSString*)postURL post:(NSString*)post{
    NSString *fileName = [InAppPurchasesManager getUUIDString];
    NSString *savedPath = [NSString stringWithFormat:@"%@%@.plist", [InAppPurchasesManager AppStoreInfoLocalFilePath], fileName];
    
    NSDictionary *dic =[ NSDictionary dictionaryWithObjectsAndKeys:
                        postURL,@"postURL",
                        post,@"post",
                        nil];
    
    [dic writeToFile:savedPath atomically:YES];
}
-(void)sendIapReceipt:(NSString*)path{
    NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:path];
    if(dic==nil){
        [self deleteIapReceipt:path];
        return;
    }
    NSString* postURL=[dic objectForKey:@"postURL"];
    NSString* post=[dic objectForKey:@"post"];
  
    [self requestGameServer:postURL post:post failSave:false deletePath:path retryCount:0];
}


-(void)deleteIapReceipt:(NSString*)path{
    
    if(path==nil || [path isEqualToString:@""]){
        return;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:path]){
        [fileManager removeItemAtPath:path error:nil];
    }
}

//验证receipt失败,App启动后再次验证
- (void)sendFailedIapFiles{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString* rootPath=[InAppPurchasesManager AppStoreInfoLocalFilePath];
    if([fileManager fileExistsAtPath:rootPath]==false){
        [fileManager createDirectoryAtPath:rootPath withIntermediateDirectories:YES attributes:nil error:nil];
        return;
    }
    
    NSError *error = nil;
    //搜索该目录下的所有文件和目录
    NSArray *cacheFileNameArray = [fileManager contentsOfDirectoryAtPath:[InAppPurchasesManager AppStoreInfoLocalFilePath] error:&error];
    if (error){
        NSLog(@"AppStoreInfoLocalFilePath error:%@", [error domain]);
        return;
    }
    for (NSString *name in cacheFileNameArray){
        if ([name hasSuffix:@".plist"]){//如果有plist后缀的文件，说明就是存储的购买凭证
            NSString *filePath = [NSString stringWithFormat:@"%@/%@", [InAppPurchasesManager AppStoreInfoLocalFilePath], name];
            [self sendIapReceipt:filePath];
        }
    }
}

UIAlertView *alert;
- (void)showAlert:(NSString *)msg {
    alert = [[UIAlertView alloc] initWithTitle:nil message:msg delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alert show];
}
@end
