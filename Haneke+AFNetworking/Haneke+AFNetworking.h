//
//  Haneke_AFNetworking.h
//  Haneke+AFNetworking
//
//  Created by Hermes Pique on 8/30/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Haneke/Haneke.h>

@interface HNKNetworkEntity(AFNetworking)

- (void)fetchImageWithSuccess:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock;

- (void)cancelFetch;

@end
