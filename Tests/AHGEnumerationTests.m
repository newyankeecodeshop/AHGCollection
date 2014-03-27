//
//  AHGEnumerationTests.m
//  AHGCollection
//
//  Created by Andrew on 2/20/14.
//  Copyright (c) 2014 Andrew Goodale. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AHGEnumeration.h"

static id (^ txFunc)(id) = ^(id anObject) {
	return [NSNumber numberWithInt:[anObject intValue] * 1000];
};
static id (^ txStrFunc)(id) = ^(NSString *anObject) {
	return [anObject uppercaseString];
};

@interface AHGEnumerationTests : XCTestCase

@property (nonatomic, copy) NSDictionary *testData;
@property (nonatomic, copy) NSArray *smallArray;

@end

@implementation AHGEnumerationTests

- (void)setUp
{
    [super setUp];
    
	NSBundle *testBundle = [NSBundle bundleForClass:self.class];
	NSURL *testDataURL = [testBundle URLForResource:@"Test Data" withExtension:@"plist"];
	self.testData = [NSDictionary dictionaryWithContentsOfURL:testDataURL];
	
	self.smallArray = @[@1, @2, @3, @4, @5];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testTransformer
{
	AHGTransformEnumeration *transformer = [[AHGTransformEnumeration alloc] initWithSource:self.smallArray
																			   transform:txFunc];
	NSUInteger size = 0;
	
	for (NSNumber *num in transformer) {
		XCTAssertTrue([num intValue] >= 1000, @"Transform didn't happen");
		++size;
	}
	
	XCTAssertEqual(size, self.smallArray.count, @"Wrong number of values in enum");
	
	// Now with a larger array
	NSArray *largeArray = [self.testData objectForKey:@"testTransformer"];
	transformer = [[AHGTransformEnumeration alloc] initWithSource:largeArray transform:txStrFunc];
	
	size = [self validateTransformer:transformer];
	XCTAssertEqual(size, largeArray.count, @"Wrong number of values in enum");
	
	// Can you iterate a second time?
	size = [self validateTransformer:transformer];
	XCTAssertEqual(size, largeArray.count, @"2nd for/in failed");
}

- (NSUInteger)validateTransformer:(AHGTransformEnumeration *)transformer
{
	NSUInteger size = 0;

	for (NSString *str in transformer) {
		NSRange r = [str rangeOfCharacterFromSet:[NSCharacterSet lowercaseLetterCharacterSet]];
		XCTAssertTrue(r.length == 0, @"Tranform didn't happen");
		++size;
	}
	
	return size;
}

- (void)testTransformerWithSet
{
	NSSet *largeSet = [NSSet setWithArray:[self.testData objectForKey:@"testTransformer"]];
	AHGTransformEnumeration *transformer = [[AHGTransformEnumeration alloc] initWithSource:largeSet
																			   transform:txStrFunc];
	
	NSUInteger size = [self validateTransformer:transformer];
	XCTAssertEqual(size, largeSet.count, @"Wrong number of values in enum");
	
	// Can you iterate a second time?
	size = [self validateTransformer:transformer];
	XCTAssertEqual(size, largeSet.count, @"2nd for/in failed");
	
}

- (void)testFlatMapper
{
	AHGFlatMapBlock mapBlock = ^id<NSFastEnumeration>(NSDictionary *item) {
		// Each dictionary contains "count" and "value"
		NSMutableArray *a = [NSMutableArray array];
		int count = [item[@"count"] intValue];

		for (int i = 0; i < count; ++i) {
			[a addObject:item[@"value"]];
		}
		return [a copy];
	};
	
	NSDictionary *myData = self.testData;
	NSArray *rootArray = [myData objectForKey:@"testFlatMapper"];
	AHGFlatMapEnumeration *mapper = [[AHGFlatMapEnumeration alloc] initWithSource:rootArray
																	  transform:mapBlock];
	NSInteger counter = 0;
	
	for (NSString *value in mapper) {
//		NSLog(@"Value %@", value);
		
		if ([value isEqualToString:@"Seven"]) {
			XCTAssertTrue(counter < 7, @"Seven strings");
		}
		else if ([value isEqualToString:@"Ninety-Nine"]) {
			XCTAssertTrue(counter >= 7 && counter < 106 , @"Ninety-Nine strings");
		}
		else if ([value isEqualToString:@"Nine"]) {
			XCTAssertTrue(counter >= 106 && counter < 115, @"Nine strings");
		}
		else if ([value isEqualToString:@"Two Hundred"]) {
			XCTAssertTrue(counter >= 115 && counter < 315, @"Two Hundred strings");
		}
		
		++counter;
	}
}

- (void)testRanges
{
    NSArray *stuff = [self.testData objectForKey:@"testTransformer"];
    NSRange range = NSMakeRange(0, 3);
    
    AHGRangeEnumeration *rangeEnum = [[AHGRangeEnumeration alloc] initWithSource:stuff range:range];
    NSMutableArray *results = [NSMutableArray array];
    
    for (id obj in rangeEnum) {
        [results addObject:obj];
    }
    
    NSArray *test = @[@"a", @"b", @"c"];
    XCTAssertEqualObjects(test, results, @"Range [0, 4) failed");
    
    // Now try it with a Set, getting the last three items
    NSSet *stuffSet = [NSSet setWithArray:stuff];
    
    rangeEnum = [[AHGRangeEnumeration alloc] initWithSource:stuffSet range:NSMakeRange(24, 3)];
    results = [NSMutableArray array];
    
    for (id obj in rangeEnum) {
        [results addObject:obj];
    }
    
    XCTAssertEqual(3, [results count], @"Didn't get the last three items");
}

@end
