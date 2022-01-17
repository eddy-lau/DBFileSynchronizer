//
//  DBError.h
//  Pods
//
//  Created by Eddie Lau on 17/1/2022.
//

#ifndef DBError_h
#define DBError_h

typedef NS_ENUM(NSInteger, DBErrorCode) {
    DBErrorCodeNotLoggedIn,
    DBErrorCodeUploadFailed,
    DBErrorCodeDownloadFailed
};

@interface NSError (extension)

+ (NSError *) notLoggedInError;
+ (NSError *) uploadFileError:(NSString *)destPath;
+ (NSError *) downloadFileError:(NSString *) destPathOrRev;


@end



#endif /* DBError_h */
