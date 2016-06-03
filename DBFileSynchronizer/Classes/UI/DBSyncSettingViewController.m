//
//  BackupSettingViewController.m
//  ChineseDailyBread
//
//  Created by Eddie Hiu-Fung Lau on 9/4/14.
//
//

#import "DBSyncSettingViewController.h"
#import "DropboxSDK.h"
#import "DBAccountInfoCell.h"

#define L(s) ([self localizedText:(s)])

enum {
    SECTION_DROPBOX_ACCOUNT = 0,
    SECTION_COUNT
};

@interface DBSyncSettingViewController ()
<
    UITableViewDataSource,
    UITableViewDelegate,
    UIAlertViewDelegate
>

@property (nonatomic,assign) UITableView *tableView;
@property (nonatomic,retain) UIAlertView *confirmDisconnectAlert;

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
    [super dealloc];
}

- (void)loadView {
    
    CGRect rect = [UIScreen mainScreen].applicationFrame;
    self.tableView = [[[UITableView alloc] initWithFrame:rect style:UITableViewStyleGrouped] autorelease];
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

- (UIView *) tableHeaderView {
    
    NSString *appName = [self.delegate appNameForSyncSettingViewController:self];
    NSString *text = [NSString stringWithFormat:L(@"當你登入了 Dropbox 賬戶後，你的筆記會自動備份到《應用/%@》資料夾。"), appName];
    
    
    UIView *view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 130)] autorelease];
    UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(20, 20, view.bounds.size.width-40, view.bounds.size.height - 40)] autorelease];
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
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormatter setDateStyle:NSDateFormatterShortStyle];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [dateFormatter setDoesRelativeDateFormatting:YES];
    
        NSString *datePart = [dateFormatter stringFromDate:date];
        
        NSString* timePart = [NSDateFormatter localizedStringFromDate: date
                                                            dateStyle: NSDateFormatterNoStyle
                                                            timeStyle: NSDateFormatterShortStyle];
        
        
        UIView *view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 120)] autorelease];
        UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(20, 20, view.bounds.size.width-40, view.bounds.size.height - 40)] autorelease];
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
                cell = [[[DBAccountInfoCell alloc] initWithReuseIdentifier:cellId] autorelease];
            }
            
            [cell reload];
            
            return cell;
            
        } else if (indexPath.row == 1) {
            
            NSString *cellId = @"dbConnectButtonCell";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId] autorelease];
                cell.textLabel.textAlignment = NSTextAlignmentLeft;
                cell.textLabel.textColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0];
            }
            
            if ([DBSession sharedSession].isLinked) {
                
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
        
        UILabel *footerLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 30)] autorelease];
        footerLabel.backgroundColor = [UIColor clearColor];
        footerLabel.textColor = [UIColor grayColor];
        footerLabel.font = [UIFont systemFontOfSize:14.0];
        footerLabel.textAlignment = NSTextAlignmentCenter;
        
        if ([DBSession sharedSession].isLinked) {
            footerLabel.text = L(@"按下登出 Dropbox 賬戶"); //ZHLocalizedString(@"Tap to disconnect this Dropbox account", @"");
        } else {
            footerLabel.text = L(@"按下登入 Dropbox 賬戶"); //ZHLocalizedString(@"Tap to connect a Dropbox account", @"");
        }
        
        return footerLabel;
        
    } else {
        return nil;
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == SECTION_DROPBOX_ACCOUNT) {
        
        if (indexPath.row == 1) {
            
            return indexPath;
            
        } else {
            return nil;
        }
        
    } else {
        
        return nil;
        
    }
    
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == SECTION_DROPBOX_ACCOUNT) {
    
        if (indexPath.row == 1) {
            if (![[DBSession sharedSession] isLinked]) {
                
                [[DBSession sharedSession] linkFromController:self];
                
            } else {
                
                NSString *title = L(@"Disconnect");
                NSString *message = L(@"Are you sure you want to disconnect Dropbox?");
                self.confirmDisconnectAlert = [[[UIAlertView alloc] initWithTitle:title
                                                                         message:message delegate:self
                                                               cancelButtonTitle:L(@"Cancel")
                                                                otherButtonTitles:L(@"Disconnect"), nil] autorelease];
                
                [self.confirmDisconnectAlert show];
                
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                
                
            }
            
        }
        
    }
    
}

#pragma mark UIAlertViewDelegate

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 1) {
        [[DBSession sharedSession] unlinkAll];
        [self.tableView reloadData];
        
        if ([self.delegate respondsToSelector:@selector(syncSettingViewControllerDidLogout:)]) {
            [self.delegate syncSettingViewControllerDidLogout:self];
        }
    }
}

#pragma mark DropboxAccount notification

- (void) dropboxAccountDidLinkNotification:(NSNotification *)notification {
    [self.tableView reloadData];
}

- (void) notesSynchronizerDidDownloadNotesNotification:(NSNotification *)notification {
    [self.tableView reloadData];
}

- (void) notesSynchronizerDidUploadNotesNotification:(NSNotification *)notification {
    [self.tableView reloadData];
}

- (void) notesSynchronizerDidFailNotification:(NSNotification *)notification {
    NSError *error = notification.userInfo[@"error"];
    if ([error.domain isEqualToString:@"dropbox.com"] && error.code == 401) {
        [[DBSession sharedSession] unlinkAll];
    }
}

@end
