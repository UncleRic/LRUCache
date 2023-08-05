//  RicCache.m
//  MyLRU
//
//  Created by Frederick C. Lee on 8/27/14.
//  Copyright (c) 2014 Amourine Technologies. All rights reserved.
// -----------------------------------------------------------------------------------------------------------------------

#import "RicCache.h"

static int kCacheMemoryLimit;

@interface RicCache ()
@property (nonatomic, strong) NSString *cacheDirectory;
@property (nonatomic, strong) NSString *appVersion;  // ...Keep cache distinct per app version.
@property (nonatomic, strong) NSMutableDictionary *memoryCache;
@end

@implementation RicCache

- (instancetype)initWithName:(NSString *)name {
    if ((self = [super init])) {
        [self cacheDirectoryForName:name];
    }
    return self;
}

// -----------------------------------------------------------------------------------------------------------------------

- (void)cacheDirectoryForName:(NSString *)name {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    self.cacheDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:name];
    if (![[NSFileManager defaultManager] fileExistsAtPath:_cacheDirectory]){
        [[NSFileManager defaultManager] createDirectoryAtPath:_cacheDirectory
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    // Invalidating the Cache.
    // Check if app's current version is dated; if true, then clear it via 'clearCache':
    
    double lastSavedCacheVersion = [[NSUserDefaults standardUserDefaults] doubleForKey:@"CACHE_VERSION"];
    double currentAppVersion = [[self appVersion] doubleValue];
    
    if (lastSavedCacheVersion < currentAppVersion) {
        // assigning current version to preference
        [self clearCache];
        
        [[NSUserDefaults standardUserDefaults] setDouble:currentAppVersion forKey:@"CACHE_VERSION"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    self.memoryCache = [[NSMutableDictionary alloc] init];
    self.recentlyAccessedKeys = [[NSMutableArray alloc] init];
    
    // you can set this based on the running device and expected cache size
    kCacheMemoryLimit = 10;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(saveMemoryCacheToDisk:)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(saveMemoryCacheToDisk:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(saveMemoryCacheToDisk:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    
}

// -----------------------------------------------------------------------------------------------------------------------

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
    
}

// -----------------------------------------------------------------------------------------------------------------------
#pragma mark -

- (void)saveMemoryCacheToDisk:(NSNotification  *)notification {
    @synchronized(self) {
        for (NSString *filename in [_memoryCache allKeys]){
            NSString *archivePath = [_cacheDirectory stringByAppendingPathComponent:filename];
            NSData *cacheData = [_memoryCache objectForKey:filename];
            [cacheData writeToFile:archivePath atomically:YES];
        }
        
        [_memoryCache removeAllObjects];
    }
}

// -----------------------------------------------------------------------------------------------------------------------

- (void)clearCache {
   @synchronized(self) {
        NSError *error;
        NSArray *cachedItems = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_cacheDirectory
                                                                                   error:&error];
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            for (NSString *path in cachedItems) {
                [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
                if (error) NSLog(@"Error: %@", error);
            }
            [_memoryCache removeAllObjects];
        }
    }
}

// -----------------------------------------------------------------------------------------------------------------------
// ...Getter: getting the current app version from its info.plist.

- (NSString *)appVersion {
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *version = [infoDict objectForKey:(NSString *)kCFBundleVersionKey];
	return version;
}


// -----------------------------------------------------------------------------------------------------------------------

- (NSData *)dataForFile:(NSString *)fileName {
        
    NSData *data;
    @synchronized(self) {
        data = [_memoryCache objectForKey:fileName];
        if (data)return data; // data is present in memory cache
        
        NSString *archivePath = [_cacheDirectory stringByAppendingPathComponent:fileName];
        data = [NSData dataWithContentsOfFile:archivePath];
        
        if (data) {
            [self cacheData:data toFile:fileName]; // put the recently accessed data to memory cache
        }
    }
    
    return data;
}

// -----------------------------------------------------------------------------------------------------------------------
#pragma mark - Caching Data

- (void)cacheData:(NSData *)data toFile:(NSString *)fileName {
    @synchronized(self) {
        
        [_memoryCache setObject:data forKey:fileName];
        [_recentlyAccessedKeys removeObject:fileName];
        [_recentlyAccessedKeys insertObject:fileName atIndex:0];
        
        // Write oldest data to file if cache is full:
        if ([_recentlyAccessedKeys count] > kCacheMemoryLimit) {
            NSString *leastRecentlyUsedDataFilename = [_recentlyAccessedKeys lastObject];
            NSData *leastRecentlyUsedCacheData = [_memoryCache objectForKey:leastRecentlyUsedDataFilename];
            NSString *archivePath = [_cacheDirectory stringByAppendingPathComponent:fileName];
            [leastRecentlyUsedCacheData writeToFile:archivePath atomically:YES];
            
            [_recentlyAccessedKeys removeLastObject];
            [_memoryCache removeObjectForKey:leastRecentlyUsedDataFilename];
        }
    }
}

// -----------------------------------------------------------------------------------------------------------------------
#pragma mark - Caching Assessors

- (void)cachedArrayItems:(NSArray *)arrayItems {
    NSError *error = nil;
    NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:arrayItems requiringSecureCoding:YES error:&error];
    if (error) {
        // Handle the error if necessary
        NSLog(@"Error archiving data: %@", error);
        return;
    }
    [self cacheData:archivedData toFile:@"RicItems.archive"];
}


// -----------------------------------------------------------------------------------------------------------------------

- (NSMutableArray *)getCachedArrayItems {
    // 1) Get data from either cache or file.
    // 2) Reposition data in cache.
    // 3) Unarchive (deSerialize) it.
    NSError *error = nil;
    NSMutableArray *cachedArrayItems = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSMutableArray class] fromData:[self dataForFile:@"RicItems.archive"] error:&error];
    
    if (error) {
        // Handle any errors during unarchiving, if necessary.
        NSLog(@"Error unarchiving data: %@", error);
        cachedArrayItems = [NSMutableArray array]; // Create an empty array to prevent crashes.
    }
    
    return cachedArrayItems;
}

@end

