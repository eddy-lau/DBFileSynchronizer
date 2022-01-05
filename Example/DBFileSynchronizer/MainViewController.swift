//
//  MainViewController.swift
//  DBFileSynchronizer_Example
//
//  Created by Eddie Hiu-Fung Lau on 4/1/2022.
//  Copyright © 2022 Eddie Lau. All rights reserved.
//

import Foundation
import UIKit

class MainViewController : UIViewController {
    
    @IBOutlet weak var textView:UITextView!
    @IBOutlet weak var syncButton:UIBarButtonItem!
    
    let synchronizer = DBSynchronizer(syncable: SyncableText())
    var syncable:SyncableText {
        synchronizer.syncable as! SyncableText
    }
    
    var isLinked:Bool {
        DBClientsManager.authorizedClient() != nil
    }
    
    override func viewDidLoad() {
        synchronizer.sync()
        
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(didDownloadSyncableNotification),
                         name: NSNotification.Name.DBSynchronizerDidDownloadSyncable,
                         object: nil)
        
        syncButton.isEnabled = isLinked
        
    }
    
}

extension MainViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        syncable.content = textView.text
        synchronizer.setHasLocalChange(true)
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
        synchronizer.sync()
    }
    
    @objc func didTapClose() {
        dismiss(animated: true, completion: nil)
    }
    
}

extension MainViewController : DBSyncSettingViewControllerDelegate {
    
    func lastSynchronizedTime(for controller: DBSyncSettingViewController) -> Date? {
        return synchronizer.lastModifiedDate
    }
    
    func appName(for controller: DBSyncSettingViewController) -> String {
        return "DBFileSynchronizer"
    }
    
    func syncSettingViewControllerDidLogin(_ controller: DBSyncSettingViewController) {
        syncButton.isEnabled = isLinked
        synchronizer.sync()
    }
    
    func syncSettingViewControllerDidLogout(_ controller: DBSyncSettingViewController) {
        syncButton.isEnabled = isLinked
    }
    
}
