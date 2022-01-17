//
//  BackupSettingViewController.m
//  ChineseDailyBread
//
//  Created by Eddie Hiu-Fung Lau on 9/4/14.
//
//

#import "DBSyncSettingViewController.h"
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>
#import "DBAccountInfoCell.h"
#import "DBLegacyKeychain.h"

#define L(s) ([self localizedText:(s)])

NSString *DBAccountDidAuthNotification = @"DropboxAccountDidAuthNotification";


enum {
    SECTION_DROPBOX_ACCOUNT = 0,
    SECTION_COUNT
};

@interface DBSyncSettingViewController ()
<
    UITableViewDataSource,
    UITableViewDelegate,
    DBLoadingStatusDelegate
>

@property (nonatomic,assign) UITableView *tableView;
@property (nonatomic,readonly) BOOL isLinked;

@end

@implementation DBSyncSettingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadView {
    
    CGRect rect = [UIScreen mainScreen].bounds;
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:rect style:UITableViewStyleGrouped];
    self.tableView = tableView;
    self.tableView.autoresizingMask |= UIViewAutoresizingFlexibleHeight;
    self.tableView.autoresizingMask |= UIViewAutoresizingFlexibleWidth;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.tableView.tableHeaderView = [self tableHeaderView];
    self.tableView.tableFooterView = [self tableFooterView];
    
    self.view = self.tableView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dropboxAccountDidAuthNotification:)
                                                 name:DBAccountDidAuthNotification
                                               object:nil];
    
    [DBSyncSettingViewController refreshAllAccessTokens:nil];
}

+ (void) refreshNextAccessToken:(NSMutableArray<DBAccessToken *> *)tokens completion:(DBRefreshTokensCompletion)completion {
    
    if (tokens.count == 0) {
        if (completion) {
            completion();
        }
        return;
    }
    
    DBAccessToken *token = [tokens objectAtIndex:0];
    [tokens removeObjectAtIndex:0];
    
    DBOAuthManager *authManager = DBOAuthManager.sharedOAuthManager;
    [authManager refreshAccessToken:token scopes:@[] queue:nil completion:^(DBOAuthResult * _Nullable authResult) {
        if (authResult == nil) {
            [self refreshNextAccessToken:tokens completion:completion];
            return;
        }
        
        if(authResult.isError) {
            
            NSLog(@"Error refreshing Token: %@", authResult.nsError);
            
        } else if (authResult.isSuccess) {

            NSTimeInterval timeInterval = token.tokenExpirationTimestamp;
            NSDate *lastUpdate = [[NSDate alloc] initWithTimeIntervalSince1970:timeInterval];
            NSLog(@"Successfully refreshed Token: %@ -> %@", token.accessToken, lastUpdate);
            
        }

        [self refreshNextAccessToken:tokens completion:completion];
    }];

    
}

+ (void) refreshAllAccessTokens:(DBRefreshTokensCompletion _Nullable)completion {

    DBOAuthManager *authManager = DBOAuthManager.sharedOAuthManager;
    NSDictionary<NSString *, DBAccessToken *> *tokensDict = [authManager retrieveAllAccessTokens];
    
    NSMutableArray<DBAccessToken *> *tokens = [NSMutableArray array];
    
    for (NSString *key in tokensDict) {
        [tokens addObject:tokensDict[key]];
    }
    
    [self refreshNextAccessToken:tokens completion:completion];
    
}

+ (void) fixKeychainBug {
    
    DBUserClient *client = [DBClientsManager authorizedClient];
    if (client == nil) {
        NSArray<NSString *> *allKeys = [DBLegacyKeychain getAll];
        if (allKeys.count > 0) {
            NSLog(@"Found legacy keys in keychain!");
            NSLog(@"This causes the problem that the new keys can't be stored.");
            NSLog(@"Removing the legacy keys now...");
            for (NSString *key in allKeys) {
                [DBLegacyKeychain delete:key];
            }
        }
        return;
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark localization helpers



- (NSString *) localizedText:(NSString *)text {
    
    if ([self.delegate respondsToSelector:@selector(localizedStringForSyncSettingViewController:ofText:)]) {
        return [self.delegate localizedStringForSyncSettingViewController:self ofText:text];
    } else {
        return text;
    }
    
}

#pragma mark private methods

- (BOOL) isLinked {
    return [DBClientsManager authorizedClient] != nil;
}

- (UIView *) tableHeaderView {
    
    NSString *appName = [self.delegate appNameForSyncSettingViewController:self];
    NSString *text = [NSString stringWithFormat:L(@"當你登入了 Dropbox 帳戶後，你的資料會自動備份到《應用/%@》資料夾。"), appName];
    
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 130)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, view.bounds.size.width-40, view.bounds.size.height - 40)];
    label.numberOfLines = 1000;
    label.backgroundColor = [UIColor clearColor];
    label.autoresizingMask |= UIViewAutoresizingFlexibleHeight;
    label.autoresizingMask |= UIViewAutoresizingFlexibleWidth;
    label.text = text;
    
    [view addSubview:label];
    
    return view;
}

- (UIView *) tableFooterView {
    
    NSDate *date = [self.delegate lastSynchronizedTimeForSyncSettingViewController:self];
    
    if (date != nil) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterShortStyle];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [dateFormatter setDoesRelativeDateFormatting:YES];
    
        NSString *datePart = [dateFormatter stringFromDate:date];
        
        NSString* timePart = [NSDateFormatter localizedStringFromDate: date
                                                            dateStyle: NSDateFormatterNoStyle
                                                            timeStyle: NSDateFormatterShortStyle];
        
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 120)];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, view.bounds.size.width-40, view.bounds.size.height - 40)];
        label.font = [UIFont systemFontOfSize:14];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor grayColor];
        label.numberOfLines = 1000;
        label.backgroundColor = [UIColor clearColor];
        label.autoresizingMask |= UIViewAutoresizingFlexibleHeight;
        label.autoresizingMask |= UIViewAutoresizingFlexibleWidth;
        label.text = [NSString stringWithFormat: L(@"上次備份時間: %@, %@"), datePart, timePart];
        [view addSubview:label];
        
        return view;
        
    } else {
        return nil;
    }
    
}

#pragma mark UITableViewDataSource and UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return SECTION_COUNT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == SECTION_DROPBOX_ACCOUNT) {
        return 2;
    } else {
        return 0;
    }
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == SECTION_DROPBOX_ACCOUNT) {
        
        if (indexPath.row == 0) {
            
            NSString *cellId = @"dbAccountInfoCell";
            DBAccountInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
            if (cell == nil) {
                cell = [[DBAccountInfoCell alloc] initWithReuseIdentifier:cellId];
            }
            
            BOOL wasLinked = [self isLinked];
            [cell reloadWithCompletionBlock:^(BOOL linked) {
                if (!wasLinked && linked) {
                    if ([self.delegate respondsToSelector:@selector(syncSettingViewControllerDidLogin:)]) {
                        [self.delegate syncSettingViewControllerDidLogin:self];
                    }
                } else if (wasLinked && !linked) {
                    if ([self.delegate respondsToSelector:@selector(syncSettingViewControllerDidLogout:)]) {
                        [self.delegate syncSettingViewControllerDidLogout:self];
                    }
                }
                [self.tableView reloadData];
            }];
            
            return cell;
            
        } else if (indexPath.row == 1) {
            
            NSString *cellId = @"dbConnectButtonCell";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
                cell.textLabel.textAlignment = NSTextAlignmentLeft;
                cell.textLabel.textColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0];
            }
            
            if (self.isLinked) {
                
                cell.textLabel.text = L(@"登出");
                
            } else {
                
                cell.textLabel.text = L(@"登入");
                
            }
            
            return cell;
            
        } else {
            return nil;
        }
        
    } else {
        return nil;
    }
    
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    if (section == SECTION_DROPBOX_ACCOUNT) {
        return L(@"Dropbox");
    } else {
        return nil;
    }
    
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    
    if (section == SECTION_DROPBOX_ACCOUNT) {
        
        UILabel *footerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 30)];
        footerLabel.backgroundColor = [UIColor clearColor];
        footerLabel.textColor = [UIColor grayColor];
        footerLabel.font = [UIFont systemFontOfSize:14.0];
        footerLabel.textAlignment = NSTextAlignmentCenter;
        
        if (self.isLinked) {
            footerLabel.text = L(@"按下登出 Dropbox 帳戶"); //ZHLocalizedString(@"Tap to disconnect this Dropbox account", @"");
        } else {
            footerLabel.text = L(@"按下登入 Dropbox 帳戶"); //ZHLocalizedString(@"Tap to connect a Dropbox account", @"");
        }
        
        return footerLabel;
        
    } else {
        return nil;
    }
}

static NSInteger clickedCount = 0;

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == SECTION_DROPBOX_ACCOUNT) {
        
        return indexPath;
        
    } else {
        
        return nil;
        
    }
    
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == SECTION_DROPBOX_ACCOUNT) {
        
        if (indexPath.row == 0) {
            
            clickedCount++;
            if (clickedCount > 5) {
                clickedCount = 0;
                
                NSBundle *bundle = [NSBundle bundleForClass:[DBSyncSettingViewController class]];
                NSURL *bundleURL = [bundle URLForResource:@"DBFileSynchronizer" withExtension:@"bundle"];
                NSBundle *resourceBundle = [NSBundle bundleWithURL:bundleURL];
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"DebugViewController" bundle:resourceBundle];
                UIViewController *vc = [storyboard instantiateInitialViewController];
                [self presentViewController:vc animated:YES completion:nil];
                
            }
            
        } else
        if (indexPath.row == 1) {
            if (!self.isLinked) {
                
                // v1
                //[[DBSession sharedSession] linkFromController:self];
                
                // v2
                [DBClientsManager authorizeFromControllerV2:[UIApplication sharedApplication]
                                                 controller:self
                                      loadingStatusDelegate:self
                                                    openURL:^(NSURL * _Nonnull url) {
                    [[UIApplication sharedApplication] openURL:url];
                } scopeRequest:nil];
                
            } else {
                
                NSString *title = L(@"Disconnect");
                NSString *message = L(@"Are you sure you want to disconnect Dropbox?");
                UIAlertController *alert =
                    [UIAlertController alertControllerWithTitle:title message:message
                                                 preferredStyle:UIAlertControllerStyleAlert];
                
                [alert addAction:
                    [UIAlertAction actionWithTitle:L(@"Cancel") style:UIAlertActionStyleCancel handler:nil]
                ];
                
                [alert addAction:
                    [UIAlertAction actionWithTitle:L(@"Disconnect") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        
                        [DBClientsManager unlinkAndResetClients];
                        [self.tableView reloadData];
                        
                        if ([self.delegate respondsToSelector:@selector(syncSettingViewControllerDidLogout:)]) {
                            [self.delegate syncSettingViewControllerDidLogout:self];
                        }
                        
                    }]
                ];
                
                [self presentViewController:alert animated:YES completion:nil];
                
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                
                
            }
            
        }
        
    }
    
}

#pragma mark DropboxAccount notification

+ (void) refreshWithAuthResult:(DBOAuthResult *)authResult {
    
    if (authResult == nil) {
        return;
    }
    
    NSDictionary *userInfo = @{@"authResult":authResult};
    [[NSNotificationCenter defaultCenter] postNotificationName:DBAccountDidAuthNotification object:nil userInfo:userInfo];

}

- (void) dropboxAccountDidAuthNotification:(NSNotification *)notification {
    
    DBOAuthResult *authResult = notification.userInfo[@"authResult"];
    [self.tableView reloadData];
    
    if ([authResult isSuccess]) {
        
        if ([self.delegate respondsToSelector:@selector(syncSettingViewControllerDidLogin:)]) {
            [self.delegate syncSettingViewControllerDidLogin:self];
        }

    } else if ([authResult isCancel]) {
        
        NSLog(@"Authorization flow was manually canceled by user!");
        
    } else if ([authResult isError]) {
        
        NSLog(@"Error: %@", authResult.nsError);
        
    }
    
}

- (void)dismissLoading {
    
}

- (void)showLoading {
    
}

@end
