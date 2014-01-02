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

- (NSUInteger)size
{
    return [[m_coll performSelector:@selector(count)] unsignedIntegerValue];
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

@end

#pragma mark

AHGCollection *AHGNewColl(AHGEnumerable *coll)
{
    return [[AHGCollection alloc] initWithCollection:coll
                                             builder:[AHGBuilder builderFor:[coll class]]];
}

