//
//  BackupSettingViewController.h
//  ChineseDailyBread
//
//  Created by Eddie Hiu-Fung Lau on 9/4/14.
//
//

#import <UIKit/UIKit.h>
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

@class DBSyncSettingViewController;
@protocol DBSyncSettingViewControllerDelegate <NSObject>

- (NSDate *) lastSynchronizedTimeForSyncSettingViewController:(DBSyncSettingViewController *)controller;
- (NSString *) appNameForSyncSettingViewController:(DBSyncSettingViewController *)controller;

@optional
- (NSString *) localizedStringForSyncSettingViewController:(DBSyncSettingViewController *)controller ofText:(NSString *)text;
- (void) syncSettingViewControllerDidLogin:(DBSyncSettingViewController *)controller;
- (void) syncSettingViewControllerDidLogout:(DBSyncSettingViewController *)controller;

@end

@interface DBSyncSettingViewController : UIViewController

@property (nonatomic,readonly) UITableView *tableView;
@property (nonatomic,assign) id<DBSyncSettingViewControllerDelegate>   delegate;

+ (void) refreshWithAuthResult:(DBOAuthResult *)authResult;

@end
