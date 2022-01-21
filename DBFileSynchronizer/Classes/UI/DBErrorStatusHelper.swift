//
//  DBSyncSettingViewController.swift
//  DBFileSynchronizer
//
//  Created by Eddie Hiu-Fung Lau on 21/1/2022.
//

import Foundation

public struct DBErrorStatus {
    public let error:NSError
    public let isRead:Bool
    public var warningMessage:String? {
        error.warningMessage()
    }
    
}

extension DBErrorStatusHelper {
    
    private static var errorStatus:DBErrorStatus?
    
    static func getErrorStatus() -> DBErrorStatus? {
        return errorStatus;
    }
        
    @objc static func set(error newError:NSError?, isRead:Bool = false) -> Bool {
        
        var newErrorStatus:DBErrorStatus? = nil;
        if let newError = newError {
            newErrorStatus = DBErrorStatus(error: newError, isRead: isRead)
        }

        var updated = false
        
        if errorStatus != nil && newErrorStatus != nil {
            
            errorStatus = newErrorStatus
            updated = true
            
        } else if errorStatus != nil && newErrorStatus == nil {
            
            if DBClientsManager.authorizedClient() == nil &&
                errorStatus!.error.domain == "DBFileSynchronizer" &&
                errorStatus!.error.code == DBErrorCode.changesNotSyncedError.rawValue {
                
                // Offline and stil have un-synced local changes.
                // Don't overwrite the error.
                
            } else {
                
                errorStatus = newErrorStatus
                updated = true
                
            }
            
        } else if errorStatus == nil && newError != nil {
            updated = true
            errorStatus = newErrorStatus
        }
        
        if updated {
            NotificationCenter.default.post(name: Notification.Name.RefreshMessage, object: nil)
            NotificationCenter.default.post(name: Notification.Name.DBSyncErrorDidUpdate, object: nil)
        }
        
        return updated
    }
    
    @objc static func warningMessage() -> String? {
        return getErrorStatus()?.warningMessage
    }
    
    @objc static func markAsRead() {
        if let errorStatus = errorStatus {
            _ = set(error: errorStatus.error, isRead: true)
        }
    }
    
}
