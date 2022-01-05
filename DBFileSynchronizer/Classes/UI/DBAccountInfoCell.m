//
//  DBAccountInfoCell.m
//  ChineseDailyBread
//
//  Created by Eddie Hiu-Fung Lau on 9/4/14.
//
//

#import "DBAccountInfoCell.h"
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

@interface DBAccountInfoCell ()

@property (nonatomic,retain) DBUserClient *restClient;
@property (nonatomic,retain) DBUSERSAccount *accountInfo;
@property (nonatomic,readonly) BOOL isLinked;

@end

@implementation DBAccountInfoCell

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.text = @"戶口";
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (BOOL) isLinked {
    return [DBClientsManager authorizedClient] != nil;
}

//typedef void (^DBCleanupBlock)(void);

- (void) reload {
    [self reloadWithCompletionBlock:NULL];
}

- (void) reloadWithCompletionBlock:(DBAccountInfoCellCompletionBlock)completionBlock {

    if (self.isLinked) {

        if (self.accountInfo == nil) {
            self.detailTextLabel.text = nil;
            self.restClient = [DBClientsManager authorizedClient];
            [[self.restClient.usersRoutes getCurrentAccount]
                setResponseBlock:^(DBUSERSFullAccount *account, DBNilObject * nilObject, DBRequestError * error) {
                
                    [self restClient:self.restClient loadedAccountInfo:account error:error];
                    if (completionBlock) {
                        completionBlock(account != nil);
                    }
                    
                }];
            
            UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [activityIndicator startAnimating];
            activityIndicator.hidden = NO;
            
            self.accessoryView = activityIndicator;
            
            
        } else {
            self.detailTextLabel.text = self.accountInfo.name.displayName;
        }
        
    } else {
        
        self.detailTextLabel.text = @"已登出"; //ZHLocalizedString(@"Unlinked", @"");
        
    }
    
}

- (void)restClient:(DBUserClient *)client loadedAccountInfo:(DBUSERSAccount *)info error:(DBRequestError *) error{
    
    if (client == self.restClient) {
        
        DBUserClient *retainCycle = client;
        
        if (error) {
            
            NSLog(@"Error: %@", error);
            self.accountInfo = nil;
            self.detailTextLabel.text = @"已登出"; //ZHLocalizedString(@"Unlinked", @"");
            [DBClientsManager unlinkAndResetClients];
            
        } else if (info != nil) {
            
            self.accountInfo = info;
            self.detailTextLabel.text = info.name.displayName;
            
        }
        
        self.restClient = nil;
        self.accessoryView = nil;
        [self setNeedsLayout];
        retainCycle = nil;
    }
    
}

@end
