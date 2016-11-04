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

typedef enum {
    SYNC_MODE_UNKNOWN,
    SYNC_MODE_MERGE,
    SYNC_MODE_DOWNLOAD,
    SYNC_MODE_UPLOAD
} SyncMode;

@interface DBFileSynchronizer ()

@property (nonatomic,retain) DropboxClient *restClient;
@property (nonatomic,copy)   NSString *accountId;
@property (nonatomic)        BOOL downloadForMerge;


@end

@implementation DBFileSynchronizer

- (void) dealloc {
    self.restClient = nil;
    [super dealloc];
}

- (NSString *) userId {
    
    NSRange colonRange = [self.accountId rangeOfString:@":"];
    if (colonRange.location != NSNotFound) {
        return [self.accountId substringFromIndex:colonRange.location + 1];
    } else {
        return self.accountId;
    }
}

- (NSURL *) URLForMetadataFile {
    
    NSURL *url = nil;
    NSString *userId = [self userId];
    
    if ([self.dataSource respondsToSelector:@selector(URLForMetadataFileInController:withUserId:)]) {
        
        url = [self.dataSource URLForMetadataFileInController:self withUserId:userId];
        
    }
    
    if (url == nil) {
        
        url = [[self.dataSource URLForFileToSyncInController:self withUserId:userId] URLByAppendingPathExtension:@"metadata"];
        
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

- (void) saveLocalMetadata:(DBMetadata *)metadata {
    
    DBLocalMetadata *localMetadata = [[DBLocalMetadata alloc] initWithMetadata:metadata];
    NSError *error = nil;
    NSURL *metadataURL = [self URLForMetadataFile];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:localMetadata];
    if (![data writeToURL:metadataURL options:0 error:&error]) {
        NSLog (@"Cannot save metadata: %@", error);
    }
}

- (void) uploadFileWithParentRev:(NSString *)rev {
    
    NSURL *url = [self.dataSource URLForFileToSyncInController:self withUserId:[self userId]];
    NSString *destFileName = [self.dataSource destinationFileNameInController:self];
    NSString *destFoldername = [self.dataSource destinationFolderInController:self];
    
    if (url && destFoldername && destFileName) {
        
        // v1
        // [self.restClient uploadFile:destFileName toPath:destFoldername withParentRev:rev fromPath:url.path];
        
        // v2
        DBFILESWriteMode *writeMode = nil;
        
        if (rev) {
            writeMode = [[[DBFILESWriteMode alloc] initWithUpdate:rev] autorelease];
        } else {
            writeMode = [[[DBFILESWriteMode alloc] initWithAdd] autorelease];
        }
        
        NSString *destPath = [destFoldername stringByAppendingPathComponent:destFileName];
        [[self.restClient.filesRoutes uploadUrl:destPath mode:writeMode autorename:@NO clientModified:nil mute:@NO inputUrl:url]
            response:^(DBFILESFileMetadata *fileMetadata, DBFILESUploadError *routeError, DBError *error) {
                
                if (fileMetadata) {
                    
                    DBMetadata *metadata = [[[DBMetadata alloc] initWithFilesMetadata:fileMetadata] autorelease];
                    [self restClient:self.restClient uploadedFile:destFileName from:url.path metadata:metadata];
                    
                } else {
                    
                    [self restClient:self.restClient uploadFileFailedWithError:routeError];
                    
                }
                
            }
         ];
        
    } else {
        NSLog(@"Null URL or destFileName or destFolderName");
    }
}

- (void) downloadFileAtRev:(NSString *)rev {
    
    self.downloadForMerge = NO;
    NSURL *url = [self.dataSource URLForFileToSyncInController:self withUserId:[self userId]];
    
    NSString *destFileName = [self.dataSource destinationFileNameInController:self];
    NSString *destFoldername = [self.dataSource destinationFolderInController:self];
    NSString *destPath = [destFoldername stringByAppendingPathComponent:destFileName];
    NSString *destPathOrRev = nil;
    if (rev != nil) {
        destPathOrRev = [NSString stringWithFormat:@"rev:%@", rev];
    } else {
        destPathOrRev = destPath;
    }
    
    // v1
    //[self.restClient loadFile:destPath atRev:rev intoPath:url.path];
    
    // v2
    [[[self.restClient filesRoutes] downloadUrl:destPathOrRev rev:nil overwrite:YES destination:url]
        response:^(DBFILESFileMetadata *fileMetadata, DBFILESDownloadError *routeError, DBError *error, NSURL *url) {
            
            if (fileMetadata) {
                
                DBMetadata *metadata = [[[DBMetadata alloc] initWithFilesMetadata:fileMetadata] autorelease];
                [self restClient:self.restClient loadedFile:url.path contentType:@"" metadata:metadata];
                
            } else {
                
                [self restClient:self.restClient loadFileFailedWithError:routeError];
                
            }
            
        }
     ];
}

- (void) mergeFileAtRev:(NSString *)rev {
    
    self.downloadForMerge = YES;
    
    NSString *destFileName = [self.dataSource destinationFileNameInController:self];
    NSString *destFoldername = [self.dataSource destinationFolderInController:self];
    NSURL *url = [self.dataSource URLForFileToSyncInController:self withUserId:[self userId]];
    
    NSString *destPath = [destFoldername stringByAppendingPathComponent:destFileName];
    NSString *ext = url.path.pathExtension;
    NSString *localFile = [[[url.path stringByDeletingPathExtension] stringByAppendingFormat:@".%@", rev] stringByAppendingPathExtension:ext];
    
    NSString *destPathOrRev = nil;
    if (rev != nil) {
        destPathOrRev = [NSString stringWithFormat:@"rev:%@", rev];
    } else {
        destPathOrRev = destPath;
    }
    
    // v1
    //[self.restClient loadFile:destPath atRev:rev intoPath:localFile];
    
    // v2
    [[[self.restClient filesRoutes] downloadUrl:destPathOrRev rev:nil overwrite:YES destination:url]
     response:^(DBFILESFileMetadata *fileMetadata, DBFILESDownloadError *routeError, DBError *error, NSURL *url) {
         
         if (fileMetadata) {
             
             DBMetadata *metadata = [[[DBMetadata alloc] initWithFilesMetadata:fileMetadata] autorelease];
             [self restClient:self.restClient loadedFile:destPath contentType:@"" metadata:metadata];
             
         } else {
             
             [self restClient:self.restClient loadFileFailedWithError:routeError];
             
         }
         
     }
     ];
}

#pragma mark DBRestClientDelegate

- (void) restClient:(DropboxClient *)client loadedMetadata:(DBMetadata *)metadata {
    
    DBLocalMetadata *localMetadata = [self localMetadata];
    
    NSURL *fileURL = [self.dataSource URLForFileToSyncInController:self withUserId:[self userId]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]) {
        
        /* The file doesn't exist,
         * Download from remote
         */
        [self downloadFileAtRev:metadata.rev];
        
    } else {
    
        if (localMetadata == nil) {
            
            /* Local metadata not found but there exists a remote file
             * Do merge
             */
            [self mergeFileAtRev:metadata.rev];
            
        } else {
            
            if (metadata.isDeleted) {
                
                [self uploadFileWithParentRev:metadata.rev];
                
            } else {
            
                if ([localMetadata.rev isEqualToString:metadata.rev]) {
                    
                    /* Remote file has same version of local file */
                    
                    if (localMetadata.hasLocalChange) {
                        
                        /* Has local change,
                         * Upload the local file
                         */
                        
                        [self uploadFileWithParentRev:metadata.rev];
                        
                    } else {
                        
                        /* No local change
                         * The file should be same as remote
                         * Nothing to do
                         */
                        
                    }
                    
                } else {
                    
                    /* Remote file has different version of local file */
                    
                    if (localMetadata.hasLocalChange) {
                    
                        /* Has local change
                         * Do merge
                         */
                        [self mergeFileAtRev:metadata.rev];
                        
                    } else {
                        
                        /* No local change
                         * Download the newer copy
                         */
                        [self downloadFileAtRev:metadata.rev];
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
}

- (void) restClient:(DropboxClient *)client loadMetadataFailedWithError:(NSError *)error {
    
    BOOL fileNotFound = error.code == 404 && [error.domain isEqualToString:@"dropbox.com"];
    
    if (fileNotFound) {
        
        /*
         * The metadata or the file doesn't exist on Dropbox.
         * Just upload the local file.
         */
        [self uploadFileWithParentRev:nil];
        
    } else {
        
        if ([self.delegate respondsToSelector:@selector(fileSynchronizer:didFailWithError:)]) {
            [self.delegate fileSynchronizer:self didFailWithError:error];
        }
        
    }
    
}

- (void) restClient:(DropboxClient *)client loadedFile:(NSString *)destPath contentType:(NSString *)contentType metadata:(DBMetadata *)metadata {

    if (self.downloadForMerge) {
        
        NSLog (@"Merging remote file");
        if ([self.delegate respondsToSelector:@selector(fileSynchronizer:mergeRemoteFileContentAtPath:)]) {
            [self.delegate fileSynchronizer:self mergeRemoteFileContentAtPath:destPath];
        }

        if ([self localMetadata].hasLocalChange) {
            
            NSLog (@"Uploading merged file");
            [self uploadFileWithParentRev:metadata.rev];
            
        } else {
            
            NSLog (@"Remote file is same as local file");
            [self saveLocalMetadata:metadata];
            
        }
        
    } else {
        
        NSLog (@"Loaded remote file: %@", destPath);
        [self saveLocalMetadata:metadata];
        
        if ([self.delegate respondsToSelector:@selector(fileSynchronizer:didDownloadFileAtPath:)]) {
            [self.delegate fileSynchronizer:self didDownloadFileAtPath:destPath];
        }
        
    }
    
}

- (void) restClient:(DropboxClient *)client loadFileFailedWithError:(NSError *)error {
    
    NSLog (@"Error: %@", error);
    if ([self.delegate respondsToSelector:@selector(fileSynchronizer:didFailWithError:)]) {
        [self.delegate fileSynchronizer:self didFailWithError:error];
    }
    
}

- (void) restClient:(DropboxClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath metadata:(DBMetadata *)metadata {
    
    NSLog (@"Uploaded: %@", destPath);
    [self saveLocalMetadata:metadata];
    
    if ([self.delegate respondsToSelector:@selector(fileSynchronizer:didUploadFileAtPath:)]) {
        [self.delegate fileSynchronizer:self didUploadFileAtPath:srcPath];
    }
}

- (void) restClient:(DropboxClient *)client uploadFileFailedWithError:(NSError *)error {
    
    NSLog (@"Sync upload failed: %@", error);
    if ([self.delegate respondsToSelector:@selector(fileSynchronizer:didFailWithError:)]) {
        [self.delegate fileSynchronizer:self didFailWithError:error];
    }
}

#pragma mark public methods

- (void) reset {
    self.restClient = nil;
}

- (void) sync {
    
    DropboxClient *authorizedClient = [DropboxClientsManager authorizedClient];
    if (authorizedClient == nil) {
        return;
    }
    
    if (self.restClient == nil) {
        self.restClient = authorizedClient;
    }
    
    // v2
    // Step 0
    [[[self.restClient usersRoutes] getCurrentAccount]
        response:^(DBUSERSFullAccount *account, DBNilObject *nilObj, DBError *error) {
            
            if (account) {
                
                self.accountId = account.accountId;
                
                /*
                 * Step 1
                 * Download metadata for the file
                 */
                NSString *destFileName = [self.dataSource destinationFileNameInController:self];
                NSString *destFoldername = [self.dataSource destinationFolderInController:self];
                NSString *path = [destFoldername stringByAppendingPathComponent:destFileName];
                
                // v1
                // [self.restClient loadMetadata:path];
                
                // v2
                [[[self.restClient filesRoutes] getMetadata:path]
                    response:^(DBFILESMetadata *filesMetadata, DBFILESGetMetadataError *routeError, DBError *error) {

                        if (filesMetadata) {
                            DBMetadata *metadata = [[[DBMetadata alloc] initWithFilesMetadata:filesMetadata] autorelease];
                            [self restClient:self.restClient loadedMetadata:metadata];
                        } else {
                            [self restClient:self.restClient loadMetadataFailedWithError:routeError];
                        }
                        
                    }
                 ];
                
                
            } else {
                
                [self restClient:self.restClient loadMetadataFailedWithError:error];
            }
            
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
