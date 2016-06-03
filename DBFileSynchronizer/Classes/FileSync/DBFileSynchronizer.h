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

@interface DBFileSynchronizer : NSObject

- (void) reset;
- (void) sync;
- (void) setHasLocalChange:(BOOL)hasLocalChange;

@property (nonatomic,assign) id<DBFileSyncDataSource> dataSource;
@property (nonatomic,assign) id<DBFileSyncDelegate> delegate;

@property (nonatomic,readonly) NSDate *lastModifiedDate;

@end
