//
//  DBFileSyncDataSource.h
//  ChineseDailyBread
//
//  Created by Eddie Hiu-Fung Lau on 11/4/14.
//
//

#import <Foundation/Foundation.h>

@class DBFileSynchronizer;
@protocol DBFileSyncDataSource <NSObject>

- (NSURL *) URLForFileToSyncInController:(DBFileSynchronizer *)synchronizer withUserId:(NSString *)userId;
- (NSString *) destinationFileNameInController:(DBFileSynchronizer *)synchronizer;
- (NSString *) destinationFolderInController:(DBFileSynchronizer *)synchronizer;

@optional
- (NSURL *) URLForMetadataFileInController:(DBFileSynchronizer *)synchronizer withUserId:(NSString *)userId;


@end
