//
//  Task.swift
//  SimpleToDoList
//
//  Created by Ollie on 2016/12/15.
//  Copyright © 2016年 Ollie. All rights reserved.
//

import RealmSwift

class Task: Object {
    dynamic var id = 0
    dynamic var datetime = Date()
    dynamic var taskName = ""
    dynamic var isFinish = false
    dynamic var isUpload = false
    dynamic var isModify = false
    dynamic var isDelete = false
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    func incrementID() -> Int {
        let realm = try! Realm()
        return (realm.objects(Task.self).max(ofProperty: "id") as Int? ?? 0) + 1
    }
}


