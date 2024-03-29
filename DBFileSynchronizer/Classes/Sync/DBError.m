//
//  DBError.m
//  DBFileSynchronizer
//
//  Created by Eddie Lau on 17/1/2022.
//

#import <Foundation/Foundation.h>
#import "DBError.h"
@import ObjectiveDropboxOfficial;

#define ErrDomain @"DBFileSynchronizer"

@implementation NSError (extension)

+ (NSError *) notLoggedInError {
    return [NSError errorWithDomain:ErrDomain
                               code:DBErrorCodeNotLoggedIn
                           userInfo:@{NSLocalizedDescriptionKey:@"Not logged in"}];
}

+ (NSError *) uploadFileError:(NSString *)destPath {
    
    NSString *message =
        [NSString stringWithFormat:@"Couldn't upload file: %@", destPath];
    
    return
        [NSError errorWithDomain:ErrDomain
                            code:DBErrorCodeUploadFailed
                        userInfo:@{NSLocalizedDescriptionKey:message}];
}

+ (NSError *) downloadFileError:(NSString *) destPathOrRev {
    
    NSString *message =
        [NSString stringWithFormat:@"Couldn't load file: %@", destPathOrRev];

    return
        [NSError errorWithDomain:ErrDomain
                            code:DBErrorCodeDownloadFailed
                        userInfo:@{NSLocalizedDescriptionKey:message}];
}

+ (NSError *) errorWithException:(NSException *)exception {
    
    return
        [NSError errorWithDomain:@"Exception"
                            code:DBErrorCodeException
                        userInfo:@{NSLocalizedDescriptionKey:exception.description}];

}

+ (NSError *) errorWithRequestError:(DBRequestError *)dbError {
    
    NSString *message = dbError.errorContent;
    if (message == nil) {
        message = [NSString stringWithFormat:@"Error message: %@", dbError.description];
    }
    
    return
        [NSError errorWithDomain:dbError.tagName
                            code:dbError.statusCode.integerValue
                        userInfo:@{NSLocalizedDescriptionKey:message}];
    
}

+ (NSError *) fileNotFoundError:(NSString *)path {
    
    NSString *message = [NSString stringWithFormat:@"File not found: %@", path];
    return
        [NSError errorWithDomain:ErrDomain
                            code:DBErrorCodeFileNotFound
                        userInfo:@{NSLocalizedDescriptionKey:message}];

}

+ (NSError *) programmingError:(NSString *)description {
    
    NSString *message = [NSString stringWithFormat:@"Programming Error: %@", description];
    return
        [NSError errorWithDomain:ErrDomain
                            code:DBErrorCodeProgrammingError
                        userInfo:@{NSLocalizedDescriptionKey:message}];
}

+ (NSError *) changesNotSyncedError {
    return [NSError errorWithDomain:ErrDomain
                               code:DBErrorCodeChangesNotSyncedError
                           userInfo:@{NSLocalizedDescriptionKey:@"Changes not synced."}];
}

- (BOOL) isOAuthError {
    return [[self domain] isEqualToString:@"com.dropbox.dropbox_sdk_obj_c.oauth.error"];
}

- (NSString *) warningMessage {
    
    NSString *message = nil;
    
    if ([DBClientsManager authorizedClient] != nil) {
        if ([self.domain isEqualToString:ErrDomain]) {
            message = [NSString stringWithFormat:@"⚠️ 上次備份時發生錯誤(%ld)。", self.code];
        }
    } else {
        if (self.isOAuthError) {
            message = @"⚠️ 登入時發生錯誤，請重新再試。";
        } else
        if (self.code == DBErrorCodeChangesNotSyncedError) {
            message = @"⚠️ 有新的資料未備份，請登入以啟動備份。";
        } else {
            message = @"⚠️ 請登入以啟動備份。";
        }
    }
    
    return message;
}

@end
