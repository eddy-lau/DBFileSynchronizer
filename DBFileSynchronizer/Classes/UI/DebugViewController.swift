//
//  DebugViewController.swift
//  DBFileSynchronizer
//
//  Created by Eddie Hiu-Fung Lau on 15/1/2022.
//

import Foundation
import ObjectiveDropboxOfficial

class DebugViewController : UITableViewController {
    
    @IBOutlet weak var tokenLabel:UILabel!
    @IBOutlet weak var expiryTimeLabel:UILabel!
    @IBOutlet weak var appRefreshStateLabel:UILabel!
    @IBOutlet weak var lastRefreshTimeLabel:UILabel!
    
    var accessToken:DBAccessToken? {
        guard let oauthManager = DBOAuthManager.shared() else {
            return nil
        }
        return oauthManager.retrieveFirstAccessToken()
    }
    
    var tokenExpiryTime:String? {
        guard let token = accessToken else {
            return nil
        }
        let date = Date(timeIntervalSince1970: token.tokenExpirationTimestamp)
        return date.formattedString
    }
    
    var appRefreshEnabled:String {
        switch UIApplication.shared.backgroundRefreshStatus {
        case .available: return "YES"
        case .denied: return "NO"
        case .restricted: return "Restricted"
        @unknown default: return "Unknown"
        }
    }
    
    override func viewDidLoad() {
        tokenLabel.text = accessToken?.accessToken
        expiryTimeLabel.text = tokenExpiryTime
        appRefreshStateLabel.text = appRefreshEnabled
        lastRefreshTimeLabel.text = DBSyncManager.lastRefreshTime?.formattedString
    }
    
    @IBAction func didTapDone() {
        navigationController?.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
}

extension Date {
    
    var formattedString:String {
        let RFC3339DateFormatter = DateFormatter()
        RFC3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
        RFC3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return RFC3339DateFormatter.string(from: self)
    }
    
}
