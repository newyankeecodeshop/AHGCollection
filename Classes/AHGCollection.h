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

/* Signatures for the various blocks used in this protocol */
typedef id (^AHGTransformBlock)(id anObject);
typedef id (^AHGFoldBlock)(id resultObject, id anObject);
typedef id<NSFastEnumeration> (^AHGFlatMapBlock)(id anObject);
typedef BOOL (^AHGPredicateBlock)(id anObject);

@class AHGTuple;

/**
 *  A class which provides functional programming operations on various Foundation collection classes.
 */
@protocol AHGCollection <NSFastEnumeration>
@optional

/** @name Properties */

/**
 *  Test if the underlying collection has at least one element
 */
@property (readonly, nonatomic, getter=isEmpty) BOOL empty;

/** @name Basic Iteration */

/**
 *  A basic iteration through the objects in the collection.
 *
 *  @param block The block to execute for each object in the collection.
 */
- (void)forEach:(void (^)(id anObject))block;

/**
 * Returns the first object (if any) in an ordered collection and returns an arbitrary value for an unordered collection (e.g. `NSSet`).
 *
 *  @return The first object
 */
- (id)firstObject;

/** @name Transforming a Collection */

/**
 *  Creates a new collection by applying a transform to all elements in this collection.
 *
 *  @param transform A block that transforms values in the collection.
 *  @return A mapped collection.
 */
- (id<AHGCollection>)map:(AHGTransformBlock)transform;

/**
 *  Creates a new collection by collapsing a list of values for each element in this collection.
 *
 *  @param transform A block that returns a collection for each object.
 *  @return A mapped collection.
 */
- (id<AHGCollection>)flatMap:(AHGFlatMapBlock)transform;

/**
 *  Creates a new collection with elements that pass the predicate test.
 *
 *  @param predicate A block that tests each object in the collection.
 *  @return A filtered collection.
 */
- (id<AHGCollection>)filter:(AHGPredicateBlock)predicate;

/**
 *  Creates a new collection with elements that fail the predicate test.
 *
 *  @param predicate A block that tests each object in the collection.
 *  @return A filtered collection.
 */
- (id<AHGCollection>)filterNot:(AHGPredicateBlock)predicate;

/**
 *  Creates a collection containing the objects from `startIndex` up to (but not including) `endIndex`. This method does not validate that the startIndex is within the range of the collecton. If the startIndex is greater than the count of elements,
 *  the resulting collection will be empty.
 *
 *  @param startIndex The index of the first element to extract
 *  @param endIndex   The index at which to stop extraction
 */
- (id<AHGCollection>)slice:(NSUInteger)startIndex until:(NSUInteger)endIndex;

/**
 *  Creates a collection containing objects that fall within the given range. Like `slice:until`, an empty collection is returned if the range falls outside the limits of this collection.
 *
 *  @param range A range within this collection's enumeration
 */
- (id<AHGCollection>)sliceWithRange:(NSRange)range;

/** 
 *  Reduce a collection to a single value using an optional start value.
 *
 *  @param startValue An initial value to pass to the operator block.
 *  @param block A block that returns a new value based on each object in the collection.
 *  @return The result of the reduction.
 */
- (id)reduce:(id)startValue withOperator:(AHGFoldBlock)block;

/** @name Grouping and Sorting */

/** 
 *  Group objects in this collection using a function that maps each object to a key.
 *
 *  @param transform A block that returns a key value for each object in the collection.
 *  @return A dictionary where each key points to an array of values from the collection.
 */
- (NSDictionary *)groupBy:(AHGTransformBlock)transform;

/**
 *  Split the collection into two collections, one with elements that satisfy the predicate,
 *  the other with elements that do not.
 *
 *  @param predicate A block that tests objects in the collection.
 */
- (AHGTuple *)partition:(AHGPredicateBlock)predicate;

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

/**
 *  Returns a string composed of all values in this collection, with an optional separator.
 *
 *  @return A string composed of all values. If the collection is empty, the string is the empty string.
 */
- (NSString *)stringJoinedBy:(NSString *)separator;


/** @name Key-Value Coding */

/**
 *  Return a new collection containing the `valueForKey:` for each object in this collection.
 *
 *  @param key The key used to lookup the map value.
 */
- (id<AHGCollection>)mapWithValueForKey:(NSString *)key;

/**
 *  Return a new collection containing elements that have a property value of YES or non-nil for the given key.
 *
 *  @param key The key used to lookup the filter value.
 */
- (id<AHGCollection>)filterWithValueForKey:(NSString *)key;

/**
 *  Return a dictionary whose keys are the `valueForKey:` for each element in this collection.
 *
 *  @param key The key used to lookup the grouping value.
 */
- (NSDictionary *)groupByValueForKey:(NSString *)key;

@end

#pragma mark - Tuple

@interface AHGTuple : NSObject

@property (readonly, nonatomic) id first;
@property (readonly, nonatomic) id second;

- (instancetype)initWithFirst:(id)first second:(id)second;

@end

#pragma mark - Concrete implementation

@interface AHGCollection : NSObject <AHGCollection>

/**
 * Provides a mechanism to mixin the implementation of `AHGCollection` to other classes that implement NSFastEnumeration.
 */
+ (void)mixinMethodsToClass:(Class)clazz;

@end

#pragma mark - Mixin to Foundation collections

@interface NSArray (AHGCollection) <AHGCollection>

@end

@interface NSSet (AHGCollection) <AHGCollection>

@end

@interface NSOrderedSet (AHGCollection) <AHGCollection>

@end
