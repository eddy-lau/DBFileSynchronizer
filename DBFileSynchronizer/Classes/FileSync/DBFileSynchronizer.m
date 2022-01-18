//
//  DBfileSynchronizer.m
//  ChineseDailyBread
//
//  Created by Eddie Hiu-Fung Lau on 11/4/14.
//
//

#import "DBFileSynchronizer.h"
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>
#import "DBLocalMetadata.h"
#import "DBError.h"

#define COMPLETE(completion) \
if((completion) != nil) { (completion)(nil); }

#define ERROR_COMPLETE(err, completion) \
if((completion) != nil) { (completion)((err)); }


@interface DBRequestError (extension)

@property (nonatomic,readonly) BOOL isPathNotFoundError;

@end



typedef enum {
    SYNC_MODE_UNKNOWN,
    SYNC_MODE_MERGE,
    SYNC_MODE_DOWNLOAD,
    SYNC_MODE_UPLOAD
} SyncMode;

@interface DBFileSynchronizer ()

@property (nonatomic,readonly) DBUserClient *restClient;
@property (nonatomic,copy)   NSString *accountId;
@property (nonatomic)        BOOL downloadForMerge;


@end

@implementation DBFileSynchronizer

- (void) dealloc {
}

- (DBUserClient *) restClient {
    return [DBClientsManager authorizedClient];
}

- (NSString *) userId {
    
    NSRange colonRange = [self.accountId rangeOfString:@":"];
    if (colonRange.location != NSNotFound) {
        return [self.accountId substringFromIndex:colonRange.location + 1];
    } else {
        return self.accountId;
    }
}

- (NSURL *) localURLFromDataSource {
    
    NSString *userId = [self userId];
    return [self.dataSource localURLForFileSynchronizer:self withUserId:userId];
    
}

- (NSString *) destFileNameFromDataSource {
    
    NSString *destPath = [self.dataSource destinationPathForFileSynchronizer:self];
    return [destPath lastPathComponent];
    
}

- (NSString *) destFolderFromDataSource {
    
    NSString *destPath = [self.dataSource destinationPathForFileSynchronizer:self];
    return [destPath stringByDeletingLastPathComponent];
    
}

- (NSURL *) URLForMetadataFile {
    
    NSURL *url = nil;
    NSString *userId = [self userId];
    
    if ([self.dataSource respondsToSelector:@selector(localMetadataURLForFileSynchronizer:withUserId:)]) {
        url = [self.dataSource localMetadataURLForFileSynchronizer:self withUserId:userId];
    }
    
    if (url == nil) {

        url = [[self localURLFromDataSource] URLByAppendingPathExtension:@"metadata"];
        
    }
    
    NSString *folder = [url.path stringByDeletingLastPathComponent];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if ([fm fileExistsAtPath:folder isDirectory:&isDir]) {
        if (!isDir) {
            NSLog (@"Error: %@ is not a directory", folder);
            return nil;
        }
    } else {
        NSError *error = nil;
        if (![fm createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog (@"Error: %@", error);
            return nil;
        }
    }
    
    return url;
}

- (DBLocalMetadata *) localMetadata {
    
    NSURL *url = [self URLForMetadataFile];
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:&error];
    if (!data) {
        NSLog (@"Couldn't load metadata: %@", error);
        return nil;
    } else {
        return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    
}

- (NSError *) saveLocalMetadata:(DBMetadata *)metadata {
    
    DBLocalMetadata *localMetadata = [[DBLocalMetadata alloc] initWithMetadata:metadata];
    NSError *error = nil;
    NSURL *metadataURL = [self URLForMetadataFile];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:localMetadata];
    if (![data writeToURL:metadataURL options:0 error:&error]) {
        NSLog (@"Cannot save metadata: %@", error);
    }
    return error;
}

- (void) uploadFileWithParentRev:(NSString *)rev completion:(DBSyncCompletionHandler)completion {
    
    NSURL *url = [self localURLFromDataSource];
    NSString *destFileName = [self destFileNameFromDataSource];
    NSString *destFoldername = [self destFolderFromDataSource];
    
    if (url == nil || destFileName == nil || destFoldername == nil) {
        ERROR_COMPLETE([NSError programmingError:@"Invalid data from DBFileSyncDataSource."], completion)
        return;
    }
    

    if (![[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
        NSLog(@"Local file not found, cannot upload.");
        ERROR_COMPLETE([NSError fileNotFoundError:url.path], completion);
        return;
    }
    
        // v2
        DBFILESWriteMode *writeMode = nil;
        
        if (rev) {
            writeMode = [[DBFILESWriteMode alloc] initWithUpdate:rev];
        } else {
            writeMode = [[DBFILESWriteMode alloc] initWithAdd];
        }
        
        NSString *destPath = [destFoldername stringByAppendingPathComponent:destFileName];
        
        [[self.restClient.filesRoutes uploadUrl:destPath mode:writeMode autorename:@NO clientModified:nil mute:@NO propertyGroups:nil strictConflict:@NO inputUrl:url.path]
            setResponseBlock:^(DBFILESFileMetadata *fileMetadata, DBFILESUploadError *routeError, DBRequestError *error) {
                
                if (fileMetadata) {
                    
                    DBMetadata *metadata = [[DBMetadata alloc] initWithFilesMetadata:fileMetadata];
                    [self restClient:self.restClient uploadedFile:destFileName from:url.path metadata:metadata completion:completion];
                    
                } else {
                    
                    NSError *error = [NSError uploadFileError:destPath];
                    [self restClient:self.restClient uploadFileFailedWithError:error completion:completion];
                    
                }
                
            }
         ];
        
}

- (void) downloadFileAtRev:(NSString *)rev completion:(DBSyncCompletionHandler)completion {
    
    self.downloadForMerge = NO;
    NSURL *url = [self localURLFromDataSource];
    
    NSString *destFileName = [self destFileNameFromDataSource];
    NSString *destFoldername = [self destFolderFromDataSource];
    NSString *destPath = [destFoldername stringByAppendingPathComponent:destFileName];
    NSString *destPathOrRev = nil;
    if (rev != nil) {
        destPathOrRev = [NSString stringWithFormat:@"rev:%@", rev];
    } else {
        destPathOrRev = destPath;
    }
    
    // v2
    [[[self.restClient filesRoutes] downloadUrl:destPathOrRev rev:nil overwrite:YES destination:url]
        setResponseBlock:^(DBFILESFileMetadata *fileMetadata, DBFILESDownloadError *routeError, DBRequestError *error, NSURL *url) {
            
            if (fileMetadata) {
                
                DBMetadata *metadata = [[DBMetadata alloc] initWithFilesMetadata:fileMetadata];
                [self restClient:self.restClient loadedFile:url.path contentType:@"" metadata:metadata completion:completion];
                
            } else {
                
                NSError *error = [NSError downloadFileError:destPathOrRev];
                [self restClient:self.restClient loadFileFailedWithError:error completion:completion];
                
            }
            
        }
     ];
}

- (void) mergeFileAtRev:(NSString *)rev completion:(DBSyncCompletionHandler)completion {
    
    self.downloadForMerge = YES;
    
    NSString *destFileName = [self destFileNameFromDataSource];
    NSString *destFoldername = [self destFolderFromDataSource];
    NSURL *url = [self localURLFromDataSource];
    
    NSString *destPath = [destFoldername stringByAppendingPathComponent:destFileName];
    
    NSString *destPathOrRev = nil;
    if (rev != nil) {
        destPathOrRev = [NSString stringWithFormat:@"rev:%@", rev];
    } else {
        destPathOrRev = destPath;
    }
    
    // v2
    [[[self.restClient filesRoutes] downloadUrl:destPathOrRev rev:nil overwrite:YES destination:url]
     setResponseBlock:^(DBFILESFileMetadata *fileMetadata, DBFILESDownloadError *routeError, DBRequestError *error, NSURL *url) {
         
         if (fileMetadata) {
             
             DBMetadata *metadata = [[DBMetadata alloc] initWithFilesMetadata:fileMetadata];
             [self restClient:self.restClient loadedFile:destPath contentType:@"" metadata:metadata completion:completion];
             
         } else {
             
             NSError *error = [NSError downloadFileError:destPathOrRev];
             [self restClient:self.restClient loadFileFailedWithError:error completion:completion];
             
         }
         
     }];
}

#pragma mark DBRestClientDelegate

- (void) restClient:(DBUserClient *)client loadedMetadata:(DBMetadata *)metadata completion:(DBSyncCompletionHandler)completion {
    
    DBLocalMetadata *localMetadata = [self localMetadata];
    
    NSURL *fileURL = [self localURLFromDataSource];
    if (![[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]) {
        
        /* The file doesn't exist,
         * Download from remote
         */
        [self downloadFileAtRev:metadata.rev completion:completion];
        
    } else {
    
        if (localMetadata == nil) {
            
            /* Local metadata not found but there exists a remote file
             * Do merge
             */
            [self mergeFileAtRev:metadata.rev completion:completion];
            
        } else {
            
            if (metadata.isDeleted) {
                
                [self uploadFileWithParentRev:metadata.rev completion:completion];
                
            } else {
            
                if ([localMetadata.rev isEqualToString:metadata.rev]) {
                    
                    /* Remote file has same version of local file */
                    
                    if (localMetadata.hasLocalChange) {
                        
                        /* Has local change,
                         * Upload the local file
                         */
                        
                        [self uploadFileWithParentRev:metadata.rev completion:completion];
                        
                    } else {
                        
                        /* No local change
                         * The file should be same as remote
                         * Nothing to do
                         */
                        COMPLETE(completion)
                        
                    }
                    
                } else {
                    
                    /* Remote file has different version of local file */
                    
                    if (localMetadata.hasLocalChange) {
                    
                        /* Has local change
                         * Do merge
                         */
                        [self mergeFileAtRev:metadata.rev completion:completion];
                        
                    } else {
                        
                        /* No local change
                         * Download the newer copy
                         */
                        [self downloadFileAtRev:metadata.rev completion:completion];
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
}

- (void) restClient:(DBUserClient *)client loadMetadataFailedWithError:(NSError *)error completion:(DBSyncCompletionHandler)completion {
    
    BOOL fileNotFound = error.code == 404 && [error.domain isEqualToString:@"dropbox.com"];
    
    if (fileNotFound) {
        
        /*
         * The metadata or the file doesn't exist on Dropbox.
         * Just upload the local file.
         */
        [self uploadFileWithParentRev:nil completion:completion];
        
    } else {
        
        if ([self.delegate respondsToSelector:@selector(fileSynchronizer:didFailWithError:)]) {
            [self.delegate fileSynchronizer:self didFailWithError:error];
        }
        ERROR_COMPLETE(error, completion)
        
    }
    
}

- (void) restClient:(DBUserClient *)client loadedFile:(NSString *)destPath contentType:(NSString *)contentType metadata:(DBMetadata *)metadata completion:(DBSyncCompletionHandler)completion {

    if (self.downloadForMerge) {
        
        NSLog (@"Merging remote file");
        if ([self.delegate respondsToSelector:@selector(fileSynchronizer:mergeRemoteFileContentAtPath:)]) {
            [self.delegate fileSynchronizer:self mergeRemoteFileContentAtPath:destPath];
        }

        if ([self localMetadata].hasLocalChange) {
            
            NSLog (@"Uploading merged file");
            [self uploadFileWithParentRev:metadata.rev completion:completion];
            
        } else {
            
            NSLog (@"Remote file is same as local file");
            NSError *error = [self saveLocalMetadata:metadata];
            ERROR_COMPLETE(error, completion)
            
        }
        
    } else {
        
        NSLog (@"Loaded remote file: %@", destPath);
        NSError *error = [self saveLocalMetadata:metadata];
        
        if ([self.delegate respondsToSelector:@selector(fileSynchronizer:didDownloadFileAtPath:)]) {
            [self.delegate fileSynchronizer:self didDownloadFileAtPath:destPath];
        }
        
        ERROR_COMPLETE(error, completion)
    }
    
}

- (void) restClient:(DBUserClient *)client loadFileFailedWithError:(NSError *)error completion:(DBSyncCompletionHandler)completion {
    
    NSLog (@"Error: %@", error);
    if ([self.delegate respondsToSelector:@selector(fileSynchronizer:didFailWithError:)]) {
        [self.delegate fileSynchronizer:self didFailWithError:error];
    }
    ERROR_COMPLETE(error, completion)
}

- (void) restClient:(DBUserClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath metadata:(DBMetadata *)metadata completion:(DBSyncCompletionHandler)completion {
    
    NSLog (@"Uploaded: %@", destPath);
    NSError *error = [self saveLocalMetadata:metadata];
    
    if ([self.delegate respondsToSelector:@selector(fileSynchronizer:didUploadFileAtPath:)]) {
        [self.delegate fileSynchronizer:self didUploadFileAtPath:srcPath];
    }
    ERROR_COMPLETE(error, completion)
}

- (void) restClient:(DBUserClient *)client uploadFileFailedWithError:(NSError *)error completion:(DBSyncCompletionHandler)completion {
    
    NSLog (@"Sync upload failed: %@", error);
    if ([self.delegate respondsToSelector:@selector(fileSynchronizer:didFailWithError:)]) {
        [self.delegate fileSynchronizer:self didFailWithError:error];
    }
    ERROR_COMPLETE(error, completion)
}

#pragma mark public methods

- (void) sync {
    [self sync:nil];
}

- (void) sync:(DBSyncCompletionHandler _Nullable)completion {

    if (self.restClient == nil) {
        
        NSError *error = nil;
        if ([self localMetadata].hasLocalChange) {
            NSLog(@"Warning: couldn't sync local change");
            error = [NSError changesNotSyncedError];
        } else {
            // Not logged in and no Local change.
            // No need to report error for this case.
        }
        ERROR_COMPLETE(error, completion)
        return;
    }
    
    // v2
    // Step 0
    [[[self.restClient usersRoutes] getCurrentAccount]
        setResponseBlock:^(DBUSERSFullAccount *account, DBNilObject *nilObj, DBRequestError *dbError) {

                if (dbError) {
                    ERROR_COMPLETE([NSError errorWithRequestError:dbError], completion)
                    return;
                }
        
                if (nil == account) {
                    ERROR_COMPLETE([NSError notLoggedInError], completion)
                    return;
                }
            
                self.accountId = account.accountId;
                
                /*
                 * Step 1
                 * Download metadata for the file
                 */
                NSString *destFileName = [self destFileNameFromDataSource];
                NSString *destFoldername = [self destFolderFromDataSource];
                NSString *path = [destFoldername stringByAppendingPathComponent:destFileName];
                
                [[[self.restClient filesRoutes] getMetadata:path]
                    setResponseBlock:^(DBFILESMetadata *filesMetadata, DBFILESGetMetadataError *routeError, DBRequestError *dbError) {

                        if (filesMetadata && [filesMetadata isKindOfClass:[DBFILESFileMetadata class]]) {
                            DBMetadata *metadata = [[DBMetadata alloc] initWithFilesMetadata:(DBFILESFileMetadata *)filesMetadata];
                            [self restClient:self.restClient loadedMetadata:metadata completion:completion];
                            
                        } else if (dbError.isPathNotFoundError) {
                            
                            @try {
                                /*
                                 * The metadata or the file doesn't exist on Dropbox.
                                 * Just upload the local file.
                                 */
                                [self uploadFileWithParentRev:nil completion:completion];
                            } @catch( NSException *exception) {
                                NSLog(@"We crashed: %@", exception);
                                ERROR_COMPLETE([NSError errorWithException:exception], completion);
                            }
                            
                        } else {
                           
                            NSError *error = [NSError errorWithRequestError:dbError];
                            [self restClient:self.restClient loadMetadataFailedWithError:error completion:completion];
                        }
                        
                    }
                 ];
                
                
        }
     ];

    
}

- (void) setHasLocalChange:(BOOL)hasLocalChange {
    
    DBLocalMetadata *localMetaData = [self localMetadata];
    localMetaData.hasLocalChange = hasLocalChange;
    [self saveLocalMetadata:localMetaData];
    
}

- (NSDate *) lastModifiedDate {
    return [self localMetadata].lastModifiedDate;
}

@end

@implementation DBRequestError (extension)

- (BOOL) isPathNotFoundError {
    return self.tag == DBRequestErrorHttp &&
    self.statusCode.integerValue == 409 &&
    [self.errorContent hasPrefix:@"path/not_found"];
}

@end
