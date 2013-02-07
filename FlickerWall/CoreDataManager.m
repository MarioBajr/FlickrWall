//
//  CoreDataManager.m
//  FlickerWall
//
//  Created by Mário Barbosa on 7/6/12.
//  Copyright (c) 2012 Mario Barbosa. All rights reserved.
//

#import "CoreDataManager.h"
#import "SynthesizeSingleton.h"


@interface CoreDataManager()
@property (strong, nonatomic) NSMutableArray *responseBlocks;
@property (strong, nonatomic) UIManagedDocument *document;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@end

@implementation CoreDataManager

@synthesize managedObjectContext;

#pragma mark - Singleton Mananger


+ (id)sharedCoreDataManager
{
	DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
		return [[self alloc] init];
	});
}

#pragma mark - Initializer

- (id)init
{
	self = [super init];
	
	if (self)
	{
		self.responseBlocks = [NSMutableArray array];
		
		NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
		url = [url URLByAppendingPathComponent:@"FlickrWall"];
		
		void (^__block InitializeDocument)(void) = ^ {
			self.document = [[UIManagedDocument alloc] initWithFileURL:url];
			// Set our document up for automatic migrations
			self.document.persistentStoreOptions = @{
				NSMigratePersistentStoresAutomaticallyOption : @(YES),
				NSInferMappingModelAutomaticallyOption : @(YES)
			};
		};
		
		void (^__block OnDocumentDidLoad)(BOOL) = ^(BOOL success) {
			if (!success)
			{
				NSError *error;
				[[NSFileManager defaultManager] removeItemAtURL:url error:&error];
				
				InitializeDocument();
				
				[self.document saveToURL:url
						forSaveOperation:UIDocumentSaveForCreating
					   completionHandler:^(BOOL success){
						   if (success)
							   [self documentIsReady];
					   }];
			}
			else
			{
				[self documentIsReady];
			}
		};
		
		InitializeDocument();
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:url.path])
		{
			[self.document openWithCompletionHandler:OnDocumentDidLoad];
		}
		else
		{
			[self.document saveToURL:url
					forSaveOperation:UIDocumentSaveForCreating
				   completionHandler:OnDocumentDidLoad];
		}
	}
	
	return self;
}

#pragma mark - Context Notifications

- (void)objectsDidChange:(NSNotification *)note
{
//	NSLog(@"Context Did Changed");
}

- (void)contextDidSave:(NSNotification *)note
{
//	NSLog(@"Context Did Save");
}

#pragma mark - Blocks

- (void)onCoreDataOpen:(CoreDataManagerResponseBlock) response
{
	if (self.managedObjectContext)
	{
		response();
	}
	else
	{
		[self.responseBlocks addObject:[response copy]];
	}
}

#pragma mark - StorageContexts Manager

- (void)saveContext
{
	[self.managedObjectContext saveContext];
}

- (void)rollbackContext
{
	[self.managedObjectContext rollbackContext];
}

#pragma mark - Read Document

- (void)documentIsReady
{
	if (self.document.documentState == UIDocumentStateNormal)
	{
		self.managedObjectContext = self.document.managedObjectContext;
		[self.managedObjectContext setStalenessInterval:0];
		
		// Register for notifications
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(objectsDidChange:)
													 name:NSManagedObjectContextObjectsDidChangeNotification
												   object:self.document.managedObjectContext];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(contextDidSave:)
													 name:NSManagedObjectContextDidSaveNotification
												   object:self.document.managedObjectContext];
	}
	
	for (CoreDataManagerResponseBlock block in self.responseBlocks)
		block();
	self.responseBlocks = nil;
}

@end