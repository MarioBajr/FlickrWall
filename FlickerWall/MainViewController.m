//
//  MainViewController.m
//  FlickerWall
//
//  Created by Mario Barbosa on 2/5/13.
//  Copyright (c) 2013 Mario. All rights reserved.
//

#import "MainViewController.h"
#import "CoreDataManager.h"
#import "Photo.h"
#import "PhotoCell.h"
#import "ConnectionManager.h"
#import "NSManagedObjectContext+Extensions.h"
#import "UIImage+Extensions.h"
#import "SDImageCache.h"
#import <CoreData/CoreData.h>

@interface MainViewController ()<NSFetchedResultsControllerDelegate>
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (weak, nonatomic) UIRefreshControl *refreshControl;
@end

@implementation MainViewController
{
	NSMutableArray *objectChanges;
    NSMutableArray *sectionChanges;
	BOOL isFetchingData;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	isFetchingData = NO;
	self.clearsSelectionOnViewWillAppear = YES;
	
	[[CoreDataManager sharedCoreDataManager] onCoreDataOpen:^{
		[self refresh];
		[self.collectionView reloadData];
	}];
	
	UIRefreshControl *refreshControl = UIRefreshControl.alloc.init;
	[refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
	[self.collectionView addSubview:refreshControl];
	self.refreshControl = refreshControl;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
	[[SDImageCache sharedImageCache] clearMemory];
}

- (void)dealloc
{
	_fetchedResultsController.delegate = nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([[segue.destinationViewController class] isSubclassOfClass:[UINavigationController class]])
	{
		UINavigationController *navigationController = (UINavigationController *)segue.destinationViewController;
		
		if ([navigationController.visibleViewController respondsToSelector:@selector(setPhoto:)])
		{
			NSIndexPath *indexPath = [self.collectionView.indexPathsForSelectedItems lastObject];
			Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
			[navigationController.visibleViewController performSelector:@selector(setPhoto:) withObject:photo]
			;
		}
	}
}

#pragma mark - Request Logic

- (void)refresh
{
	if (isFetchingData)
		return;
	
	isFetchingData = YES;
	[ConnectionManager fetchWithCompletionHandler:^(BOOL success){
		isFetchingData = NO;
		[self.refreshControl endRefreshing];
	}];
}

#pragma mark - UICollectionViewDelegate Methods

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	return !isFetchingData;
}

#pragma mark - UICollectionViewDataSource Methods

- (NSInteger)collectionView:(UICollectionView *)collectionView
	 numberOfItemsInSection:(NSInteger)section
{
	return [[[self.fetchedResultsController sections] objectAtIndex:section] numberOfObjects];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [[self.fetchedResultsController sections] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
				  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor whiteColor];
	
	PhotoCell *photoCell = (PhotoCell *)cell;
	Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
	photoCell.photo = photo;
	
    return cell;
}

#pragma mark – UICollectionViewDelegateFlowLayout Methods

- (CGSize)collectionView:(UICollectionView *)collectionView
				  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
	Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
	CGSize size = CGSizeMake([photo.width integerValue], [photo.height integerValue]);
	CGSize bounds = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)?
	CGSizeMake(200, 200) : CGSizeMake(145, 145);
	
	size = [UIImage scaleToFit:size withBounds:bounds];
	return size;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
						layout:(UICollectionViewLayout*)collectionViewLayout
		insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(10, 10, 10, 10);
}

#pragma mark - NSFetchedResultsController Methods

- (NSFetchedResultsController *)fetchedResultsController
{
	if (_fetchedResultsController)
		return _fetchedResultsController;
	
	NSManagedObjectContext *context = [[CoreDataManager sharedCoreDataManager] managedObjectContext];
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"published" ascending:NO];
	_fetchedResultsController = [context fetchedResultsControllerFromClass:[Photo class]
														withSortDescriptor:@[sortDescriptor]
															 withPredicate:nil];
	_fetchedResultsController.delegate = self;
	return _fetchedResultsController;
}

//Code based on https://github.com/AshFurrow/UICollectionView-NSFetchedResultsController
- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    
    NSMutableDictionary *change = [NSMutableDictionary new];
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = @(sectionIndex);
            break;
        case NSFetchedResultsChangeDelete:
            change[@(type)] = @(sectionIndex);
            break;
    }
    
    [sectionChanges addObject:change];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    
    NSMutableDictionary *change = [NSMutableDictionary new];
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = newIndexPath;
            break;
        case NSFetchedResultsChangeDelete:
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeUpdate:
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeMove:
            change[@(type)] = @[indexPath, newIndexPath];
            break;
    }
    [objectChanges addObject:change];
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
	objectChanges = [NSMutableArray array];
    sectionChanges = [NSMutableArray array];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if ([sectionChanges count] > 0)
    {
        [self.collectionView performBatchUpdates:^{
            
            for (NSDictionary *change in sectionChanges)
            {
                [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                    
                    NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                    switch (type)
                    {
                        case NSFetchedResultsChangeInsert:
                            [self.collectionView insertSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                            break;
                        case NSFetchedResultsChangeDelete:
                            [self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                            break;
                        case NSFetchedResultsChangeUpdate:
                            [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                            break;
                    }
                }];
            }
        } completion:nil];
    }
    
    if ([objectChanges count] > 0 && [sectionChanges count] == 0)
    {
        [self.collectionView performBatchUpdates:^{
            
            for (NSDictionary *change in objectChanges)
            {
                [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                    
                    NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                    switch (type)
                    {
                        case NSFetchedResultsChangeInsert:
                            [self.collectionView insertItemsAtIndexPaths:@[obj]];
                            break;
                        case NSFetchedResultsChangeDelete:
                            [self.collectionView deleteItemsAtIndexPaths:@[obj]];
                            break;
                        case NSFetchedResultsChangeUpdate:
                            [self.collectionView reloadItemsAtIndexPaths:@[obj]];
                            break;
                        case NSFetchedResultsChangeMove:
                            [self.collectionView moveItemAtIndexPath:obj[0] toIndexPath:obj[1]];
                            break;
                    }
                }];
            }
        } completion:nil];
    }
    
    [sectionChanges removeAllObjects];
    [objectChanges removeAllObjects];
}


@end
