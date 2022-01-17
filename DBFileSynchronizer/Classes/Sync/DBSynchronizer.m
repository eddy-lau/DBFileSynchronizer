//
//  DBSynchronizer.m
//  ChineseDailyBread
//
//  Created by Eddie Hiu-Fung Lau on 10/4/14.
//
//

#import "DBSynchronizer.h"
#import "DBFileSynchronizer.h"

NSNotificationName DBSyncableDidDownloadNotification = @"DBSyncableDidDownloadNotification";
NSNotificationName DBSyncableDidUploadNotification = @"DBSyncableDidUploadNotification";
NSNotificationName DBSyncableDidFailNotification = @"DBSyncableDidFailNotification";


@interface DBSynchronizer ()
<
    DBFileSyncDataSource,
    DBFileSyncDelegate
>

@property (nonatomic,retain) DBFileSynchronizer *fileSynchronizer;

@end

@implementation DBSynchronizer

- (instancetype) initWithSyncable:(id<DBSyncable>)syncable {
    self = [super init];
    if (self) {
        self.syncable = syncable;
        self.fileSynchronizer = [[DBFileSynchronizer alloc] init];
        self.fileSynchronizer.dataSource = self;
        self.fileSynchronizer.delegate = self;
    }
    return self;
}

- (instancetype) init {
    
    self = [super init];
    if (self) {
        self.fileSynchronizer = [[DBFileSynchronizer alloc] init];
        self.fileSynchronizer.dataSource = self;
        self.fileSynchronizer.delegate = self;
    }
    return self;
    
}

- (void) dealloc {
    self.fileSynchronizer = nil;
    self.syncable = nil;
}

#pragma mark private methods

- (NSString *) baseFileName {
    return [[self.syncable fileName] stringByDeletingPathExtension];
}

#pragma mark DBFileSyncDataSource

- (NSURL *) localURLForFileSynchronizer:(DBFileSynchronizer *)synchronizer withUserId:(NSString *)userId {
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    NSURL *docURL = [fm URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:NULL create:NO error:&error];
    if (docURL == nil) {
        NSLog (@"Error: %@", error);
        return nil;
    }
    
    
    NSString *fileName = self.syncable.fileName;
    
    if (userId) {
        fileName = [[NSString stringWithFormat:@"%@-%@", [self baseFileName], userId] stringByAppendingPathExtension:[fileName pathExtension]];
    }
    
    NSURL *fileURL = [docURL URLByAppendingPathComponent:fileName];
    
    if ([self.syncable hasData]) {
        
        NSData *data = [self.syncable dataRepresentation];
        if (![data writeToURL:fileURL options:NSDataWritingAtomic error:&error]) {
            NSLog (@"Error: %@", error);
        } else {
            NSLog (@"Exported syncable to: %@", fileURL.path);
        }
        
    } else {
        
        if ([fm fileExistsAtPath:fileURL.path]) {
            if (![fm removeItemAtURL:fileURL error:&error]) {
                NSLog (@"Error: %@", error);
            }
        }
        
    }
    
    return fileURL;
    
}

- (NSURL *) localMetadataURLForFileSynchronizer:(DBFileSynchronizer *)synchronizer withUserId:(NSString *)userId {
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    NSURL *docURL = [fm URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:NULL create:NO error:&error];
    if (docURL == nil) {
        NSLog (@"Error: %@", error);
        return nil;
    }
    
    if (userId) {
        NSString *fileName = [NSString stringWithFormat:@"%@-%@.metadata", [self baseFileName], userId];
        return [docURL URLByAppendingPathComponent:fileName];
    } else {
        return [docURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.metadata", [self baseFileName]]];
    }
    
}

- (NSString *) destinationPathForFileSynchronizer:(DBFileSynchronizer *)synchronizer {
    return [@"/" stringByAppendingPathComponent:[self.syncable fileName]];
}

#pragma mark DBFileDelegate

- (void) fileSynchronizer:(DBFileSynchronizer *)controller mergeRemoteFileContentAtPath:(NSString *)path {
    
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:path options:0 error:&error];
    if (error || data == nil) {
        NSLog(@"Error reading %@: %@", path, error);
        return;
    }

    self.hasLocalChange = [self.syncable mergeWithData:data];
}

- (void) fileSynchronizer:(DBFileSynchronizer *)controller didDownloadFileAtPath:(NSString *)path {
    
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:path options:0 error:&error];
    if (error || data == nil) {
        NSLog(@"Error reading %@: %@", path, error);
        return;
    }
    
    [self.syncable replaceByData:data];
    
    NSDictionary *userInfo = @{@"syncable":self.syncable};
    [[NSNotificationCenter defaultCenter] postNotificationName:DBSyncableDidDownloadNotification object:self userInfo:userInfo];
}

- (void) fileSynchronizer:(DBFileSynchronizer *)controller didUploadFileAtPath:(NSString *)path {
    
    NSDictionary *userInfo = @{@"syncable":self.syncable};
    [[NSNotificationCenter defaultCenter] postNotificationName:DBSyncableDidUploadNotification object:self userInfo:userInfo];
}

- (void) fileSynchronizer:(DBFileSynchronizer *)controller didFailWithError:(NSError *)error {
    
    NSDictionary *userInfo = @{@"syncable":self.syncable, @"error":error};
    [[NSNotificationCenter defaultCenter] postNotificationName:DBSyncableDidFailNotification object:self userInfo:userInfo];
    
}

#pragma mark public methods

- (void) reset {
}

- (void) sync {
    [self.fileSynchronizer sync];
}

- (void) setHasLocalChange:(BOOL)hasLocalChange {
    [self.fileSynchronizer setHasLocalChange:hasLocalChange];
}

- (NSDate *) lastModifiedDate {
    return self.fileSynchronizer.lastModifiedDate;
}


@end
