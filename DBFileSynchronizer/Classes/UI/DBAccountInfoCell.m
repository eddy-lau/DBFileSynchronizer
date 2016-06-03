//
//  DBAccountInfoCell.m
//  ChineseDailyBread
//
//  Created by Eddie Hiu-Fung Lau on 9/4/14.
//
//

#import "DBAccountInfoCell.h"
#import "DropboxSDK.h"

@interface DBAccountInfoCell ()
<
    DBRestClientDelegate
>

@property (nonatomic,retain) DBRestClient *restClient;
@property (nonatomic,retain) DBAccountInfo *accountInfo;

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

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) reload {
    
    if ([DBSession sharedSession].isLinked) {

        if (self.accountInfo == nil) {
            self.detailTextLabel.text = nil;
            self.restClient = [[[DBRestClient alloc] initWithSession:[DBSession sharedSession]] autorelease];
            self.restClient.delegate = self;
            [self.restClient loadAccountInfo];
            
            UIActivityIndicatorView *activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
            [activityIndicator startAnimating];
            activityIndicator.hidden = NO;
            
            self.accessoryView = activityIndicator;
            
            
        } else {
            self.detailTextLabel.text = self.accountInfo.displayName;
        }
        
    } else {
        
        self.detailTextLabel.text = @"已登出"; //ZHLocalizedString(@"Unlinked", @"");
        
    }
    
}

- (void)restClient:(DBRestClient *)client loadedAccountInfo:(DBAccountInfo *)info {
    
    if (client == self.restClient) {
        
        [[client retain] autorelease];
        
        self.accountInfo = info;
        self.accessoryView = nil;
        self.detailTextLabel.text = info.displayName;
        
        self.restClient = nil;
        [self setNeedsLayout];
    }
    
}

@end
