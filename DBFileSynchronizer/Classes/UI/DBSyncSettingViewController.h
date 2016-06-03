//
//  BackupSettingViewController.h
//  ChineseDailyBread
//
//  Created by Eddie Hiu-Fung Lau on 9/4/14.
//
//

#import <UIKit/UIKit.h>

@class DBSyncSettingViewController;
@protocol DBSyncSettingViewControllerDelegate <NSObject>

- (NSDate *) lastSynchronizedTimeForSyncSettingViewController:(DBSyncSettingViewController *)controller;
- (NSString *) appNameForSyncSettingViewController:(DBSyncSettingViewController *)controller;

@optional
- (NSString *) localizedStringForSyncSettingViewController:(DBSyncSettingViewController *)controller ofText:(NSString *)text;
- (void) syncSettingViewControllerDidLogout:(DBSyncSettingViewController *)controller;

@end

@interface DBSyncSettingViewController : UIViewController

@property (nonatomic,readonly) UITableView *tableView;
@property (nonatomic,assign) id<DBSyncSettingViewControllerDelegate>   delegate;

@end