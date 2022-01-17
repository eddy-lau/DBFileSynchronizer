//
//  DBError.m
//  DBFileSynchronizer
//
//  Created by Eddie Lau on 17/1/2022.
//

#import <Foundation/Foundation.h>
#import "DBError.h"

#define ErrDomain @"DBFileSynchronizer"

@implementation NSError (extension)

+ (NSError *) notLoggedInError {
    return [NSError errorWithDomain:ErrDomain code:DBErrorCodeNotLoggedIn userInfo:nil];
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

@end
