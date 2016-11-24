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

@property (nonatomic,retain) DropboxClient *restClient;
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
    return [DropboxClientsManager authorizedClient] != nil;
}

- (void) reload {
    
    if (self.isLinked) {

        if (self.accountInfo == nil) {
            self.detailTextLabel.text = nil;
            self.restClient = [DropboxClientsManager authorizedClient];
            [[self.restClient.usersRoutes getCurrentAccount]
                response:^(DBUSERSFullAccount *account, DBNilObject * nilObject, DBError * error) {
                    
                    if (account) {
                        [self restClient:self.restClient loadedAccountInfo:account];
                    } else {
                        
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

- (void)restClient:(DropboxClient *)client loadedAccountInfo:(DBUSERSAccount *)info {
    
    if (client == self.restClient) {
        
        DropboxClient *retainCycle = client;
        
        self.accountInfo = info;
        self.accessoryView = nil;
        self.detailTextLabel.text = info.name.displayName;
        
        self.restClient = nil;
        [self setNeedsLayout];
        
        retainCycle = nil;
    }
    
}

@end
