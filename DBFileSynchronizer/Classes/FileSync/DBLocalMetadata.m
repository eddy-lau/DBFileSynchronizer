//
//  DBLocalMetadata.m
//  ChineseDailyBread
//
//  Created by Eddie Hiu-Fung Lau on 12/4/14.
//
//

#import "DBLocalMetadata.h"

@implementation DBLocalMetadata

- (id) initWithMetadata:(DBMetadata *)metadata {
    
    self = [super init];
    if (self) {
        
        thumbnailExists = metadata.thumbnailExists;
        totalBytes = metadata.totalBytes;
        lastModifiedDate = [metadata.lastModifiedDate copy];
        clientMtime = [metadata.clientMtime copy];
        path = [metadata.path copy];
        isDirectory = metadata.isDirectory;
        contents = [metadata.contents copy];
        hash = [metadata.hash copy];
        humanReadableSize = [metadata.humanReadableSize copy];
        root = [metadata.root copy];
        icon = [metadata.icon copy];
        rev = [metadata.rev copy];
        revision = metadata.revision;
        isDeleted = metadata.isDeleted;
        
        filename = [metadata.filename copy];
        
        if ([metadata isKindOfClass:[DBLocalMetadata class]]) {
            self.hasLocalChange = ((DBLocalMetadata *)metadata).hasLocalChange;
        }

    }
    return self;
    
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [super encodeWithCoder:aCoder];
    [aCoder encodeBool:self.hasLocalChange forKey:@"hasLocalChange"];
    
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.hasLocalChange = [aDecoder decodeBoolForKey:@"hasLocalChange"];
    }
    return self;
    
}


@end
