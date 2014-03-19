/*
 AHGCollection.h
 
 Copyright (c) 2014 Andrew H. Goodale
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
*/

#import <Foundation/Foundation.h>

// Foundation collections implement these two protocols
typedef NSObject<NSCopying, NSFastEnumeration> AHGCoreCollection;

typedef id (^AHGTransformBlock)(id anObject);
typedef id (^AHGFoldBlock)(id resultObject, id anObject);
typedef id<NSFastEnumeration> (^AHGFlatMapBlock)(id anObject);
typedef BOOL (^AHGPredicateBlock)(id anObject);

/**
 *  A class which provides functional programming operations on various Foundation collection classes.
 */
@interface AHGCollection : NSObject <NSCopying, NSFastEnumeration>

/** @name Properties */

/**
 *  Test if the underlying collection has at least one element
 */
@property (readonly, nonatomic, getter=isEmpty) BOOL empty;

/** @name Initializing a Collection */

/**
 *  Initializes an `AHGCollection` instance with a backing collection. If the collection is mutable, the `copy` method
 *  will be invoked so that an immutable collection is referenced by this object.
 *
 *  @param collection An enumerable object, typically a Foundation collection.
 *  @return A new collection object
 */
- (id)initWithCollection:(AHGCoreCollection *)collection;

/** @name Basic Iteration */

/**
 *  A basic iteration through the objects in the collection.
 *  The block can break out of the loop early by setting the `stop` parameter to `YES`.
 *
 *  @param block The block to execute for each object in the collection.
 */
- (void)forEach:(void (^)(id obj, BOOL *stop))block;

/** @name Transforming a Collection */

/**
 *  Creates a new collection by applying a transform to all elements in this collection.
 *
 *  @param transform A block that transforms values in the collection.
 *  @return A mapped collection.
 */
- (AHGCollection *)map:(AHGTransformBlock)transform;

/**
 *  Creates a new collection by collapsing a list of values for each element in this collection.
 *
 *  @param transform A block that returns a collection for each object.
 *  @return A mapped collection.
 */
- (AHGCollection *)flatMap:(AHGFlatMapBlock)transform;

/**
 *  Creates a new collection with elements that pass the predicate test.
 *
 *  @param predicate A block that tests each object in the collection.
 *  @return A filtered collection.
 */
- (AHGCollection *)filter:(AHGPredicateBlock)predicate;

/**
 *  Creates a new collection with elements that fail the predicate test.
 *
 *  @param predicate A block that tests each object in the collection.
 *  @return A filtered collection.
 */
- (AHGCollection *)filterNot:(AHGPredicateBlock)predicate;

/** 
 *  Reduce a collection to a single value using an optional start value.
 *
 *  @param startValue An initial value to pass to the operator block.
 *  @param block A block that returns a new value based on each object in the collection.
 *  @return The result of the reduction.
 */
- (id)reduce:(id)startValue withOperator:(AHGFoldBlock)block;

/** 
 *  Group objects in this collection using a function that maps each object to a key.
 *
 *  @param transform A block that returns a key value for each object in the collection.
 *  @return A dictionary where each key points to an array of values from the collection.
 */
- (NSDictionary *)groupBy:(AHGTransformBlock)transform;

/** @name Testing objects in a Collection */

/**
 *  Return the first value in the collection where predicate is true.
 *
 *  @param predicate A block that tests objects in the collection.
 */
- (id)find:(AHGPredicateBlock)predicate;

/**
 *  Tests whether predicate is true for any value in the collection.
 *
 *  @param predicate A block that tests objects in the collection.
 */
- (BOOL)exists:(AHGPredicateBlock)predicate;

/**
 *  Tests whether predicate is true for all values in the collection.
 *
 *  @param predicate A block that tests objects in the collection.
 */
- (BOOL)every:(AHGPredicateBlock)predicate;

/** @name Converting a Collection */

/** 
 *  Returns an array containing the members of this collection.
 */
- (NSArray *)allObjects;

/**
 *  Returns a set containing the members of this collection. Since sets do not allow duplicates,
 *  the size of the set may be smaller than the size of this collection.
 *
 *  @return An immutable set
 */
- (NSSet *)setOfObjects;

@end

/*
 * Create a Collection with an existing Foundation collection.
 *
 * @param coll A collection of objects.
 */
AHGCollection *AHGNewColl(AHGCoreCollection *coll);

#pragma mark

@interface AHGCollection (KeyValueCoding)

/**
 *  Return a new collection containing the `valueForKey:` for each object in this collection.
 *
 *  @param key The key used to lookup the map value.
 */
- (AHGCollection *)mapWithKeyValue:(NSString *)key;

/**
 *  Return a new collection containing elements that have a property value of YES or non-nil for the given key.
 *
 *  @param key The key used to lookup the filter value.
 */
- (AHGCollection *)filterWithKeyValue:(NSString *)key;

/**
 *  Return a dictionary whose keys are the `valueForKey:` for each element in this collection.
 *
 *  @param key The key used to lookup the grouping value.
 */
- (NSDictionary *)groupByKeyValue:(NSString *)key;

@end
