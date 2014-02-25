//
//  AHGEnumerator.h
//  AHGCollection
//
//  Created by Andrew on 2/19/14.
//  Copyright (c) 2014 Andrew Goodale. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef id (^AHGTransformBlock)(id anObject);
typedef BOOL (^AHGPredicateBlock)(id anObject);
typedef id<NSFastEnumeration> (^AHGFlatMapBlock)(id anObject);

@interface AHGFastEnumeration : NSObject<NSCopying, NSFastEnumeration>

- (instancetype)initWithSource:(id<NSFastEnumeration>)source;

// Not for public use - subclasses should implement
- (NSUInteger)enumerateWithState:(NSFastEnumerationState *)state
					 sourceItems:(id __unsafe_unretained *)itemsPtr
						  buffer:(id __strong *)buffer;

@end

#pragma mark

/**
 * A fast enumeration that runs a transformation on the objects in the source enumeration.
 */
@interface AHGTransformEnumerator : AHGFastEnumeration

- (instancetype)initWithSource:(id<NSFastEnumeration>)source transform:(AHGTransformBlock)transform;

@end

#pragma mark

/**
 * A fast enumeration that runs a filter predicate on the objects in the source enumeration.
 */
@interface AHGFilterEnumerator : AHGFastEnumeration

- (instancetype)initWithSource:(id<NSFastEnumeration>)source filter:(AHGPredicateBlock)filter;

@end

#pragma mark

/**
 * A fast enumeration that flattens an enumeration of collections into a single enumeration.
 */
@interface AHGFlatMapEnumerator : AHGFastEnumeration

- (instancetype)initWithSource:(id<NSFastEnumeration>)source transform:(AHGFlatMapBlock)transform;

@end