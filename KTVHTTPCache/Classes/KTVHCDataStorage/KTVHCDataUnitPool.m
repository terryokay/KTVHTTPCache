//
//  KTVHCDataUnitPool.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataUnitPool.h"
#import "KTVHCDataUnitQueue.h"
#import "KTVHCPathTools.h"

@interface KTVHCDataUnitPool ()

@property (nonatomic, strong) NSLock * lock;
@property (nonatomic, strong) KTVHCDataUnitQueue * unitQueue;

@end

@implementation KTVHCDataUnitPool

+ (instancetype)unitPool
{
    static KTVHCDataUnitPool * obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[self alloc] init];
    });
    return obj;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.lock = [[NSLock alloc] init];
        self.unitQueue = [KTVHCDataUnitQueue unitQueueWithArchiverPath:[KTVHCPathTools pathForArchiver]];
    }
    return self;
}

- (KTVHCDataUnit *)unitWithURLString:(NSString *)URLString
{
    if (URLString.length <= 0) {
        return nil;
    }
    
    [self.lock lock];
    NSString * uniqueIdentifier = [KTVHCDataUnit uniqueIdentifierWithURLString:URLString];
    KTVHCDataUnit * unit = [self.unitQueue unitWithUniqueIdentifier:uniqueIdentifier];
    if (!unit)
    {
        unit = [KTVHCDataUnit unitWithURLString:URLString];
        [self.unitQueue putUnit:unit];
        [self.unitQueue archive];
    }
    [self.lock unlock];
    return unit;
}

- (void)deleteUnitWithURLString:(NSString *)URLString
{
    if (URLString.length <= 0) {
        return;
    }
    
    [self.lock lock];
    NSString * uniqueIdentifier = [KTVHCDataUnit uniqueIdentifierWithURLString:URLString];
    KTVHCDataUnit * obj = [self.unitQueue unitWithUniqueIdentifier:uniqueIdentifier];
    if (obj && !obj.working)
    {
        [KTVHCPathTools deleteFolderAtPath:obj.fileFolderPath];
        [self.unitQueue popUnit:obj];
    }
    [self.lock unlock];
}

- (void)deleteAllUnits
{
    [self.lock lock];
    BOOL needArchive = NO;
    NSArray <KTVHCDataUnit *> * units = [self.unitQueue allUnits];
    for (KTVHCDataUnit * obj in units)
    {
        if (!obj.working) {
            [KTVHCPathTools deleteFolderAtPath:obj.fileFolderPath];
            [self.unitQueue popUnit:obj];
            needArchive = YES;
        }
    }
    if (needArchive) {
        [self.unitQueue archive];
    }
    [self.lock unlock];
}


#pragma mark - Unit Control

- (void)unit:(NSString *)unitURLString insertUnitItem:(KTVHCDataUnitItem *)unitItem
{
    if (unitURLString.length <= 0) {
        return;
    }
    
    [self.lock lock];
    NSString * uniqueIdentifier = [KTVHCDataUnit uniqueIdentifierWithURLString:unitURLString];
    KTVHCDataUnit * unit = [self.unitQueue unitWithUniqueIdentifier:uniqueIdentifier];
    [unit insertUnitItem:unitItem];
    [self.unitQueue archive];
    [self.lock unlock];
}

- (void)unit:(NSString *)unitURLString updateRequestHeaderFields:(NSDictionary *)requestHeaderFields
{
    if (unitURLString.length <= 0) {
        return;
    }
    
    [self.lock lock];
    NSString * uniqueIdentifier = [KTVHCDataUnit uniqueIdentifierWithURLString:unitURLString];
    KTVHCDataUnit * unit = [self.unitQueue unitWithUniqueIdentifier:uniqueIdentifier];
    [unit updateRequestHeaderFields:requestHeaderFields];
    [self.lock unlock];
}

- (void)unit:(NSString *)unitURLString updateResponseHeaderFields:(NSDictionary *)responseHeaderFields
{
    if (unitURLString.length <= 0) {
        return;
    }
    
    [self.lock lock];
    NSString * uniqueIdentifier = [KTVHCDataUnit uniqueIdentifierWithURLString:unitURLString];
    KTVHCDataUnit * unit = [self.unitQueue unitWithUniqueIdentifier:uniqueIdentifier];
    [unit updateResponseHeaderFields:responseHeaderFields];
    [self.unitQueue archive];
    [self.lock unlock];
}


@end
