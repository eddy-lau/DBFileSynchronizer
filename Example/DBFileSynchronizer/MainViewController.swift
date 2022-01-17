//
//  MainViewController.swift
//  DBFileSynchronizer_Example
//
//  Created by Eddie Hiu-Fung Lau on 4/1/2022.
//  Copyright © 2022 Eddie Lau. All rights reserved.
//

import Foundation
import UIKit
import ObjectiveDropboxOfficial
import DBFileSynchronizer

class MainViewController : UIViewController {
    
    @IBOutlet weak var textView:UITextView!
    @IBOutlet weak var syncButton:UIBarButtonItem!

    let syncable = SyncableText()
    
    var isLinked:Bool {
        DBClientsManager.authorizedClient() != nil
    }
    
    override func viewDidLoad() {
        
        _ = try! DBSyncManager.add(syncable: syncable)
        DBSyncManager.sync()
        
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(didDownloadSyncableNotification),
                         name: NSNotification.Name.DBSyncableDidDownload,
                         object: nil)
        
        syncButton.isEnabled = isLinked
        
    }
    
}

extension MainViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        syncable.content = textView.text
        DBSyncManager.markSyncableAsDirty(syncable)
    }
    
    @objc func didDownloadSyncableNotification() {
        textView.text = syncable.content
    }
    
}

extension MainViewController {
    
    @IBAction func didTapSetting() {
        
        let vc = DBSyncSettingViewController()
        vc.delegate = self
        vc.title = "Settings"
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(didTapClose))
        let navController = UINavigationController(rootViewController: vc)
        present(navController, animated: true, completion: nil)
        
    }
    
    @IBAction func didTapSync() {
        DBSyncManager.sync()
    }
    
    @objc func didTapClose() {
        dismiss(animated: true, completion: nil)
    }
    
}

extension MainViewController : DBSyncSettingViewControllerDelegate {
    
    func lastSynchronizedTime(for controller: DBSyncSettingViewController) -> Date? {
        return DBSyncManager.lastModifiedDate
    }
    
    func appName(for controller: DBSyncSettingViewController) -> String {
        return "DBFileSynchronizer"
    }
    
    func syncSettingViewControllerDidLogin(_ controller: DBSyncSettingViewController) {
        syncButton.isEnabled = isLinked
        DBSyncManager.sync()
    }
    
    func syncSettingViewControllerDidLogout(_ controller: DBSyncSettingViewController) {
        syncButton.isEnabled = isLinked
    }
    
}
