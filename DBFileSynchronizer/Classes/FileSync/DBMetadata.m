//
//  DBMetadata.m
//  DropboxSDK
//
//  Created by Brian Smith on 5/3/10.
//  Copyright 2010 Dropbox, Inc. All rights reserved.
//

#import "DBMetadata.h"

@implementation DBMetadata

+ (NSDateFormatter*)dateFormatter {
    NSMutableDictionary* dictionary = [[NSThread currentThread] threadDictionary];
    static NSString* dateFormatterKey = @"DBMetadataDateFormatter";
    
    NSDateFormatter* dateFormatter = [dictionary objectForKey:dateFormatterKey];
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter new] autorelease];
        // Must set locale to ensure consistent parsing:
        // http://developer.apple.com/iphone/library/qa/qa2010/qa1480.html
        dateFormatter.locale = 
            [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease];
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
                [[[DBMetadata dateFormatter] dateFromString:[dict objectForKey:@"modified"]] retain];
        }

        if ([dict objectForKey:@"client_mtime"]) {
            clientMtime =
                [[[DBMetadata dateFormatter] dateFromString:[dict objectForKey:@"client_mtime"]] retain];
        }

        path = [[dict objectForKey:@"path"] retain];
        isDirectory = [[dict objectForKey:@"is_dir"] boolValue];
        
        if ([dict objectForKey:@"contents"]) {
            NSArray* subfileDicts = [dict objectForKey:@"contents"];
            NSMutableArray* mutableContents = 
                [[NSMutableArray alloc] initWithCapacity:[subfileDicts count]];
            for (NSDictionary* subfileDict in subfileDicts) {
                DBMetadata* subfile = [[DBMetadata alloc] initWithDictionary:subfileDict];
                [mutableContents addObject:subfile];
                [subfile release];
            }
            contents = mutableContents;
        }
        
        hash = [[dict objectForKey:@"hash"] retain];
        humanReadableSize = [[dict objectForKey:@"size"] retain];
        root = [[dict objectForKey:@"root"] retain];
        icon = [[dict objectForKey:@"icon"] retain];
        rev = [[dict objectForKey:@"rev"] retain];
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
        lastModifiedDate = [filesMetadata.serverModified retain];
        clientMtime = [filesMetadata.clientModified retain];
        path = [filesMetadata.pathDisplay retain];;
        isDirectory = NO; // See below
        contents = [[NSMutableArray alloc] init];
        hash = [@"" retain];
        humanReadableSize = [[NSString stringWithFormat:@"%@", filesMetadata.size] retain];
        root = nil;
        icon = nil;
        rev = [filesMetadata.rev retain];
        revision = [filesMetadata.rev retain];
        isDeleted = NO; // See below
        videoDuration = 0;
        
        for (DBPROPERTIESPropertyGroup *propertyGroup in filesMetadata.propertyGroups) {
            for (DBPROPERTIESPropertyField *field in propertyGroup.fields) {
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
    [lastModifiedDate release];
    [clientMtime release];
    [path release];
    [contents release];
    [hash release];
    [humanReadableSize release];
    [root release];
    [icon release];
    [rev release];
    [filename release];
    [super dealloc];
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
        filename = [[path lastPathComponent] retain];
    }
    return filename;
}

#pragma mark NSCoding methods

- (id)initWithCoder:(NSCoder*)coder {
    if ((self = [super init])) {
        thumbnailExists = [coder decodeBoolForKey:@"thumbnailExists"];
        totalBytes = [coder decodeInt64ForKey:@"totalBytes"];
        lastModifiedDate = [[coder decodeObjectForKey:@"lastModifiedDate"] retain];
        clientMtime = [[coder decodeObjectForKey:@"clientMtime"] retain];
        path = [[coder decodeObjectForKey:@"path"] retain];
        isDirectory = [coder decodeBoolForKey:@"isDirectory"];
        contents = [[coder decodeObjectForKey:@"contents"] retain];
        hash = [[coder decodeObjectForKey:@"hash"] retain];
        humanReadableSize = [[coder decodeObjectForKey:@"humanReadableSize"] retain];
        root = [[coder decodeObjectForKey:@"root"] retain];
        icon = [[coder decodeObjectForKey:@"icon"] retain];
        rev = [[coder decodeObjectForKey:@"rev"] retain];
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
