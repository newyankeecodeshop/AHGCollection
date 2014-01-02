//
//  AHGCollection.h
//  AHGCollection
//
//  Created by Andrew (Wingspan) on 12/30/2013.
//  Copyright (c) 2013 Andrew Goodale. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSObject<NSCopying, NSFastEnumeration> AHGEnumerable;

typedef id (^AHGTransformBlock)(id obj);
typedef AHGEnumerable* (^AHGEnumerateBlock)(id obj);

@class AHGBuilder;

/**
 * A class which provides functional programming operations on various Foundation collection classes.
 */
@interface AHGCollection : NSObject <NSCopying, NSFastEnumeration>

@property (readonly, nonatomic) id  collection;

@property (readonly, nonatomic) NSUInteger  size;

- (id)initWithCollection:(AHGEnumerable *)collection builder:(AHGBuilder *)builder;

- (AHGCollection *)map:(AHGTransformBlock)transform;
- (AHGCollection *)flatMap:(AHGEnumerateBlock)transform;

@end

/**
 * Create a Collection with an existing Foundation collection.
 */
AHGCollection *AHGNewColl(AHGEnumerable *coll);
