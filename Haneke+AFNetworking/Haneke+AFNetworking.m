//
//  Haneke+AFNetworking.m
//  Haneke+AFNetworking
//
//  Created by Hermes Pique on 8/30/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "Haneke+AFNetworking.h"
#import <AFNetworking/AFNetworking.h>
#import <objc/runtime.h>

@interface HNKNetworkEntity (_AFNetworking)

@property (readwrite, nonatomic, strong, setter = af_setImageRequestOperation:) AFHTTPRequestOperation *af_imageRequestOperation;

+ (void)af_failWithError:(NSError*)error block:(void (^)(NSError *error))failureBlock;

@end

@implementation HNKNetworkEntity (_AFNetworking)

+ (NSOperationQueue *)af_sharedImageRequestOperationQueue
{
    static NSOperationQueue *_af_sharedImageRequestOperationQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _af_sharedImageRequestOperationQueue = [NSOperationQueue new];
        _af_sharedImageRequestOperationQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    });
    
    return _af_sharedImageRequestOperationQueue;
}

- (AFHTTPRequestOperation *)af_imageRequestOperation
{
    return (AFHTTPRequestOperation *)objc_getAssociatedObject(self, @selector(af_imageRequestOperation));
}

- (void)af_setImageRequestOperation:(AFHTTPRequestOperation *)imageRequestOperation
{
    objc_setAssociatedObject(self, @selector(af_imageRequestOperation), imageRequestOperation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void)af_failWithError:(NSError*)error block:(void (^)(NSError *error))failureBlock
{
    HanekeLog(@"%@", error.localizedDescription);
    if (!failureBlock) return;
    
    failureBlock(error);
}

@end

@implementation HNKNetworkEntity(AFNetworking)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleSelector:@selector(fetchImageWithSuccess:failure:) withSelector:@selector(af_fetchImageWithSuccess:failure:)];
        [self swizzleSelector:@selector(cancelFetch) withSelector:@selector(af_cancelFetch)];
    });
}

+ (void)swizzleSelector:(SEL)originalSelector withSelector:(SEL)swizzledSelector
{
    Class class = self.class;
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    const BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod)
    {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    }
    else
    {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

- (void)af_fetchImageWithSuccess:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    NSURLRequest *URLRequest = [NSURLRequest requestWithURL:self.URL];
    self.af_imageRequestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:URLRequest];
    self.af_imageRequestOperation.responseSerializer = [AFImageResponseSerializer serializer];
    NSURL *URL = self.URL;
    [self.af_imageRequestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, UIImage *image) {
        if (!successBlock) return;
        
        if (!image)
        {
            NSString *localizedDescription = [NSString stringWithFormat:NSLocalizedString(@"Failed to load image from data at URL %@", @""), URL];
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : localizedDescription , NSURLErrorKey : URL};
            NSError *error = [NSError errorWithDomain:HNKErrorDomain code:HNKErrorNetworkEntityInvalidData userInfo:userInfo];
            
            [HNKNetworkEntity af_failWithError:error block:failureBlock];
            return;
        }
        
        successBlock(image);

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [HNKNetworkEntity af_failWithError:error block:failureBlock];
    }];
    
    [[self.class af_sharedImageRequestOperationQueue] addOperation:self.af_imageRequestOperation];
}

- (void)af_cancelFetch
{
    [self.af_imageRequestOperation cancel];
    self.af_imageRequestOperation = nil;
}

@end
