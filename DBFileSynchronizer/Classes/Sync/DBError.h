//
//  DBError.h
//  Pods
//
//  Created by Eddie Lau on 17/1/2022.
//

#ifndef DBError_h
#define DBError_h

typedef void(^DBSyncCompletionHandler)(NSError * _Nullable);

@class DBRequestError;

typedef NS_ENUM(NSInteger, DBErrorCode) {
    DBErrorCodeNotLoggedIn = 1,
    DBErrorCodeUploadFailed,
    DBErrorCodeDownloadFailed,
    DBErrorCodeFileNotFound,
    DBErrorCodeProgrammingError,
    DBErrorCodeChangesNotSyncedError,
    DBErrorCodeException
};

@interface NSError (extension)

+ (NSError * _Nonnull) notLoggedInError;
+ (NSError * _Nonnull) uploadFileError:(NSString * _Nonnull)destPath;
+ (NSError * _Nonnull) downloadFileError:(NSString * _Nonnull) destPathOrRev;
+ (NSError * _Nonnull) errorWithException:(NSException * _Nonnull)exception;
+ (NSError * _Nonnull) errorWithRequestError:(DBRequestError * _Nonnull)dbError;
+ (NSError * _Nonnull) fileNotFoundError:(NSString * _Nonnull)path;
+ (NSError * _Nonnull) programmingError:(NSString * _Nonnull)description;
+ (NSError * _Nonnull) changesNotSyncedError;
- (BOOL) isOAuthError;
- (NSString * _Nullable) warningMessage;

@end



#endif /* DBError_h */
