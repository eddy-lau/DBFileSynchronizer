//
//  DBSyncManager.swift
//  DBFileSynchronizer
//
//  Created by Eddie Hiu-Fung Lau on 14/1/2022.
//

import Foundation
import BackgroundTasks

public class DBSyncManager {
    
    static var lastRefreshTime:Date? {
        get {
            UserDefaults.standard.lastRefreshTime
        }
        set {
            UserDefaults.standard.lastRefreshTime = newValue
        }
    }
    
    @objc public static func setup() {
        fixKeychainBug()
        setupBackgroundTask()
    }
    
    @objc public static func update(authResult:DBOAuthResult?) {
        
        guard let authResult = authResult else {
            return
        }
        
        let userInfo = ["authResult":authResult]
        NotificationCenter.default.post(name: .didAuth, object: nil, userInfo: userInfo)
        
    }
    
}

extension NSNotification.Name {
    static let didAuth = Notification.Name("DropboxAccountDidAuthNotification")
}

// MARK: -
extension DBSyncManager {
    
    static func fixKeychainBug() {
        guard DBClientsManager.authorizedClient() == nil else {
            return
        }
        
        guard let allKeys = DBLegacyKeychain.getAll(), allKeys.count > 0 else {
            return
        }
        
        NSLog("Found legacy keys in keychain!")
        NSLog("This causes the problem that the new keys can't be stored.")
        NSLog("Removing the legacy keys now...")
        
        for key in allKeys {
            DBLegacyKeychain.delete(key)
        }

    }
}

// MARK: - Background App Refresh
extension DBSyncManager {
    
    static func setupBackgroundTask() {
        
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        
        if #available(iOS 13, *) {
            BGTaskScheduler.shared.register(forTaskWithIdentifier: .dropboxTokenRefreshTask, using: nil) {
                task in
                
                self.performFetch { _ in
                    task.setTaskCompleted(success: true)
                    self.scheduleAppRefresh()
                }
            }
        }
            
    }
    
    @objc public static func performFetch(completionHandler: ((UIBackgroundFetchResult) -> Void)? = nil) {
        
        // iOS 12
        DBSyncSettingViewController.refreshAllAccessTokens {
            lastRefreshTime = Date()
            completionHandler?(.newData)
        }
        
    }
    
    @available(iOS 13.0, *)
    static var appRefreshTaskRequest:BGTaskRequest {
        BGAppRefreshTaskRequest(identifier: .dropboxTokenRefreshTask)
    }
    
    @available(iOS 13.0, *)
    static var processingTaskRequest:BGTaskRequest {
        let request = BGProcessingTaskRequest(identifier: .dropboxTokenRefreshTask)
        request.requiresNetworkConnectivity = true
        return request
    }

    @available(iOS 13.0, *)
    @objc public static func scheduleAppRefresh(timeInterval:TimeInterval = 60 * 60) {
   
        let request = appRefreshTaskRequest
        request.earliestBeginDate = Date(timeIntervalSinceNow: timeInterval)
        
        do {
            try BGTaskScheduler.shared.submit(request)

            /// Set a breakpoint here and in Xcode console,
            /// to simulate app refresh in iOS 13.
            /// key in this commmand:
            /// (lldb) e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"DBFileSynchronizerTokenRefreshTaskId"];
            NSLog("scheduled app refresh task")
            
            
        } catch {
            NSLog("Could not schedule app refresh task \(error.localizedDescription)")
        }
    }
}

// MARK: - Extensions
extension String {
    static let dropboxTokenRefreshTask = "DBFileSynchronizerTokenRefreshTaskId"
    static let lastRefreshTimeKey = "DBFileSynchronizer.lastRefreshTimeDefaultsKey"
}

extension UserDefaults {
    
    var lastRefreshTime:Date? {
        get {
            value(forKey: .lastRefreshTimeKey) as? Date
        }
        set {
            set(newValue, forKey: .lastRefreshTimeKey)
            synchronize()
        }
    }
}
