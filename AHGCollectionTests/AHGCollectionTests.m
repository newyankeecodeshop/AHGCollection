//
//  AHGCollectionTests.m
//  AHGCollectionTests
//
//  Created by Andrew (Wingspan) on 12/30/2013.
//  Copyright (c) 2013 Andrew Goodale. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AHGCollection.h"

@interface AHGCollectionTests : XCTestCase

@end

@implementation AHGCollectionTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testMap
{
    NSArray *strings = @[@"hello", @"world", @"too"];
    NSArray *result = [[AHGNewColl(strings) map:^id(NSString *str) {
        return [str uppercaseString];
    }] map:^id(NSString *str) {
        return [str stringByAppendingString:@"!"];
    }].collection;
    
    NSArray *test = @[@"HELLO!", @"WORLD!", @"TOO!"];
    XCTAssertEqualObjects(result, test, @"Map function didn't work");
    
    // And test that [map:] works with Sets
    
    NSSet *stringSet = [NSSet setWithArray:strings];
    
    NSSet *result2 = [[AHGNewColl(stringSet) map:^id(NSString *str) {
        return [str uppercaseString];
    }] map:^id(NSString *str) {
        return [str stringByAppendingString:@"!"];
    }].collection;
    
    NSSet *test2 = [NSSet setWithArray:test];
    XCTAssertEqualObjects(result2, test2, @"Map function didn't work");
    
    // And test that [map:] works with Dictionaries
    
}

- (void)testFlatMap
{
    
}

@end
