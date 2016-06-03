//
//  DBFileSyncDelegate.h
//  ChineseDailyBread
//
//  Created by Eddie Hiu-Fung Lau on 11/4/14.
//
//

#import <Foundation/Foundation.h>

@class DBFileSynchronizer;
@protocol DBFileSyncDelegate <NSObject>

@optional
- (void) fileSynchronizer:(DBFileSynchronizer *)synchronizer mergeRemoteFileContentAtPath:(NSString *)path;
- (void) fileSynchronizer:(DBFileSynchronizer *)synchronizer didDownloadFileAtPath:(NSString *)path;
- (void) fileSynchronizer:(DBFileSynchronizer *)synchronizer didUploadFileAtPath:(NSString *)path;

- (void) fileSynchronizer:(DBFileSynchronizer *)synchronizer didFailWithError:(NSError *)error;

@end
