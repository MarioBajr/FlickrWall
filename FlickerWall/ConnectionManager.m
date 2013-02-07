//
//  ConnectionManager.m
//  FlickerWall
//
//  Created by Mario Barbosa on 2/5/13.
//  Copyright (c) 2013 Mario. All rights reserved.
//

#import "ConnectionManager.h"
#import "Photo.h"
#import "CoreDataManager.h"
#import <CoreData/CoreData.h>

#define PATH @"http://api.flickr.com/services/feeds/photos_public.gne?format=json&nojsoncallback=1"

@implementation ConnectionManager

+ (void)fetchWithCompletionHandler:(FetchCompletionHandler)completionHandler
{
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	
	NSURL *url = [NSURL URLWithString:PATH];
	NSURLRequest * request = [[NSURLRequest alloc] initWithURL:url];
	[NSURLConnection sendAsynchronousRequest:request
									   queue:[[NSOperationQueue alloc] init]
						   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
	 {
		 [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
		 
		 if (error)
		 {
			 completionHandler(NO);
			 LOG_ERR(error);
			 return;
		 }
		 
		 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
			 BOOL success = [[self class] processFetchedData:data];
			 
			 dispatch_async(dispatch_get_main_queue(), ^{
				 completionHandler(success);
			 });
		 });
	 }];
}

+ (BOOL)processFetchedData:(NSData *)data
{
	NSError *error = nil;
	NSString *jsonBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	NSMutableString *formatedJsonBody = [NSMutableString stringWithString:jsonBody];
	NSRegularExpression *regex;
	
	regex = [NSRegularExpression
			 regularExpressionWithPattern:@"(\\\\.)"
			 options:NSRegularExpressionCaseInsensitive
			 error:&error];
	[regex replaceMatchesInString:formatedJsonBody options:0 range:NSMakeRange(0, [formatedJsonBody length]) withTemplate:@""];
	
	if (error)
	{
		LOG_ERR(error);
		return NO;
	}
	
	id json = [NSJSONSerialization JSONObjectWithData:[formatedJsonBody dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
	
	if (error)
	{
		LOG_ERR(error);
		return NO;
	}
	
	NSArray *items = [json valueForKey:@"items"];
	if (items)
	{
		return [[self class] synchronizeObjects:items];
	}
	
	return NO;
}

+ (BOOL)synchronizeObjects:(NSArray *)remoteObjects
{	
	NSManagedObjectContext *mainContext = [[CoreDataManager sharedCoreDataManager] managedObjectContext];
	NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	[managedObjectContext setParentContext:mainContext];
	
	__block BOOL success = NO;
	
	[managedObjectContext performBlockAndWait:^{
		@try
		{
			[[self class] syncManagedObjectContext:managedObjectContext
									withRemoteList:remoteObjects];
			[managedObjectContext saveContext];
			success = YES;
		}
		@catch (NSException *exception)
		{
			NSLog(@"{NSException}: %@", exception);
		}
	}];
	
	return success;
}

+ (void)syncManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
				  withRemoteList:(NSArray *)remoteArray
{
	NSString *remoteID = @"link";
	NSString *localID  = @"link";
	Class syncClass = [Photo class];
	
	NSPredicate *matchingIdPredicate = [NSPredicate predicateWithFormat:
										[localID stringByAppendingString:@" in %@"],
										[remoteArray valueForKey:remoteID]];
	
	NSMutableSet *allObjectsSet = [[NSMutableSet alloc] initWithArray:
								   [managedObjectContext fetchAllObjectsOfClass:syncClass
																  withPredicate:nil]];
	NSSet *matchingObjectsSet = [[NSSet alloc] initWithArray:
								 [managedObjectContext fetchAllObjectsOfClass:syncClass
																withPredicate:matchingIdPredicate]];
	
	[allObjectsSet minusSet:matchingObjectsSet];
	
	//Remove Objects
	for (NSManagedObject *object in allObjectsSet)
		[managedObjectContext deleteObject:object];
	
	//Create Dictionary
	NSMutableDictionary *remoteItemsById = [NSMutableDictionary dictionary];
	for (NSManagedObject *object in matchingObjectsSet)
		[remoteItemsById setObject:object forKey:[object valueForKey:localID]];
	
	//Update or Create Objects
	for (NSDictionary *object in remoteArray)
	{
		NSManagedObject *localObject = [remoteItemsById objectForKey:[object valueForKey:remoteID]];
		
		if (!localObject)
		{
			localObject = [managedObjectContext createObjectFromClass:syncClass];
		}
		
		[self updateObject:localObject fromDictionary:object];
	}
}

+ (void)updateObject:(NSManagedObject *)localObject fromDictionary:(NSDictionary *)object
{
	Photo *photo = (Photo *)localObject;
	photo.author = [[self class] extractAuthorName:[object valueForKey:@"author"]];
	photo.authorID = [object valueForKey:@"author_id"];
	photo.dateTaken = [[self class] dateFromTaken:[object valueForKey:@"date_taken"]];
	photo.published = [[self class] dateFromPublished:[object valueForKey:@"published"]];
	photo.link = [object valueForKey:@"link"];
	photo.media = [object valueForKeyPath:@"media.m"];
	photo.tags = [object valueForKey:@"tags"];
	photo.title = [object valueForKey:@"title"];
	
	CGSize size = [[self class] extractPhotoSizeFromDescription:[object valueForKey:@"description"]];
	photo.width = @(size.width);
	photo.height = @(size.height);
}

+ (NSString *)extractAuthorName:(NSString *)author
{
	__block NSString *onlyName = author;
	
	NSError *error = nil;
	NSRegularExpression *regex;
	regex = [NSRegularExpression regularExpressionWithPattern:@".+\\((.+)\\)"
													  options:NSRegularExpressionCaseInsensitive
														error:&error];
	[regex enumerateMatchesInString:author
							options:0
							  range:NSMakeRange(0, [author length])
						 usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop)
	 {
		 NSString *subStr = [author substringWithRange:[match rangeAtIndex:1]];
		 onlyName = subStr;
		 *stop = YES;
	 }];
	
	return onlyName;
}

+ (CGSize)extractPhotoSizeFromDescription:(NSString *)description
{
	__block CGSize size = CGSizeMake(100, 100);
	NSError *error = nil;
	NSRegularExpression *regex;
	regex = [NSRegularExpression regularExpressionWithPattern:@"width=(\\d+)"
													  options:NSRegularExpressionCaseInsensitive
														error:&error];
	[regex enumerateMatchesInString:description
							options:0
							  range:NSMakeRange(0, [description length])
						 usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop)
	 {
		 NSString *subStr = [description substringWithRange:[match rangeAtIndex:1]];
		 size.width = [subStr intValue];
		 *stop = YES;
	 }];
	
	regex = [NSRegularExpression regularExpressionWithPattern:@"height=(\\d+)"
													  options:NSRegularExpressionCaseInsensitive
														error:&error];
	[regex enumerateMatchesInString:description
							options:0
							  range:NSMakeRange(0, [description length])
						 usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop)
	 {
		 NSString *subStr = [description substringWithRange:[match rangeAtIndex:1]];
		 size.height = [subStr intValue];
		 *stop = YES;
	 }];
	
	return size;
}

+ (NSDate*)dateFromTaken:(NSString *)stringDate
{
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setTimeStyle:NSDateFormatterFullStyle];
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
	[dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
	return [dateFormatter dateFromString:stringDate];
}

+ (NSDate*)dateFromPublished:(NSString *)stringDate
{
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setTimeStyle:NSDateFormatterFullStyle];
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
	[dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
	return [dateFormatter dateFromString:stringDate];
}
@end
