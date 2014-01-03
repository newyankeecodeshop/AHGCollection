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
typedef BOOL (^AHGPredicateBlock)(id obj);

@class AHGBuilder;

/**
 * A class which provides functional programming operations on various Foundation collection classes.
 */
@interface AHGCollection : NSObject <NSCopying, NSFastEnumeration>

/* Return the underlying Foundation collection */
@property (readonly, nonatomic) id  collection;

/* Test if the underlying collection has at least one element */
@property (readonly, nonatomic, getter = isEmpty) BOOL empty;

- (id)initWithCollection:(AHGEnumerable *)collection builder:(AHGBuilder *)builder;

- (AHGCollection *)map:(AHGTransformBlock)transform;
- (AHGCollection *)flatMap:(AHGEnumerateBlock)transform;

- (AHGCollection *)filter:(AHGPredicateBlock)predicate;
- (AHGCollection *)filterNot:(AHGPredicateBlock)predicate;

/* Return a dictionary of arrays containing values using the transform block to generate keys */
- (NSDictionary *)groupBy:(AHGTransformBlock)transform;

/* Return the first value in the collection where predicate is true */
- (id)find:(AHGPredicateBlock)predicate;

/* Tests whether predicate is true for any value in the collection */
- (BOOL)exists:(AHGPredicateBlock)predicate;

/* Tests whether predicate is true for all values in the collection */
- (BOOL)every:(AHGPredicateBlock)predicate;

@end

/**
 * Create a Collection with an existing Foundation collection.
 */
AHGCollection *AHGNewColl(AHGEnumerable *coll);

/**
 * A category that adds operations using KVC key names instead of blocks.
 */
@interface AHGCollection (KeyValueCoding)

- (AHGCollection *)mapWithKey:(NSString *)key;

- (AHGCollection *)filterWithKey:(NSString *)key;

- (NSDictionary *)groupByKey:(NSString *)key;

@end
