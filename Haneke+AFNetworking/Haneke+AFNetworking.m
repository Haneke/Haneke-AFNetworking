//
//  Haneke+AFNetworking.m
//  Haneke+AFNetworking
//
//  Created by Hermes Pique on 8/30/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "Haneke+AFNetworking.h"
#import <AFNetworking/AFNetworking.h>
#import <objc/runtime.h>

@interface HNKNetworkFetcher (_AFNetworking)

@property (readwrite, nonatomic, strong, setter = af_setImageRequestOperation:) AFHTTPRequestOperation *af_imageRequestOperation;

+ (void)af_failWithError:(NSError*)error block:(void (^)(NSError *error))failureBlock;

@end

@implementation HNKNetworkFetcher (_AFNetworking)

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

@implementation HNKNetworkFetcher(AFNetworking)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self af_swizzleSelector:@selector(fetchImageWithSuccess:failure:) withSelector:@selector(af_fetchImageWithSuccess:failure:)];
        [self af_swizzleSelector:@selector(cancelFetch) withSelector:@selector(af_cancelFetch)];
    });
}

+ (void)af_swizzleSelector:(SEL)originalSelector withSelector:(SEL)swizzledSelector
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
            NSError *error = [NSError errorWithDomain:HNKErrorDomain code:HNKErrorNetworkFetcherInvalidData userInfo:userInfo];
            
            [HNKNetworkFetcher af_failWithError:error block:failureBlock];
            return;
        }
        
        successBlock(image);

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [HNKNetworkFetcher af_failWithError:error block:failureBlock];
    }];
    
    [[self.class af_sharedImageRequestOperationQueue] addOperation:self.af_imageRequestOperation];
}

- (void)af_cancelFetch
{
    [self.af_imageRequestOperation cancel];
    self.af_imageRequestOperation = nil;
}

@end
