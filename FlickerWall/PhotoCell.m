//
//  PhotoCell.m
//  FlickrWall
//
//  Created by Mario Barbosa on 2/6/13.
//  Copyright (c) 2013 Mario. All rights reserved.
//

#import "PhotoCell.h"
#import "UIImageView+WebCache.h"
//
@interface PhotoCell()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end

@implementation PhotoCell

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.backgroundView = [[UIView alloc] init];
	self.backgroundView.backgroundColor = [UIColor whiteColor];
	
	self.selectedBackgroundView = [[UIView alloc] init];
	self.selectedBackgroundView.backgroundColor = [UIColor colorWithRed:.19 green:.41 blue:.96 alpha:1.];
}

- (void)setPhoto:(Photo *)photo
{
	_photo = photo;
	[self.imageView setImageWithURL:[NSURL URLWithString:photo.media]];
}

@end
