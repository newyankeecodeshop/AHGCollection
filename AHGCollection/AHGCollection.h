//
//  AHGCollection.h
//  AHGCollection
//
//  Created by Andrew on 12/30/2013.
//  Copyright (c) 2013 Andrew Goodale. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSObject<NSCopying, NSFastEnumeration> AHGEnumerable;

typedef id (^AHGTransformBlock)(id anObject);
typedef id (^AHGFoldBlock)(id resultObject, id anObject);
typedef id<NSFastEnumeration> (^AHGFlatMapBlock)(id anObject);
typedef BOOL (^AHGPredicateBlock)(id anObject);

/**
 * A class which provides functional programming operations on various Foundation collection classes.
 */
@interface AHGCollection : NSObject <NSCopying, NSFastEnumeration>

/* Test if the underlying collection has at least one element */
@property (readonly, nonatomic, getter = isEmpty) BOOL empty;

- (id)initWithCollection:(AHGEnumerable *)collection;

/* Create a new collection by applying a transform to all elements in this collection */
- (AHGCollection *)map:(AHGTransformBlock)transform;

/* Create a new collection by collapsing a list of values for each element in this collection */
- (AHGCollection *)flatMap:(AHGFlatMapBlock)transform;

/* Return a new collection with elements that pass the predicate test */
- (AHGCollection *)filter:(AHGPredicateBlock)predicate;

/* Return a new collection with elements that fail the predicate test */
- (AHGCollection *)filterNot:(AHGPredicateBlock)predicate;

/* Reduce a collection to a single value using an optional start value */
- (id)foldLeft:(id)startValue operator:(AHGFoldBlock)folder;

/* Return a dictionary of arrays containing values using the transform block to generate keys */
- (NSDictionary *)groupBy:(AHGTransformBlock)transform;

/* Return the first value in the collection where predicate is true */
- (id)find:(AHGPredicateBlock)predicate;

/* Tests whether predicate is true for any value in the collection */
- (BOOL)exists:(AHGPredicateBlock)predicate;

/* Tests whether predicate is true for all values in the collection */
- (BOOL)every:(AHGPredicateBlock)predicate;

/* Returns an array containing the members of this collection */
- (NSArray *)allObjects;

@end

/**
 * Create a Collection with an existing Foundation collection.
 */
AHGCollection *AHGNewColl(AHGEnumerable *coll);

/**
 * A category that adds operations using KVC key names instead of blocks.
 */
@interface AHGCollection (KeyValueCoding)

/* Return a new collection containing the [valueForKey:] for each element in this collection */
- (AHGCollection *)mapWithKey:(NSString *)key;

/* Return a new collection containing elements that have a property value of YES or non-nil for the given key */
- (AHGCollection *)filterWithKey:(NSString *)key;

/* Return a dictionary whose keys are the [valueForKey:] for each element in this collection */
- (NSDictionary *)groupByKey:(NSString *)key;

@end
