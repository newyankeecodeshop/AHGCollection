//
//  AHGBuilder.h
//  AHGCollection
//
//  Created by Andrew (Wingspan) on 1/2/2014.
//  Copyright (c) 2014 Andrew Goodale. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * A builder creates an abstraction for creating new collections.
 */
@interface AHGBuilder : NSObject

+ (AHGBuilder *)builderFor:(Class)collectionClass;

+ (void)registerBuilder:(AHGBuilder *)builder forClass:(Class)collectionClass;

- (id)newMutableColl:(id)sourceColl;

- (void)addObject:(id)anObject toMutableColl:(id)mutableColl;

@end

#pragma mark

@interface AHGBuilderForArray : AHGBuilder

@end

#pragma mark

@interface AHGBuilderForSet : AHGBuilder

@end
