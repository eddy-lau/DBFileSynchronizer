//
//  NotesBackupManager.h
//  ChineseDailyBread
//
//  Created by Eddie Hiu-Fung Lau on 10/4/14.
//
//

#import <Foundation/Foundation.h>
#import "DBSyncable.h"

@interface DBSynchronizer : NSObject

- (instancetype _Nonnull) initWithSyncable:(id<DBSyncable> _Nonnull)syncable;
- (void) sync;
- (void) setHasLocalChange:(BOOL)hasLocalChange;

@property (nonatomic,retain) id<DBSyncable> _Nullable syncable;
@property (nonatomic,readonly) NSDate * _Nullable lastModifiedDate;

@end
