/*
 AHGEnumeration.m
 
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

#import "AHGEnumeration.h"
#import <objc/runtime.h>
#import <pthread.h>

// The size of the buffer holding temporary objects during an enumeration
#define BUFFER_LEN	16

// These macros give some identity to the slots in the "extra" array
#define SOURCE_COUNT(state) state->extra[0]
#define NEXT_INDEX(state)   state->extra[1]
#define SUB_INDEX(state)	state->extra[2]

/**
 Private state stored in a thread dictionary during the enumeration.
 */
@interface AHGFastEnumerationState : NSObject
{
@public
    NSFastEnumerationState m_enumState;
    id __strong            m_buffer[BUFFER_LEN];
}

+ (instancetype)stateForEnum:(AHGFastEnumeration *)fastEnum;

- (void)doneWithState;

@end

#pragma mark

@implementation AHGFastEnumeration
{
	id<NSFastEnumeration>  m_source;
}

- (instancetype)initWithSource:(id<NSFastEnumeration>)source
{
	if ((self = [super init])) {
		m_source = source;
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;    // This object is immutable, so this is safe.
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
								  objects:(id __unsafe_unretained [])buffer
									count:(NSUInteger)len
{
    AHGFastEnumerationState *myState = [AHGFastEnumerationState stateForEnum:self];
    NSFastEnumerationState *srcState = &myState->m_enumState;
    
	if (state->state == 0) {	// First time in
        // Clear the nested state for the first call to the source enumeration.
		memset(srcState, 0, sizeof(NSFastEnumerationState));

		state->extra[0] = [m_source countByEnumeratingWithState:srcState objects:buffer count:len];
		state->extra[1] = 0;
		state->mutationsPtr = srcState->mutationsPtr;
		state->state = 1;
	}
	
	if (SOURCE_COUNT(state) == 0) {
        // The wrapped enumeration has no more objects, so we're done.
        [myState doneWithState];
		return 0;
	}
	else if (SOURCE_COUNT(state) == NEXT_INDEX(state)) {
		// We transformed everything in itemsPtr, see if more data is available
		state->extra[0] = [m_source countByEnumeratingWithState:srcState objects:buffer count:len];
		state->extra[1] = 0;
	}

	state->itemsPtr = (id __unsafe_unretained *)(void *)myState->m_buffer;
	
	// Let the subclass do the specific processing on each item in the source state itemsPtr
	//
	return [self enumerateWithState:state sourceItems:srcState->itemsPtr objects:myState->m_buffer count:BUFFER_LEN];
}

- (NSUInteger)enumerateWithState:(NSFastEnumerationState *)state
                     sourceItems:(id __unsafe_unretained *)itemsPtr
                         objects:(id __strong *)buffer
                           count:(NSUInteger)len;
{
	return 0;
}

#pragma Key-Value Coding

/*
 * To match up with the behavior of NSArray and NSSet, we override valueForKey: and return an enumeration
 * over values for the given key.
 */
- (id)valueForKey:(NSString *)key
{
    return [[AHGTransformEnumeration alloc] initWithSource:self transform:^id(id anObject) {
        return [anObject valueForKey:key];
    }];
}

@end

@implementation AHGFastEnumerationState

+ (instancetype)stateForEnum:(AHGFastEnumeration *)fastEnum
{
    void *key = pthread_self();
    AHGFastEnumerationState *myState = objc_getAssociatedObject(fastEnum, key);
    
    if (myState == nil) {
        myState = [AHGFastEnumerationState new];
        objc_setAssociatedObject(fastEnum, key, myState, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return myState;
}

- (void)doneWithState
{
    // Clear out references to objects in the buffer, releasing them.
    for (int i = 0; i < BUFFER_LEN; ++i) {
        m_buffer[i] = nil;
    }
}

@end

#pragma mark

@implementation AHGTransformEnumeration
{
	AHGTransformBlock	  m_transform;
}

- (instancetype)initWithSource:(id<NSFastEnumeration>)source transform:(AHGTransformBlock)transform
{
	if ((self = [super initWithSource:source])) {
		m_transform = transform;
	}
	return self;
}

- (NSUInteger)enumerateWithState:(NSFastEnumerationState *)state
                     sourceItems:(id __unsafe_unretained *)itemsPtr
                         objects:(id __strong *)buffer
                           count:(NSUInteger)len;
{
	NSUInteger numLeft = SOURCE_COUNT(state) - NEXT_INDEX(state);
	NSUInteger itemCount = MIN(numLeft, len);
	NSUInteger srcIndex = NEXT_INDEX(state);

	for (NSUInteger i = 0; i < itemCount; ++i) {
		buffer[i] = m_transform(itemsPtr[srcIndex++]);
	}
	
	NEXT_INDEX(state) = srcIndex;
	
	return itemCount;
}

@end

#pragma mark -

@implementation AHGFilterEnumeration
{
	AHGPredicateBlock	  m_filter;
}

- (instancetype)initWithSource:(id<NSFastEnumeration>)source filter:(AHGPredicateBlock)filter
{
	if ((self = [super initWithSource:source])) {
		m_filter = filter;
	}
	return self;
}

- (NSUInteger)enumerateWithState:(NSFastEnumerationState *)state
                     sourceItems:(id __unsafe_unretained *)itemsPtr
                         objects:(id __strong *)buffer
                           count:(NSUInteger)len;
{
	NSUInteger count = 0;
	NSUInteger srcIndex = NEXT_INDEX(state);

	while ((SOURCE_COUNT(state) - srcIndex) > 0 && count < len) {
		// Iterate through the returned objects extracting ones that match the filter
		if (m_filter(itemsPtr[srcIndex++])) {
			buffer[count++] = itemsPtr[srcIndex - 1];
		}
		
		// Break out when we have none left, or we've hit the buffer limit
	}
	
	NEXT_INDEX(state) = srcIndex;
	
	return count;
}

@end

#pragma mark -

@implementation AHGFlatMapEnumeration
{
	AHGFlatMapBlock		  m_mapper;
	id<NSFastEnumeration> m_curValues;
}

- (instancetype)initWithSource:(id<NSFastEnumeration>)source transform:(AHGFlatMapBlock)transform
{
	if ((self = [super initWithSource:source])) {
		m_mapper = transform;
	}
	return self;
}

- (NSUInteger)enumerateWithState:(NSFastEnumerationState *)state
                     sourceItems:(id __unsafe_unretained *)itemsPtr
                         objects:(id __strong *)buffer
                           count:(NSUInteger)len;
{
	NSUInteger count = 0, pos = 0;
	NSUInteger srcIndex = NEXT_INDEX(state);
	
	while ((SOURCE_COUNT(state) - srcIndex) > 0 && count < len) {
		// Save the result of the mapping in case the buffer can't hold all the values
		if (m_curValues == nil) {
			m_curValues = m_mapper(itemsPtr[srcIndex]);
		}
		
		// Extract the set of values and add them to our buffer
		for (id value in m_curValues) {
			// Move us to the subindex
			if (pos++ < SUB_INDEX(state)) {
				continue;
			}
			
			buffer[count++] = value;
			SUB_INDEX(state) += 1;
			
			// We are out of buffer space, break out and wait for the next call
			if (count == len) {
				break;
			}
		}
		
		if (count < len) {
			m_curValues = nil;
			srcIndex += 1;
			SUB_INDEX(state) = pos = 0;
		}
	}
	
	NEXT_INDEX(state) = srcIndex;
	
	return count;
}

@end


