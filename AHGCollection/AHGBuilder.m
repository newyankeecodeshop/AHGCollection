//
//  AHGBuilder.m
//  AHGCollection
//
//  Created by Andrew on 1/2/2014.
//  Copyright (c) 2014 Andrew Goodale. All rights reserved.
//

#import "AHGBuilder.h"

@implementation AHGBuilder

static NSDictionary *s_builders = nil;

+ (void)initialize
{
    if (s_builders == nil) {
        s_builders = @{ NSStringFromClass([NSArray class]): [[AHGBuilderForArray alloc] init],
                        NSStringFromClass([NSSet class]): [[AHGBuilderForSet alloc] init] };
    }
}

+ (AHGBuilder *)builderFor:(Class)collectionClass
{
    if ([collectionClass isSubclassOfClass:[NSArray class]]) {
        return [s_builders objectForKey:NSStringFromClass([NSArray class])];
    }
    
    if ([collectionClass isSubclassOfClass:[NSSet class]]) {
        return [s_builders objectForKey:NSStringFromClass([NSSet class])];
    }
    
    return [s_builders objectForKey:NSStringFromClass(collectionClass)];
}

+ (void)registerBuilder:(AHGBuilder *)builder forClass:(Class)collectionClass
{
    NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithDictionary:s_builders];
    [newDict setObject:builder forKey:NSStringFromClass(collectionClass)];
    
    s_builders = [newDict copy];
}

- (id)newMutableColl:(id)sourceColl
{
    NSAssert(NO, @"Missing override for [AHGBuilder newMutableColl:]");
    return nil;
}

- (void)addObject:(id)anObject toMutableColl:(id)mutableColl
{
    NSAssert(NO, @"Missing override for [AHGBuilder addObject:toMutableColl:]");
}

@end

#pragma mark -

@implementation AHGBuilderForArray

- (id)newMutableColl:(NSArray *)sourceColl
{
    return [[NSMutableArray alloc] initWithCapacity:sourceColl.count];
}

- (void)addObject:(id)anObject toMutableColl:(NSMutableArray *)mutableArray
{
    [mutableArray addObject:anObject];
}

@end

#pragma mark -

@implementation AHGBuilderForSet

- (id)newMutableColl:(NSSet *)sourceColl
{
    return [[NSMutableSet alloc] initWithCapacity:sourceColl.count];
}

- (void)addObject:(id)anObject toMutableColl:(NSMutableSet *)mutableSet
{
    [mutableSet addObject:anObject];
}

@end
