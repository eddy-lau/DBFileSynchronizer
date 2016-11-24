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

- (NSURL *) localURLForFileSynchronizer:(DBFileSynchronizer *)synchronizer withUserId:(NSString *)userId;
- (NSString *) destinationPathForFileSynchronizer:(DBFileSynchronizer *)synchronizer;

@optional
- (NSURL *) localMetadataURLForFileSynchronizer:(DBFileSynchronizer *)synchronizer withUserId:(NSString *)userId;


@end
