//
//  DBMetadata.m
//  DropboxSDK
//
//  Created by Brian Smith on 5/3/10.
//  Copyright 2010 Dropbox, Inc. All rights reserved.
//

#import "DBMetadata.h"

@implementation DBMetadata

+ (BOOL) supportsSecureCoding {
    return YES;
}

+ (NSDateFormatter*)dateFormatter {
    NSMutableDictionary* dictionary = [[NSThread currentThread] threadDictionary];
    static NSString* dateFormatterKey = @"DBMetadataDateFormatter";
    
    NSDateFormatter* dateFormatter = [dictionary objectForKey:dateFormatterKey];
    if (dateFormatter == nil) {
        dateFormatter = [NSDateFormatter new];
        // Must set locale to ensure consistent parsing:
        // http://developer.apple.com/iphone/library/qa/qa2010/qa1480.html
        dateFormatter.locale = 
            [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        dateFormatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss Z";
        [dictionary setObject:dateFormatter forKey:dateFormatterKey];
    }
    return dateFormatter;
}

- (id)initWithDictionary:(NSDictionary*)dict {
    if ((self = [super init])) {
        thumbnailExists = [[dict objectForKey:@"thumb_exists"] boolValue];
        totalBytes = [[dict objectForKey:@"bytes"] longLongValue];

        if ([dict objectForKey:@"modified"]) {
            lastModifiedDate = 
                [[DBMetadata dateFormatter] dateFromString:[dict objectForKey:@"modified"]];
        }

        if ([dict objectForKey:@"client_mtime"]) {
            clientMtime =
                [[DBMetadata dateFormatter] dateFromString:[dict objectForKey:@"client_mtime"]];
        }

        path = [dict objectForKey:@"path"];
        isDirectory = [[dict objectForKey:@"is_dir"] boolValue];
        
        if ([dict objectForKey:@"contents"]) {
            NSArray* subfileDicts = [dict objectForKey:@"contents"];
            NSMutableArray* mutableContents = 
                [[NSMutableArray alloc] initWithCapacity:[subfileDicts count]];
            for (NSDictionary* subfileDict in subfileDicts) {
                DBMetadata* subfile = [[DBMetadata alloc] initWithDictionary:subfileDict];
                [mutableContents addObject:subfile];
            }
            contents = mutableContents;
        }
        
        hash = [dict objectForKey:@"hash"];
        humanReadableSize = [dict objectForKey:@"size"];
        root = [dict objectForKey:@"root"];
        icon = [dict objectForKey:@"icon"];
        rev = [dict objectForKey:@"rev"];
        revision = [[dict objectForKey:@"revision"] longLongValue];
        isDeleted = [[dict objectForKey:@"is_deleted"] boolValue];
        
        if ([dict objectForKey:@"video_info"]) {
            NSDictionary * videoInfoDict =  [dict objectForKey:@"video_info"];
            
            NSNumber * duration = [videoInfoDict objectForKey:@"duration"];
            if (duration && duration != (id)[NSNull null] && [duration isKindOfClass:[NSNumber class]]) {
                videoDuration = [duration intValue];
            }
        }
        
    }
    return self;
}

- (id)initWithFilesMetadata:(DBFILESFileMetadata *)filesMetadata {
    
    self = [super init];
    if (self) {
        
        thumbnailExists = NO; // Unknown
        totalBytes = [filesMetadata.size longLongValue];
        lastModifiedDate = filesMetadata.serverModified;
        clientMtime = filesMetadata.clientModified;
        path = filesMetadata.pathDisplay;
        isDirectory = NO; // See below
        contents = [[NSMutableArray alloc] init];
        hash = @"";
        humanReadableSize = [NSString stringWithFormat:@"%@", filesMetadata.size];
        root = nil;
        icon = nil;
        rev = filesMetadata.rev;
        revision = [filesMetadata.rev longLongValue];
        isDeleted = NO; // See below
        videoDuration = 0;
        
        for (DBFILEPROPERTIESPropertyGroup *propertyGroup in filesMetadata.propertyGroups) {
            for (DBFILEPROPERTIESPropertyField *field in propertyGroup.fields) {
                if ([field.name isEqualToString:@"tag"]) {
                    isDirectory = [field.value isEqualToString:@"folder"];
                    isDeleted = [field.value isEqualToString:@"deleted"];
                }
            }
        }
        
        
    }
    return self;
    
    
}

- (void)dealloc {
    lastModifiedDate = nil;
    clientMtime = nil;
    path = nil;
    contents = nil;
    hash = nil;
    humanReadableSize = nil;
    root = nil;
    icon = nil;
    rev = nil;
    filename = nil;
}

@synthesize thumbnailExists;
@synthesize totalBytes;
@synthesize lastModifiedDate;
@synthesize clientMtime;
@synthesize path;
@synthesize isDirectory;
@synthesize contents;
@synthesize hash;
@synthesize humanReadableSize;
@synthesize root;
@synthesize icon;
@synthesize rev;
@synthesize revision;
@synthesize isDeleted;
@synthesize videoDuration;

- (BOOL)isEqual:(id)object {
    if (object == self) return YES;
    if (![object isKindOfClass:[DBMetadata class]]) return NO;
    DBMetadata *other = (DBMetadata *)object;
    return [self.rev isEqualToString:other.rev];
}

- (NSString *)filename {
    if (filename == nil) {
        filename = [path lastPathComponent];
    }
    return filename;
}

#pragma mark NSCoding methods

- (id)initWithCoder:(NSCoder*)coder {
    if ((self = [super init])) {
        thumbnailExists = [coder decodeBoolForKey:@"thumbnailExists"];
        totalBytes = [coder decodeInt64ForKey:@"totalBytes"];
        lastModifiedDate = [coder decodeObjectOfClass:[NSDate class] forKey:@"lastModifiedDate"];
        clientMtime = [coder decodeObjectOfClass:[NSDate class] forKey:@"clientMtime"];
        path = [coder decodeObjectOfClass:[NSString class] forKey:@"path"];
        isDirectory = [coder decodeBoolForKey:@"isDirectory"];
        contents = [coder decodeObjectOfClass:[NSArray class] forKey:@"contents"];
        hash = [coder decodeObjectOfClass:[NSString class] forKey:@"hash"];
        humanReadableSize = [coder decodeObjectOfClass:[NSString class] forKey:@"humanReadableSize"];
        root = [coder decodeObjectOfClass:[NSString class] forKey:@"root"];
        icon = [coder decodeObjectOfClass:[NSString class] forKey:@"icon"];
        rev = [coder decodeObjectOfClass:[NSString class] forKey:@"rev"];
        revision = [coder decodeInt64ForKey:@"revision"];
        isDeleted = [coder decodeBoolForKey:@"isDeleted"];
		if( [coder containsValueForKey:@"videoDuration"] )
		{
			videoDuration = [coder decodeIntegerForKey:@"videoDuration"];
		}
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder {
    [coder encodeBool:thumbnailExists forKey:@"thumbnailExists"];
    [coder encodeInt64:totalBytes forKey:@"totalBytes"];
    [coder encodeObject:lastModifiedDate forKey:@"lastModifiedDate"];
    [coder encodeObject:clientMtime forKey:@"clientMtime"];
    [coder encodeObject:path forKey:@"path"];
    [coder encodeBool:isDirectory forKey:@"isDirectory"];
    [coder encodeObject:contents forKey:@"contents"];
    [coder encodeObject:hash forKey:@"hash"];
    [coder encodeObject:humanReadableSize forKey:@"humanReadableSize"];
    [coder encodeObject:root forKey:@"root"];
    [coder encodeObject:icon forKey:@"icon"];
    [coder encodeObject:rev forKey:@"rev"];
    [coder encodeInt64:revision forKey:@"revision"];
    [coder encodeBool:isDeleted forKey:@"isDeleted"];
    [coder encodeInteger:videoDuration forKey:@"videoDuration"];
}

@end
