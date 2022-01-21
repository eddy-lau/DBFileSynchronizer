//
//  BackupSettingViewController.h
//  ChineseDailyBread
//
//  Created by Eddie Hiu-Fung Lau on 9/4/14.
//
//

#import <UIKit/UIKit.h>
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>
#import "DBError.h"

@class DBSyncSettingViewController;
@protocol DBSyncSettingViewControllerDelegate <NSObject>

- (NSDate * _Nullable) lastSynchronizedTimeForSyncSettingViewController:(DBSyncSettingViewController * _Nonnull)controller;
- (NSString * _Nonnull) appNameForSyncSettingViewController:(DBSyncSettingViewController * _Nonnull)controller;

@optional
- (NSString * _Nonnull) localizedStringForSyncSettingViewController:(DBSyncSettingViewController * _Nonnull)controller ofText:(NSString * _Nonnull)text;
- (void) syncSettingViewControllerDidLogin:(DBSyncSettingViewController * _Nonnull)controller;
- (void) syncSettingViewControllerDidLogout:(DBSyncSettingViewController * _Nonnull)controller;

@end


typedef void (^DBRefreshTokensCompletion)(void);

@interface DBSyncSettingViewController : UIViewController

@property (nonatomic,readonly) UITableView * _Nullable tableView;
@property (nonatomic,assign) id<DBSyncSettingViewControllerDelegate> _Nullable delegate;

+ (void) refreshWithAuthResult:(DBOAuthResult * _Nullable)authResult;
+ (void) refreshAllAccessTokens:(DBRefreshTokensCompletion _Nullable)completion;
+ (void) fixKeychainBug;

@end
