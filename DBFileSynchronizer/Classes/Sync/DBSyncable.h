//
//  HTMLBackupable.h
//  ChineseDailyBread
//
//  Created by Eddie Hiu-Fung Lau on 13/6/2016.
//
//

#import <Foundation/Foundation.h>

@protocol DBSyncable <NSObject>

- (BOOL) hasData;
- (NSData * _Nullable) dataRepresentation;
- (void) replaceByData:(NSData * _Nonnull)data;
- (BOOL) mergeWithData:(NSData * _Nonnull)data;
- (NSString * _Nonnull) fileName;

@end
