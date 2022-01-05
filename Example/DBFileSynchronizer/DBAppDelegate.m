//
//  DBAppDelegate.m
//  DBFileSynchronizer
//
//  Created by Eddie Lau on 06/02/2016.
//  Copyright (c) 2016 Eddie Lau. All rights reserved.
//

#import "DBAppDelegate.h"
#import "DBSyncSettingViewController.h"
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

@implementation DBAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [DBClientsManager setupWithAppKey:@"l269l58a1s4fck5"];

    return YES;
}

- (BOOL) application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {

    NSLog(@"application handle url: %@", url);
    
    return [DBClientsManager handleRedirectURL:url completion:^(DBOAuthResult * _Nullable authResult) {
        
        [DBSyncSettingViewController refreshWithAuthResult:authResult];
            
    }];
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
