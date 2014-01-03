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
    NSArray *result = [[AHGNewColl(self.strings) map:^id(NSString *str) {
        return [str uppercaseString];
    }] map:^id(NSString *str) {
        return [str stringByAppendingString:@"!"];
    }].collection;
    
    NSArray *test = @[@"HELLO!", @"WORLD!", @"TOO!"];
    XCTAssertEqualObjects(result, test, @"Map function didn't work");
    
    // And test that [map:] works with Sets
    
    NSSet *stringSet = [NSSet setWithArray:self.strings];
    
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
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSError *__block myErr = nil;
    
    NSArray *paths = @[@"/Library"];
    NSArray *files = [AHGNewColl(paths) flatMap:^NSObject<NSCopying,NSFastEnumeration> *(id obj) {
        return [fileMgr contentsOfDirectoryAtPath:obj error:&myErr];
    }].collection;
    
    XCTAssertTrue(files.count > 0, @"Should have found some files");
    
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
    }].collection;
    
    XCTAssertTrue(files.count > 0, @"Should have found some files");
}

- (void)testFilter
{
    BOOL (^myFilter)(NSString *) = ^(NSString *str) {
        return (BOOL) (str.length > 3);
    };
    
    AHGCollection *strings = AHGNewColl(@[@"hello", @"to", @"you", @"again"]);
    NSArray *result = [strings filter:myFilter].collection;
    
    NSArray *test = @[@"hello", @"again"];
    XCTAssertEqualObjects(result, test, @"Filter function didn't work");
    
    NSArray *resultNot = [strings filterNot:myFilter].collection;
    
    NSArray *testNot = @[@"to", @"you"];
    XCTAssertEqualObjects(resultNot, testNot, @"FilterNot function didn't work");
}

- (void)testFolding
{
    AHGCollection *strings = AHGNewColl(self.stringSet);
    
    NSString *result = [strings foldLeft:@"" operator:^id(NSString *resultObject, NSString *anObject) {
        return [resultObject stringByAppendingString:anObject];
    }];
    XCTAssertEqualObjects(@"hellotoyouagain", result, @"Fold produced the wrong result");
    
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
    NSArray *result = [AHGNewColl(self.dictValues) mapWithKey:@"name"].collection;
    
    XCTAssertEqual(self.dictValues.count, result.count, @"Count is wrong");
    XCTAssertEqualObjects(@"Andrew1", result.firstObject, @"First value is wrong");
    XCTAssertEqualObjects(@"Andrew4", result.lastObject, @"Last value is wrong");
}

- (void)testFilterWithKey
{
    NSArray *result = [AHGNewColl(self.dictValues) filterWithKey:@"a"].collection;
    XCTAssertEqual(2U, result.count, @"Count is wrong");
    XCTAssertEqualObjects(@"Andrew1", result.firstObject[@"name"], @"First value is wrong");
    XCTAssertEqualObjects(@"Andrew3", result.lastObject[@"name"], @"Last value is wrong");
}

- (void)testGroupByKey
{
    NSDictionary *result = [AHGNewColl(self.dictValues) groupByKey:@"name"];
    XCTAssertEqual(4U, result.count, @"Count is wrong");
    
    for (id key in result) {
        NSArray *group = result[key];
        XCTAssertEqual(2U, group.count, @"Group count is wrong");
    }
}

@end
