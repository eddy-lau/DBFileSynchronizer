//
//  SyncableText.swift
//  DBFileSynchronizer_Example
//
//  Created by Eddie Hiu-Fung Lau on 5/1/2022.
//  Copyright © 2022 Eddie Lau. All rights reserved.
//

import Foundation

class SyncableText : NSObject, DBSyncable {
    
    var content = ""
    
    func hasData() -> Bool {
        return content.count > 0
    }
    
    func dataRepresentation() -> Data! {
        return content.data(using: .utf8)
    }
    
    func replace(by data: Data!) {
        guard let newText = String(data: data, encoding: .utf8) else {
            return
        }
        content = newText
    }
    
    func merge(with Data: Data!) -> Bool {
        guard let newText = String(data: Data, encoding: .utf8) else {
            return false
        }
        
        content = content + newText
        return true
    }
    
    func fileName() -> String! {
        return "Text.txt"
    }
}
