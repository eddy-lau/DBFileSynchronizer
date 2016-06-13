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
- (NSData *) dataRepresentation;
- (void) replaceByData:(NSData *)Data;
- (BOOL) mergeWithData:(NSData *)Data;
- (NSString *) fileName;

@end