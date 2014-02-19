//
//  AHGCollectionTests.m
//  AHGCollectionTests
//
//  Created by Andrew on 12/30/2013.
//  Copyright (c) 2013 Andrew Goodale. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AHGCollection.h"

@interface AHGCollectionTests : XCTestCase

@property (nonatomic, copy) NSArray *strings;
@property (nonatomic, copy) NSSet   *stringSet;

@property (nonatomic, copy) NSArray *dictValues;

@end

@implementation AHGCollectionTests

- (void)setUp
{
    [super setUp];
   
    self.strings = @[@"hello", @"world", @"too"];
    self.stringSet = [NSSet setWithObjects:@"hello", @"to", @"you", @"again", nil];
    
    self.dictValues = @[@{@"a": @1, @"name": @"Andrew1"},
                        @{@"b": @2, @"name": @"Andrew1"},
                        @{@"c": @3, @"name": @"Andrew2"},
                        @{@"d": @4, @"name": @"Andrew2"},
                        @{@"a": @5, @"name": @"Andrew3"},
                        @{@"b": @6, @"name": @"Andrew3"},
                        @{@"c": @7, @"name": @"Andrew4"},
                        @{@"d": @8, @"name": @"Andrew4"}];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testForEach
{
    AHGCollection *coll = AHGNewColl(self.strings);

    for (NSString *str in coll) {
        XCTAssertTrue([self.strings containsObject:str], @"Enumeration not working");
    }
    
    XCTAssertFalse(coll.isEmpty, @"isEmpty doesn't work");
}

- (void)testMap
{
    NSArray *result = [[[AHGNewColl(self.strings) map:^id(NSString *str) {
        return [str uppercaseString];
    }] map:^id(NSString *str) {
        return [str stringByAppendingString:@"!"];
    }] allObjects];
    
    NSArray *test = @[@"HELLO!", @"WORLD!", @"TOO!"];
    XCTAssertEqualObjects(result, test, @"Map function didn't work");
    
    // And test that [map:] works with Sets
    
    NSSet *stringSet = [NSSet setWithArray:self.strings];
    
    NSArray *result2 = [[[AHGNewColl(stringSet) map:^id(NSString *str) {
        return [str uppercaseString];
    }] map:^id(NSString *str) {
        return [str stringByAppendingString:@"!"];
    }] allObjects];
    
	XCTAssertEqual(3UL, [result2 count], @"Wrong length for set mapping");
	
	for (id testObj in test) {
		XCTAssertTrue([result2 containsObject:testObj], @"Map function didn't work");
    }
	
    // And test that [map:] works with Dictionaries
    
}

- (void)testFlatMap
{
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSError *__block myErr = nil;
    
    NSArray *paths = @[@"/Library"];
    AHGCollection *files = [AHGNewColl(paths) flatMap:^NSObject<NSCopying,NSFastEnumeration> *(id obj) {
        return [fileMgr contentsOfDirectoryAtPath:obj error:&myErr];
    }];
    
    XCTAssertFalse(files.isEmpty, @"Should have found some files");
    
    for (NSString *file in files) {
        NSString *path = [@"/Library" stringByAppendingPathComponent:file];
        XCTAssertTrue([fileMgr fileExistsAtPath:path], @"Flat map didn't work!");
    }

    files = [[AHGNewColl(paths) flatMap:^NSObject<NSCopying,NSFastEnumeration> *(NSString *path) {
//        NSLog(@"%@", path);
        return [fileMgr contentsOfDirectoryAtPath:path error:&myErr];
    }] flatMap:^NSObject<NSCopying,NSFastEnumeration> *(NSString *path) {
//        NSLog(@"\t%@", path);
        return [fileMgr contentsOfDirectoryAtPath:[@"/Library" stringByAppendingPathComponent:path] error:&myErr];
    }];
    
    XCTAssertFalse(files.isEmpty, @"Should have found some files");
}

- (void)testFilter
{
    BOOL (^myFilter)(NSString *) = ^(NSString *str) {
        return (BOOL) (str.length > 3);
    };
    
    AHGCollection *strings = AHGNewColl(@[@"hello", @"to", @"you", @"again"]);
    NSArray *result = [[strings filter:myFilter] allObjects];
    
    NSArray *test = @[@"hello", @"again"];
    XCTAssertEqualObjects(result, test, @"Filter function didn't work");
    
    NSArray *resultNot = [[strings filterNot:myFilter] allObjects];
    
    NSArray *testNot = @[@"to", @"you"];
    XCTAssertEqualObjects(resultNot, testNot, @"FilterNot function didn't work");
}

- (void)testFolding
{
    AHGCollection *strings = AHGNewColl(self.strings);
    
    NSString *result = [strings foldLeft:@"" operator:^id(NSString *resultObject, NSString *anObject) {
        return [resultObject stringByAppendingString:anObject];
    }];
    XCTAssertEqualObjects(@"helloworldtoo", result, @"Fold produced the wrong result");
    
    strings = AHGNewColl(@[]);
    result = [strings foldLeft:@"empty" operator:^id(id resultObject, id anObject) {
        return [resultObject stringByAppendingString:anObject];
    }];
    XCTAssertEqualObjects(@"empty", result, @"Fold with empty array failed");
}

- (void)testGroupBy
{
    AHGCollection *strings = AHGNewColl(self.stringSet);
    
    NSDictionary *groups = [[strings flatMap:^NSObject<NSCopying,NSFastEnumeration> *(NSString *obj) {
        return [NSArray arrayWithObjects:obj, [obj uppercaseString], [obj lowercaseString], nil];
    }] groupBy:^id(NSString *obj) {
        return [NSNumber numberWithInteger:[obj length]];
    }];
    
    for (NSNumber *key in groups) {
//        NSLog(@"Group: %@", [groups objectForKey:key]);

        NSArray *group = [groups objectForKey:key];
        XCTAssertTrue([AHGNewColl(group) every:^BOOL(id obj) {
            return [obj length] == [key integerValue];
        }], @"Grouping is not working");
    }
}

- (void)testFind
{
    AHGCollection *strings = AHGNewColl(self.stringSet);
    
    NSString *result = [strings find:^(id obj) {
        return [obj hasPrefix:@"yo"];
    }];
    XCTAssertEqualObjects(result, @"you", @"Find didn't work");
    
    BOOL doesExist = [strings exists:^(id obj) {
        return [obj isEqualToString:@"not you"];
    }];
    XCTAssertFalse(doesExist, @"Exists didn't work");

    BOOL noneEmpty = [strings every:^(id obj) {
        return (BOOL) ![obj isEqualToString:@""];
    }];
    XCTAssertTrue(noneEmpty, @"Every didn't work");
}

- (void)testMapWithKey
{
    NSArray *result = [[AHGNewColl(self.dictValues) mapWithKey:@"name"] allObjects];
    
    XCTAssertEqual(self.dictValues.count, result.count, @"Count is wrong");
    XCTAssertEqualObjects(@"Andrew1", result.firstObject, @"First value is wrong");
    XCTAssertEqualObjects(@"Andrew4", result.lastObject, @"Last value is wrong");
}

- (void)testFilterWithKey
{
    NSArray *result = [[AHGNewColl(self.dictValues) filterWithKey:@"a"] allObjects];
    XCTAssertEqual(2UL, result.count, @"Count is wrong");
    XCTAssertEqualObjects(@"Andrew1", result.firstObject[@"name"], @"First value is wrong");
    XCTAssertEqualObjects(@"Andrew3", result.lastObject[@"name"], @"Last value is wrong");
}

- (void)testGroupByKey
{
    NSDictionary *result = [AHGNewColl(self.dictValues) groupByKey:@"name"];
    XCTAssertEqual(4UL, result.count, @"Count is wrong");
    
    for (id key in result) {
        NSArray *group = result[key];
        XCTAssertEqual(2UL, group.count, @"Group count is wrong");
    }
}

@end
