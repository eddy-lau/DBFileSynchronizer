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

- (instancetype) initWithSyncable:(id<DBSyncable>)syncable;
- (void) reset;
- (void) sync;
- (void) setHasLocalChange:(BOOL)hasLocalChange;

@property (nonatomic,retain) id<DBSyncable> syncable;
@property (nonatomic,readonly) NSDate *lastModifiedDate;

@end

extern NSString *DBSynchronizerDidDownloadSyncableNotification;
extern NSString *DBSynchronizerDidUploadSyncableNotification;
extern NSString *DBSynchronizerDidFailNotification;
