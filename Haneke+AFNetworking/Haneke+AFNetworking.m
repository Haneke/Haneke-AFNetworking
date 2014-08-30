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
@property (nonatomic, readonly) NSURL *URL;

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

@end

@implementation HNKNetworkEntity(AFNetworking)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

- (void)fetchImageWithSuccess:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    NSURLRequest *URLRequest = [NSURLRequest requestWithURL:self.URL];
    self.af_imageRequestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:URLRequest];
    self.af_imageRequestOperation.responseSerializer = [AFImageResponseSerializer serializer];
    [self.af_imageRequestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, UIImage *image) {
        if (!successBlock) return;
        
        successBlock(image);

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        HanekeLog(@"%@", error);
        if (!failureBlock) return;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
    }];
    
    [[self.class af_sharedImageRequestOperationQueue] addOperation:self.af_imageRequestOperation];
}

- (void)cancelFetch
{
    [self.af_imageRequestOperation cancel];
    self.af_imageRequestOperation = nil;
}

#pragma clang diagnostic pop

@end
