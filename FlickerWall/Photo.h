//
//  Photo.h
//  FlickerWall
//
//  Created by Mario Barbosa on 2/5/13.
//  Copyright (c) 2013 Mario. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Photo : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * link;
@property (nonatomic, retain) NSString * media;
@property (nonatomic, retain) NSDate * dateTaken;
@property (nonatomic, retain) NSDate * published;
@property (nonatomic, retain) NSString * author;
@property (nonatomic, retain) NSString * authorID;
@property (nonatomic, retain) NSString * tags;
@property (nonatomic, retain) NSNumber * width;
@property (nonatomic, retain) NSNumber * height;

@end
