//
//  DBLocalMetadata.h
//  ChineseDailyBread
//
//  Created by Eddie Hiu-Fung Lau on 12/4/14.
//
//

#import "DBMetadata.h"

@interface DBLocalMetadata : DBMetadata

- (id) initWithMetadata:(DBMetadata *)metadata;

@property (nonatomic) BOOL hasLocalChange;


@end
