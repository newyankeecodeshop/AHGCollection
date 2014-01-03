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

@end

@implementation AHGCollectionTests

- (void)setUp
{
    [super setUp];
   
    self.strings = @[@"hello", @"world", @"too"];
    self.stringSet = [NSSet setWithObjects:@"hello", @"to", @"you", @"again", nil];
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



@end
