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
#import <objc/runtime.h>

@implementation AHGCollection
{
}

+ (void)mixinMethodsToClass:(Class)clazz
{
    NSParameterAssert([clazz conformsToProtocol:@protocol(NSFastEnumeration)]);
    
    unsigned int methodCount;
    Method *methods = class_copyMethodList([AHGCollection class], &methodCount);
    
    for (int i = 0; i < methodCount; i++) {
        SEL name = method_getName(methods[i]);
        
        // Don't overwrite the class's own implementation of the method (esp. for NSFastEnumeration)
        if (class_getInstanceMethod(clazz, name)) {
            continue;
        }
        class_addMethod(clazz, name, method_getImplementation(methods[i]), method_getTypeEncoding(methods[i]));
    }
    
    free(methods);
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])buffer
                                    count:(NSUInteger)len
{
    return 0;   // Not important - will be implemented by the real class at runtime
}

- (BOOL)isEmpty
{
    id obj;
    
    for (obj in self) {
        return NO;
    }
    
    return YES;
}

- (void)forEach:(void (^)(id anObject))block
{
	for (id obj in self) {
		block(obj);
	}
}

- (id)firstObject
{
    for (id obj in self) {
        return obj;
    }
    
    return nil;
}

#pragma mark Transforming a Collection

- (id<AHGCollection>)map:(AHGTransformBlock)transform
{
	// This enumeration object wraps the source collection with a transform function
	return [[AHGTransformEnumeration alloc] initWithSource:self	transform:transform];
}

- (id<AHGCollection>)flatMap:(AHGFlatMapBlock)transform
{
	return [[AHGFlatMapEnumeration alloc] initWithSource:self transform:transform];
}

- (id<AHGCollection>)filter:(AHGPredicateBlock)predicate
{
	return [[AHGFilterEnumeration alloc] initWithSource:self filter:predicate];
}

- (id<AHGCollection>)filterNot:(AHGPredicateBlock)predicate
{
    return [self filter:^BOOL(id obj) {
        return !predicate(obj);
    }];
}

- (id<AHGCollection>)slice:(NSUInteger)startIndex until:(NSUInteger)endIndex
{
    NSRange range = NSMakeRange(startIndex, endIndex - startIndex);
	return [[AHGRangeEnumeration alloc] initWithSource:self range:range];
}

- (id<AHGCollection>)sliceWithRange:(NSRange)range
{
	return [[AHGRangeEnumeration alloc] initWithSource:self range:range];
}

- (id)reduce:(id)startValue withOperator:(AHGFoldBlock)folder
{
    id result = startValue;
    
    for (id obj in self) {
        result = folder(result, obj);
    }
    
    return result;
}

#pragma mark Grouping and Sorting

- (NSDictionary *)groupBy:(AHGTransformBlock)transform
{
    NSMutableDictionary *newDict = [NSMutableDictionary dictionary];
    
    for (id obj in self) {
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

#pragma mark Testing objects in a Collection

- (id)find:(AHGPredicateBlock)predicate
{
    for (id obj in self) {
        if (predicate(obj)) {
            return obj;
        }
    }
    
    return (id) nil;
}

- (BOOL)exists:(AHGPredicateBlock)predicate
{
    for (id obj in self) {
        if (predicate(obj)) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)every:(AHGPredicateBlock)predicate
{
    for (id obj in self) {
        if (!predicate(obj)) {
            return NO;
        }
    }
        
    return YES;
}

#pragma mark Converting a Collection

- (NSArray *)allObjects
{
	NSMutableArray *array = [NSMutableArray array];
	
	for (id obj in self) {
		[array addObject:obj];
	}
	
	return [array copy];
}

- (NSSet *)setOfObjects
{
    NSMutableSet *set = [NSMutableSet set];
    
    for (id obj in self) {
        [set addObject:obj];
    }
    
    return [set copy];
}

- (NSString *)stringJoinedBy:(NSString *)separator
{
    NSMutableString *result = [NSMutableString string];
    BOOL appendSeparator = NO;  // Never the first time in the loop
    
    for (id obj in self) {
        if (appendSeparator) {
            [result appendString:separator];
        }

        [result appendString:[obj description]];
        appendSeparator = (separator != nil);
    }
    
    return [result copy];
}

@end

#pragma mark

@implementation AHGCollection (KeyValueCoding)

- (id<AHGCollection>)mapWithValueForKey:(NSString *)key
{
    // Use the built-in ability for collections such as NSArray and NSSet to create mapped collections.
    // This has the benefit of enforcing constraints within the new collection, such as an NSSet producing
    // a mapped collection with no duplicates. TODO: Fix when m_coll is an NSDictionary.
    //
    NSObject<AHGCollection> *newColl = [self valueForKey:key];
    NSAssert([newColl conformsToProtocol:@protocol(NSFastEnumeration)], @"Collection needs to implement valueForKey:");
    
    return newColl;
}

- (id<AHGCollection>)filterWithValueForKey:(NSString *)key
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

#pragma mark

@implementation NSArray (AHGCollection)

+ (void)load
{
    [AHGCollection mixinMethodsToClass:self];
}

- (NSArray *)allObjects
{
    return self;
}

@end

@implementation NSSet (AHGCollection)

+ (void)load
{
    [AHGCollection mixinMethodsToClass:self];
}

- (NSSet *)setOfObjects
{
    return self;
}

@end

@implementation NSOrderedSet (AHGCollection)

+ (void)load
{
    [AHGCollection mixinMethodsToClass:self];
}

@end
