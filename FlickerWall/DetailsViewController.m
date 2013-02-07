//
//  DetailsViewController.m
//  FlickrWall
//
//  Created by Mario Barbosa on 2/6/13.
//  Copyright (c) 2013 Mario. All rights reserved.
//

#import "DetailsViewController.h"
#import <FacebookSDK/FacebookSDK.h>

#import "SDWebImageCompat.h"
#import "SDWebImageManagerDelegate.h"
#import "SDWebImageManager.h"

@interface DetailsViewController ()<SDWebImageManagerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *publishedLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateTakenLabel;
@property (weak, nonatomic) IBOutlet UILabel *authorLabel;
@property (weak, nonatomic) IBOutlet UILabel *tags;

@property (weak, nonatomic) IBOutlet UIButton *facebookButton;
@property (strong, nonatomic) UIImage *image;
@end

@implementation DetailsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.facebookButton.enabled = NO;
	
	///Customize Interface
	if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad)
	{
		UIImage *image;
		image = [[UIImage imageNamed:@"facebook_default"] resizableImageWithCapInsets:UIEdgeInsetsMake(21, 47, 21, 5)];
		[self.facebookButton setBackgroundImage:image forState:UIControlStateNormal];
		image = [[UIImage imageNamed:@"facebook_pressed"] resizableImageWithCapInsets:UIEdgeInsetsMake(21, 47, 21, 5)];
		[self.facebookButton setBackgroundImage:image forState:UIControlStateHighlighted];
		image = [[UIImage imageNamed:@"facebook_disabled"] resizableImageWithCapInsets:UIEdgeInsetsMake(21, 47, 21, 5)];
		[self.facebookButton setBackgroundImage:image forState:UIControlStateDisabled];
	}
	
	[self.facebookButton addTarget:self action:@selector(facebookAction:) forControlEvents:UIControlEventTouchUpInside];
	
	///Try to load the UIImage
	SDWebImageManager *manager = [SDWebImageManager sharedManager];
	
    /// Remove in progress downloader from queue
    [manager cancelForDelegate:self];
	
	NSURL *url = [NSURL URLWithString:self.photo.media];
    if (url)
	{
		__weak DetailsViewController *own = self;
        [manager downloadWithURL:url delegate:self options:0 success:^(UIImage *image){
			own.image = image;
			own.facebookButton.enabled = YES;
		} failure:^(NSError *error){
			LOG_ERR(error);
		}];
	}
	
	///Add Photo Informations
	NSDateFormatter *format = [[NSDateFormatter alloc] init];
	[format setDateStyle:NSDateFormatterShortStyle];
	[format setTimeStyle:NSDateFormatterShortStyle];
	[format setLocale:[NSLocale currentLocale]];
	
	self.titleLabel.text = self.photo.title;
	self.dateTakenLabel.text = [format stringFromDate:self.photo.dateTaken];
	self.publishedLabel.text = [format stringFromDate:self.photo.published];
	self.authorLabel.text = self.photo.author;
	self.tags.text = self.photo.tags;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Actions Callback

- (IBAction)facebookAction:(id)sender
{
    BOOL displayedNativeDialog = [FBNativeDialogs presentShareDialogModallyFrom:self
                                                                    initialText:nil
                                                                          image:self.image
                                                                            url:nil
                                                                        handler:nil];
    if (!displayedNativeDialog)
	{
        [self performPublishAction:^{
            [FBRequestConnection startForUploadPhoto:self.image
                                   completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                       self.facebookButton.enabled = YES;
                                   }];
            
            self.facebookButton.enabled = NO;
        }];
    }
}

#pragma mark - Facebook

- (void) performPublishAction:(void (^)(void)) action {
    if ([FBSession.activeSession.permissions indexOfObject:@"publish_actions"] == NSNotFound)
	{
		[FBSession.activeSession reauthorizeWithPublishPermissions:[NSArray arrayWithObject:@"publish_actions"]
												   defaultAudience:FBSessionDefaultAudienceFriends
												 completionHandler:^(FBSession *session, NSError *error) {
													 if (!error) {
														 action();
													 }
												 }];
    } else {
        action();
    }
}

@end
