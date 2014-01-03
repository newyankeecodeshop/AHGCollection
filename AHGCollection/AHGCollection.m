//
//  AHGCollection.m
//  AHGCollection
//
//  Created by Andrew (Wingspan) on 12/30/2013.
//  Copyright (c) 2013 Andrew Goodale. All rights reserved.
//

#import "AHGCollection.h"
#import "AHGBuilder.h"

@implementation AHGCollection
{
    AHGEnumerable *m_coll;
    AHGBuilder    *m_builder;
}

- (id)initWithCollection:(AHGEnumerable *)collection builder:(AHGBuilder *)builder
{
    if ((self = [super init])) {
        m_coll = [collection copy];
        m_builder = builder;
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(__unsafe_unretained id [])buffer
                                    count:(NSUInteger)len
{
    return [m_coll countByEnumeratingWithState:state objects:buffer count:len];
}

- (id)collection
{
    return m_coll;
}

- (BOOL)isEmpty
{
    for (id obj in m_coll) {
        return NO;
    }
    
    return YES;
}

#pragma mark Collection Transformations

- (AHGCollection *)map:(AHGTransformBlock)transform
{
    AHGEnumerable *newColl = [m_builder newMutableColl:m_coll];
    
    for (id obj in m_coll) {
        [m_builder addObject:transform(obj) toMutableColl:newColl];
    };
    
    return [[AHGCollection alloc] initWithCollection:newColl builder:m_builder];
}

- (AHGCollection *)flatMap:(AHGEnumerateBlock)transform
{
    AHGEnumerable *newColl = [m_builder newMutableColl:m_coll];
    
    for (id obj in m_coll) {
        for (id value in transform(obj)) {
            [m_builder addObject:value toMutableColl:newColl];
        }
    }
    
    return [[AHGCollection alloc] initWithCollection:newColl builder:m_builder];
}

- (AHGCollection *)filter:(AHGPredicateBlock)predicate
{
    AHGEnumerable *newColl = [m_builder newMutableColl:m_coll];
    
    for (id obj in m_coll) {
        if (predicate(obj)) {
            [m_builder addObject:obj toMutableColl:newColl];
        }
    };
    
    return [[AHGCollection alloc] initWithCollection:newColl builder:m_builder];
}

- (AHGCollection *)filterNot:(AHGPredicateBlock)predicate
{
    return [self filter:^BOOL(id obj) {
        return !predicate(obj);
    }];
}

- (NSDictionary *)groupBy:(AHGTransformBlock)transform
{
    NSMutableDictionary *newDict = [NSMutableDictionary dictionary];
    
    for (id obj in m_coll) {
        id key = transform(obj);
        AHGEnumerable *group = [newDict objectForKey:key];
        
        if (group == nil) {
            group = [m_builder newMutableColl:m_coll];
            [newDict setObject:group forKey:key];
        }
        
        [m_builder addObject:obj toMutableColl:group];
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

@end

#pragma mark

AHGCollection *AHGNewColl(AHGEnumerable *coll)
{
    return [[AHGCollection alloc] initWithCollection:coll
                                             builder:[AHGBuilder builderFor:[coll class]]];
}

#pragma mark

@implementation AHGCollection (KeyValueCoding)

- (AHGCollection *)mapWithKey:(NSString *)key
{
    // Categories on NSArray and NSSet cause this call to do the right thing for mapping here.
    //
    id newColl = [m_coll valueForKey:key];
    
    return [[AHGCollection alloc] initWithCollection:newColl builder:m_builder];
}

- (AHGCollection *)filterWithKey:(NSString *)key
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

- (NSDictionary *)groupByKey:(NSString *)key
{
    return [self groupBy:^id(id obj) {
        return [obj valueForKey:key];   // Return [NSNull null] for nil?
    }];
}

@end

