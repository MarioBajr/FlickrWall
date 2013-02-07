//
//  PhotoViewController.m
//  FlickrWall
//
//  Created by Mario Barbosa on 2/6/13.
//  Copyright (c) 2013 Mario. All rights reserved.
//

#import "PhotoViewController.h"
#import "UIImageView+WebCache.h"

@interface PhotoViewController ()<SDWebImageManagerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end

@implementation PhotoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[self.navigationController.navigationBar setBarStyle:UIBarStyleBlackOpaque];
	
	self.title = self.photo.title;
	[self.imageView setImageWithURL:[NSURL URLWithString:self.photo.media]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.destinationViewController respondsToSelector:@selector(setPhoto:)])
	{
		[segue.destinationViewController setPhoto:self.photo];
	}
}

#pragma mark - Actions Callback

- (IBAction)closeAction:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

@end
