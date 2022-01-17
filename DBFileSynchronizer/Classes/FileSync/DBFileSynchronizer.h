//
//  DBfileSynchronizer.h
//  ChineseDailyBread
//
//  Created by Eddie Hiu-Fung Lau on 11/4/14.
//
//

#import <Foundation/Foundation.h>
#import "DBFileSyncDataSource.h"
#import "DBFileSyncDelegate.h"

typedef void(^DBSyncCompletionHandler)(NSError * _Nullable);

@interface DBFileSynchronizer : NSObject

- (void) sync;
- (void) sync:(DBSyncCompletionHandler _Nullable)completionHandler;
- (void) setHasLocalChange:(BOOL)hasLocalChange;

@property (nonatomic,assign) id<DBFileSyncDataSource> _Nullable dataSource;
@property (nonatomic,assign) id<DBFileSyncDelegate> _Nullable delegate;

@property (nonatomic,readonly) NSDate * _Nullable lastModifiedDate;

@end
