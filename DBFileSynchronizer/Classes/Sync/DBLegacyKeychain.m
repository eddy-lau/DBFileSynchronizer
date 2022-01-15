///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Security/Security.h>

#import "DBLegacyKeychain.h"

@implementation DBLegacyKeychain

+ (BOOL)set:(NSString *)key value:(NSString *)value {
  NSData *encoding = [value dataUsingEncoding:NSUTF8StringEncoding];
  if (encoding) {
    return [self setWithData:key value:encoding];
  } else {
    return NO;
  }
}

+ (NSString *)get:(NSString *)key {
  NSData *data = [self getAsData:key];
  if (data != nil) {
    return [NSString stringWithUTF8String:[data bytes]];
  } else {
    return nil;
  }
}

+ (NSArray<NSString *> *)getAll {
  NSMutableDictionary<NSString *, id> *query = [self queryWithDict:@{
    (NSString *)kSecReturnAttributes : (id)kCFBooleanTrue,
    (NSString *)kSecMatchLimit : (id)kSecMatchLimitAll
  }];

  CFDataRef dataResult = nil;
  OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&dataResult);

  NSMutableArray<NSString *> *results = [[NSMutableArray alloc] init];

  if (status == noErr) {
    NSData *data = (__bridge NSData *)dataResult;
    NSArray<NSDictionary<NSString *, id> *> *dataResultDict = (NSArray<NSDictionary<NSString *, id> *> *)data ?: @[];
    for (NSDictionary<NSString *, id> *dict in dataResultDict) {
      [results addObject:(NSString *)dict[@"acct"]];
    }
  }

  return results;
}

+ (BOOL) delete:(NSString *)key {
  NSMutableDictionary<NSString *, id> *query = [self queryWithDict:@{(id)kSecAttrAccount : key}];
  return SecItemDelete((__bridge CFDictionaryRef)query) == noErr;
}

+ (BOOL)clear {
  NSMutableDictionary<NSString *, id> *query = [self queryWithDict:@{}];
  return SecItemDelete((__bridge CFDictionaryRef)query) == noErr;
}

+ (BOOL)setWithData:(NSString *)key value:(NSData *)value {
  NSMutableDictionary<NSString *, id> *query =
      [self queryWithDict:@{(id)kSecAttrAccount : key, (id)kSecValueData : value}];

  SecItemDelete((__bridge CFDictionaryRef)query);

  return SecItemAdd((__bridge CFDictionaryRef)query, nil) == noErr;
}

+ (NSData *)getAsData:(NSString *)key {
  NSMutableDictionary<NSString *, id> *query = [self queryWithDict:@{
    (id)kSecAttrAccount : key,
    (id)kSecReturnData : (id)kCFBooleanTrue,
    (id)kSecMatchLimit : (id)kSecMatchLimitOne
  }];

  CFDataRef dataResult = NULL;
  OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&dataResult);

  if (status == noErr) {
    return (__bridge NSData *)dataResult;
  }
  return nil;
}

+ (NSMutableDictionary<NSString *, id> *)queryWithDict:(NSDictionary<NSString *, id> *)query {
  NSMutableDictionary<NSString *, id> *queryResult = [query mutableCopy];
  NSString *bundleId = [NSBundle mainBundle].bundleIdentifier ?: @"";

  [queryResult setObject:(id)kSecClassGenericPassword forKey:(NSString *)kSecClass];
  [queryResult setObject:(id)[NSString stringWithFormat:@"%@.dropbox.authv2", bundleId]
                  forKey:(NSString *)kSecAttrService];

  return queryResult;
}

@end
