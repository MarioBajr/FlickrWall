//
//  UIImage+Extensions.h
//  FlickerWall
//
//  Created by Mario Barbosa on 10/17/12.
//  Copyright (c) 2012 Mario Barbosa. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Extensions)

- (UIImage*)imageScaledToSize:(CGSize)size;
- (UIImage*)imageScaledToFit:(CGSize)size;
- (UIImage*)imageScaledToFill:(CGSize)size;
+ (CGSize)scaleToFit:(CGSize)size withBounds:(CGSize)bounds;
+ (CGSize)scaleToFill:(CGSize)size withBounds:(CGSize)bounds;

@end