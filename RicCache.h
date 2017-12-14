//  RicCache.h
//  MyLRU
//
//  Created by Frederick C. Lee on 8/27/14.
//  Copyright (c) 2014 Amourine Technologies. All rights reserved.
// -----------------------------------------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@interface RicCache : NSObject

@property (nonatomic, strong) NSMutableArray *recentlyAccessedKeys;
- (instancetype)init NS_UNAVAILABLE;  
- (instancetype)initWithName:(NSString *)name NS_DESIGNATED_INITIALIZER;
- (void)cachedArrayItems:(NSArray *)arrayItems;
@property (NS_NONATOMIC_IOSONLY, getter=getCachedArrayItems, readonly, copy) NSMutableArray *cachedArrayItems;
- (void)clearCache;
@end
