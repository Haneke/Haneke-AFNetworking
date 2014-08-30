//
//  UIImage+HanekeTestUtils.h
//  Haneke
//
//  Created by Hermes Pique on 20/02/14.
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

#import <UIKit/UIKit.h>

@interface UIImage (HanekeTestUtils)

+ (UIImage*)hnk_imageWithColor:(UIColor*)color size:(CGSize)size;

+ (UIImage*)hnk_imageWithColor:(UIColor*)color size:(CGSize)size opaque:(BOOL)opaque;

+ (UIImage*)hnk_imageGradientFromColor:(UIColor*)fromColor toColor:(UIColor*)toColor size:(CGSize)size;

- (BOOL)hnk_isEqualToImage:(UIImage*)image;

@end

// Implemented in HNKCache.m

@interface UIImage (hnk_utils)

- (BOOL)hnk_hasAlpha;

@end
