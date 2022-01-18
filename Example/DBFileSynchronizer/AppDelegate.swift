//
//  AppDelegate.swift
//  DBFileSynchronizer_Example
//
//  Created by Eddie Hiu-Fung Lau on 14/1/2022.
//  Copyright © 2022 Eddie Lau. All rights reserved.
//

import Foundation
import UIKit
import ObjectiveDropboxOfficial
import DBFileSynchronizer

@objc public class AppDelegate : UIResponder, UIApplicationDelegate {
    
    public var window: UIWindow?
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        DBClientsManager.setup(withAppKey: "l269l58a1s4fck5")
        DBSyncManager.setup()
        return true
    }
    
    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        NSLog("application handle url: \(url)")
        return DBClientsManager.handleRedirectURL(url) {
            DBSyncManager.update(authResult: $0)
        }
    }
    
    public func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        DBSyncManager.performFetch(completionHandler: completionHandler)
    }
    
    public func applicationDidBecomeActive(_ application: UIApplication) {
        DBSyncManager.sync()
        DBSyncManager.performFetch()
    }
    
    public func applicationDidEnterBackground(_ application: UIApplication) {
        if #available(iOS 13.0, *) {
            DBSyncManager.scheduleAppRefresh()
        }
    }
    
}
