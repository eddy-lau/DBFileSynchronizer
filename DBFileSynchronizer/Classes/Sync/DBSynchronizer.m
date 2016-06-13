//
//  DBSynchronizer.m
//  ChineseDailyBread
//
//  Created by Eddie Hiu-Fung Lau on 10/4/14.
//
//

#import "DBSynchronizer.h"
#import "DBFileSynchronizer.h"

NSString *DBSynchronizerDidDownloadSyncableNotification = @"DBSynchronizerDidDownloadSyncableNotification";
NSString *DBSynchronizerDidUploadSyncableNotification = @"DBSynchronizerDidUploadSyncableNotification";
NSString *DBSynchronizerDidFailNotification = @"DBSynchronizerDidFailNotification";

@interface DBSynchronizer ()
<
    DBFileSyncDataSource,
    DBFileSyncDelegate
>

@property (nonatomic,retain) DBFileSynchronizer *fileSynchronizer;

@end

@implementation DBSynchronizer

- (id) init {
    
    self = [super init];
    if (self) {
        self.fileSynchronizer = [[[DBFileSynchronizer alloc] init] autorelease];
        self.fileSynchronizer.dataSource = self;
        self.fileSynchronizer.delegate = self;
    }
    return self;
    
}

- (void) dealloc {
    self.fileSynchronizer = nil;
    self.syncable = nil;
    [super dealloc];
}

#pragma mark private methods

- (NSString *) baseFileName {
    return [[self.syncable fileName] stringByDeletingPathExtension];
}

#pragma mark DBFileSyncDataSource

- (NSURL *) URLForFileToSyncInController:(DBFileSynchronizer *)controller withUserId:(NSString *)userId {
    
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

- (NSURL *) URLForMetadataFileInController:(DBFileSynchronizer *)controller withUserId:(NSString *)userId {
    
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

- (NSString *) destinationFileNameInController:(DBFileSynchronizer *)controller {
    return [self.syncable fileName];
}

- (NSString *) destinationFolderInController:(DBFileSynchronizer *)controller {
    return @"/";
}

#pragma mark DBFileDelegate

- (void) fileSynchronizer:(DBFileSynchronizer *)controller mergeRemoteFileContentAtPath:(NSString *)path {
    
    NSData *data = [NSData dataWithContentsOfFile:path];
    self.hasLocalChange = [self.syncable mergeWithData:data];
    
}

- (void) fileSynchronizer:(DBFileSynchronizer *)controller didDownloadFileAtPath:(NSString *)path {
    
    NSData *data = [NSData dataWithContentsOfFile:path];
    [self.syncable replaceByData:data];
    
    NSDictionary *userInfo = @{@"syncable":self.syncable};
    [[NSNotificationCenter defaultCenter] postNotificationName:DBSynchronizerDidDownloadSyncableNotification object:self userInfo:userInfo];
}

- (void) fileSynchronizer:(DBFileSynchronizer *)controller didUploadFileAtPath:(NSString *)path {
    
    NSDictionary *userInfo = @{@"syncable":self.syncable};
    [[NSNotificationCenter defaultCenter] postNotificationName:DBSynchronizerDidUploadSyncableNotification object:self userInfo:userInfo];
}

- (void) fileSynchronizer:(DBFileSynchronizer *)controller didFailWithError:(NSError *)error {
    
    NSDictionary *userInfo = @{@"syncable":self.syncable, @"error":error};
    [[NSNotificationCenter defaultCenter] postNotificationName:DBSynchronizerDidFailNotification object:self userInfo:userInfo];
    
}

#pragma mark public methods

- (void) reset {
    [self.fileSynchronizer reset];
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
