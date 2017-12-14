//  MyLRUTests.m
//  MyLRUTests
//
//  Created by Frederick C. Lee on 8/27/14.
//  Copyright (c) 2014 Amourine Technologies. All rights reserved.
// -----------------------------------------------------------------------------------------------------------------------

#import <XCTest/XCTest.h>
#import "RicCache.h"

@interface MyLRUTests : XCTestCase
@property (strong, nonatomic) NSArray *arrayItems;
@property (strong, nonatomic) RicCache *ricCache;
@end

@implementation MyLRUTests

- (void)setUp {
    [super setUp];
    self.ricCache = [[RicCache alloc] initWithName:@"myCache"];
    self.arrayItems = @[@"One",@"Two",@"Three",@"Four",@"Five",@"Six",@"Seven",@"Eight",@"Nine",@"Ten"];
    [_ricCache cachedArrayItems:self.arrayItems];
}

// -----------------------------------------------------------------------------------------------------------------------

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

// -----------------------------------------------------------------------------------------------------------------------

- (void)testFillCache {
    [_ricCache cachedArrayItems:self.arrayItems];
    (self.ricCache.recentlyAccessedKeys).firstObject;
     XCTAssertEqualObjects([self.ricCache.recentlyAccessedKeys firstObject], @"RicItems.archive", @"Cache doesn't have file name.");
}

// -----------------------------------------------------------------------------------------------------------------------

- (void)testRetreiveCache {
    NSArray *receivedArrayItems = [_ricCache getCachedArrayItems];
    XCTAssertEqualObjects(receivedArrayItems, _arrayItems, @"Error: Retrieved Data doesn't match original Data. ");
}

@end
