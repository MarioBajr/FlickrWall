//
//  UIImage+Extensions.m
//  FlickerWall
//
//  Created by Mario Barbosa on 10/17/12.
//  Copyright (c) 2012 Mario Barbosa. All rights reserved.
//

#import "UIImage+Extensions.h"

@implementation UIImage (Extensions)

- (UIImage*)imageScaledToSize:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage*)imageScaledToFill:(CGSize)size
{
	CGSize imageSize = [UIImage scaleToFill:self.size withBounds:size];
	return [self imageScaledToSize:imageSize];
}

- (UIImage*)imageScaledToFit:(CGSize)size
{
	CGSize imageSize = [UIImage scaleToFit:self.size withBounds:size];
	return [self imageScaledToSize:imageSize];
}

+ (CGSize)scaleToFit:(CGSize)size withBounds:(CGSize)bounds
{
	CGSize scaleSize = [UIImage scaleHeightSize:size withWidth:bounds.width];
	
	if (scaleSize.height > bounds.height)
		scaleSize = [UIImage scaleWidthSize:size withHeight:bounds.height];
	
	return scaleSize;
}

+ (CGSize)scaleToFill:(CGSize)size withBounds:(CGSize)bounds
{
	CGSize scaleSize = [UIImage scaleHeightSize:size withWidth:bounds.width];
	
	if (scaleSize.height < bounds.height)
		scaleSize = [UIImage scaleWidthSize:size withHeight:bounds.height];
	
	return scaleSize;
}

+ (CGSize)scaleHeightSize:(CGSize)size withWidth:(NSInteger)width
{
	return CGSizeMake( roundf(width), roundf(width * [UIImage heightToWidth:size]));
}

+ (CGSize)scaleWidthSize:(CGSize)size withHeight:(NSInteger)height
{	
	return CGSizeMake( roundf(height * [UIImage widthToHeight:size]), round(height));
}

+ (float)widthToHeight:(CGSize)size
{
	return size.width / size.height;
}

+ (float)heightToWidth:(CGSize)size
{
	return size.height / size.width;
}

@end
