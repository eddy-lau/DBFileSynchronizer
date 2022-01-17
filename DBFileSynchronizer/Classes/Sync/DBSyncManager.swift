//
//  DBSyncManager.swift
//  DBFileSynchronizer
//
//  Created by Eddie Hiu-Fung Lau on 14/1/2022.
//

import Foundation
import BackgroundTasks

@objc public class DBSyncManager : NSObject {
    
    static var synchronizers = [DBSynchronizer]()
    
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
    
    @objc public static func sync() {
        synchronizers.forEach { $0.sync() }
    }
    
    @objc public static func sync(id:NSNumber) throws {
        synchronizers[id.intValue].sync()
    }
    
    @objc public static var lastModifiedDate:Date? {
        
        synchronizers
            .map { $0.lastModifiedDate }
            .filter { $0 != nil }
            .map { $0! }
            .sorted { lhs, rhs in
                lhs < rhs
            }.last
    }
    
    @objc public static func add(syncable:DBSyncable) throws -> NSNumber {
        
        guard nil == synchronizers.first(where: {
            $0.syncable?.fileName() == syncable.fileName()
        }) else {
            throw NSError(domain: "DBFileSynchronizer", code: -1,
                          userInfo: [NSLocalizedFailureReasonErrorKey:"Syncable with filename \(syncable.fileName()) already exists."])
        }
        
        let synchronizer = DBSynchronizer()
        synchronizer.syncable = syncable
        synchronizers.append(synchronizer)
        return NSNumber(value:synchronizers.count - 1)
        
    }
    
    @objc public static func markSyncableAsDirty(_ syncable:DBSyncable) {
        
        synchronizers.first {
            $0.syncable?.fileName() == syncable.fileName()
        }?.setHasLocalChange(true)
        
    }
    
    @objc public static func markAsDirty(_ syncableId:NSNumber) {
        synchronizers[syncableId.intValue].setHasLocalChange(true)
    }
    
}

fileprivate extension NSNotification.Name {
    static let didAuth = Notification.Name("DropboxAccountDidAuthNotification")
}

// MARK: Private methods -
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