/*
 AHGEnumeration.h
 
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

typedef id (^AHGTransformBlock)(id anObject);
typedef BOOL (^AHGPredicateBlock)(id anObject);
typedef id<NSFastEnumeration> (^AHGFlatMapBlock)(id anObject);

/**
 * A base class for implementing an `NSFastEnumeration` in terms of a source collection. This class provides
 * an internal buffer for temporary objects created during the enumeration process. It is used when
 */
@interface AHGFastEnumeration : NSObject<NSFastEnumeration>

/** @name Initializing the Enumeration */

/**
 * The designated initializer.
 * 
 * @param source The collection being wrapped by this enumeration.
 */
- (instancetype)initWithSource:(id<NSFastEnumeration>)source;

/** @name Enumeration */

/**
 * Not for public use - subclasses should implement this method and populate the buffer `NSFastEnumerationState` with
 * objects. The buffer is provided to store temporary objects whose lifetime is not managed by the source collection.
 *
 * @param state The current enumeration state
 * @param itemsPtr Items from the wrapped collection in this state
 * @param buffer A 16-slot buffer to store temporary objects
 */
- (NSUInteger)enumerateWithState:(NSFastEnumerationState *)state
					 sourceItems:(id __unsafe_unretained *)itemsPtr
						  buffer:(id __strong *)buffer;

@end

#pragma mark

/**
 * A fast enumeration that runs a transformation on the objects in the source enumeration.
 */
@interface AHGTransformEnumeration : AHGFastEnumeration

/** @name Initializing the Enumeration */

/**
 * The designated initializer.
 *
 * @param source The collection being wrapped by this enumeration.
 * @param transform A block that transforms objects from the source collection.
 */
- (instancetype)initWithSource:(id<NSFastEnumeration>)source transform:(AHGTransformBlock)transform;

@end

#pragma mark

/**
 * A fast enumeration that runs a filter predicate on the objects in the source enumeration.
 */
@interface AHGFilterEnumeration : AHGFastEnumeration

/** @name Initializing the Enumeration */

/**
 * The designated initializer.
 *
 * @param source The collection being wrapped by this enumeration.
 * @param filter A block that evaulates a predicate for objects in the source.
 */
- (instancetype)initWithSource:(id<NSFastEnumeration>)source filter:(AHGPredicateBlock)filter;

@end

#pragma mark

/**
 * A fast enumeration that flattens an enumeration of collections into a single enumeration.
 */
@interface AHGFlatMapEnumeration : AHGFastEnumeration

/** @name Initializing the Enumeration */

/**
 * The designated initializer.
 *
 * @param source The collection being wrapped by this enumeration.
 * @param transform A block that maps objects to an enumerable object.
 */
- (instancetype)initWithSource:(id<NSFastEnumeration>)source transform:(AHGFlatMapBlock)transform;

@end