/*
 AHGCollection.m
 
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

#import "AHGCollection.h"
#import "AHGEnumeration.h"

AHGCollection *AHGNewColl(AHGCoreCollection *coll)
{
    return [[AHGCollection alloc] initWithCollection:coll];
}

#pragma mark

@implementation AHGCollection
{
    NSObject<NSFastEnumeration> *m_coll;
}

- (id)initWithCollection:(AHGCoreCollection *)collection
{
    if ((self = [super init])) {
        m_coll = [collection copy];
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])buffer
                                    count:(NSUInteger)len
{
    return [m_coll countByEnumeratingWithState:state objects:buffer count:len];
}

- (BOOL)isEmpty
{
    id obj;
    
    for (obj in m_coll) {
        return NO;
    }
    
    return YES;
}

- (void)forEach:(void (^)(id anObject))block
{
	for (id obj in m_coll) {
		block(obj);
	}
}

#pragma mark Transforming a Collection

- (AHGCollection *)map:(AHGTransformBlock)transform
{
	// This enumeration object wraps the source collection with a transform function
	AHGTransformEnumeration *transformer = [[AHGTransformEnumeration alloc] initWithSource:m_coll
																			   transform:transform];
	return [[AHGCollection alloc] initWithCollection:transformer];
}

- (AHGCollection *)flatMap:(AHGFlatMapBlock)transform
{
	AHGFlatMapEnumeration *flatMapper = [[AHGFlatMapEnumeration alloc] initWithSource:m_coll
																		  transform:transform];
	return [[AHGCollection alloc] initWithCollection:flatMapper];
}

- (AHGCollection *)filter:(AHGPredicateBlock)predicate
{
	AHGFilterEnumeration *filter = [[AHGFilterEnumeration alloc] initWithSource:m_coll
																	   filter:predicate];
	return [[AHGCollection alloc] initWithCollection:filter];
}

- (AHGCollection *)filterNot:(AHGPredicateBlock)predicate
{
    return [self filter:^BOOL(id obj) {
        return !predicate(obj);
    }];
}

- (AHGCollection *)slice:(NSUInteger)startIndex until:(NSUInteger)endIndex
{
    NSRange range = NSMakeRange(startIndex, endIndex - startIndex);
	AHGRangeEnumeration *rangeEnum = [[AHGRangeEnumeration alloc] initWithSource:m_coll range:range];
    
	return [[AHGCollection alloc] initWithCollection:rangeEnum];
}

- (AHGCollection *)sliceWithRange:(NSRange)range
{
	AHGRangeEnumeration *rangeEnum = [[AHGRangeEnumeration alloc] initWithSource:m_coll range:range];
    
	return [[AHGCollection alloc] initWithCollection:rangeEnum];    
}

- (id)reduce:(id)startValue withOperator:(AHGFoldBlock)folder
{
    id result = startValue;
    
    for (id obj in m_coll) {
        result = folder(result, obj);
    }
    
    return result;
}

#pragma mark Grouping and Sorting

- (NSDictionary *)groupBy:(AHGTransformBlock)transform
{
    NSMutableDictionary *newDict = [NSMutableDictionary dictionary];
    
    for (id obj in m_coll) {
        id key = transform(obj);
        NSMutableArray *group = [newDict objectForKey:key];
        
        if (group == nil) {
            group = [NSMutableArray array];
            [newDict setObject:group forKey:key];
        }
        
        [group addObject:obj];
    }
    
    return [newDict copy];
}

- (id)find:(AHGPredicateBlock)predicate
{
    for (id obj in m_coll) {
        if (predicate(obj)) {
            return obj;
        }
    }
    
    return (id) nil;
}

- (BOOL)exists:(AHGPredicateBlock)predicate
{
    for (id obj in m_coll) {
        if (predicate(obj)) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)every:(AHGPredicateBlock)predicate
{
    for (id obj in m_coll) {
        if (!predicate(obj)) {
            return NO;
        }
    }
        
    return YES;
}

- (NSArray *)allObjects
{
	// If the backing collection is already an array, we can return it.
	if ([m_coll isKindOfClass:[NSArray class]]) {
		return (NSArray *)m_coll;
	}
	
	NSMutableArray *array = [NSMutableArray array];
	
	for (id obj in m_coll) {
		[array addObject:obj];
	}
	
	return [array copy];
}

- (NSSet *)setOfObjects
{
    NSMutableSet *set = [NSMutableSet set];
    
    for (id obj in m_coll) {
        [set addObject:obj];
    }
    
    return [set copy];
}

@end

#pragma mark

@implementation AHGCollection (KeyValueCoding)

- (AHGCollection *)mapWithValueForKey:(NSString *)key
{
    // Use the built-in ability for collections such as NSArray and NSSet to create mapped collections.
    // This has the benefit of enforcing constraints within the new collection, such as an NSSet producing
    // a mapped collection with no duplicates. TODO: Fix when m_coll is an NSDictionary.
    //
    AHGCoreCollection *newColl = [m_coll valueForKey:key];
    NSAssert([newColl conformsToProtocol:@protocol(NSFastEnumeration)], @"Collection needs to implement valueForKey:");
    
    return [[AHGCollection alloc] initWithCollection:newColl];
}

- (AHGCollection *)filterWithValueForKey:(NSString *)key
{
    return [self filter:^BOOL(id obj) {
        id value = [obj valueForKey:key];

        // If the property is a NSNumber or NSString, the boolValue call is what we want.
        //
        if ([value respondsToSelector:@selector(boolValue)]) {
            return [value boolValue];
        }
        return value != nil;    // Check for [NSNull null]?
    }];
}

- (NSDictionary *)groupByValueForKey:(NSString *)key
{
    return [self groupBy:^id(id obj) {
        id value = [obj valueForKey:key];
        
        return value ? value : [NSNull null];   // Return [NSNull null] for nil because keys can't be nil
    }];
}

@end

