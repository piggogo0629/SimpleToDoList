//
//  ViewController.swift
//  SimpleToDoList
//
//  Created by Ollie on 2016/12/15.
//  Copyright © 2016年 Ollie. All rights reserved.
//

import UIKit
import RealmSwift
import ReachabilitySwift
import Alamofire
import SwiftyJSON

class TaskListViewController: UIViewController {
    //MARK:- Variable
    var tasks: Results<Task>!
    let reachibility = Reachability(hostname: "www.apple.com")
    let sheetsuUrlString = "https://sheetsu.com/apis/v1.0/6f371b3ddbc5"
    
    //MARK:- @IBOutlet
    @IBOutlet weak var taskListTableView: UITableView!
    
    //MARK:- ViewController Func
    deinit {
        reachibility?.stopNotifier()
        NotificationCenter.default.removeObserver(self, name: ReachabilityChangedNotification, object: reachibility)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        taskListTableView.delegate = self
        taskListTableView.dataSource = self
        
        //print("Path to realm file: " + (Realm.Configuration.defaultConfiguration.fileURL?.absoluteString)!)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.reachabilityChanged(noti:)), name: ReachabilityChangedNotification, object: reachibility)
        
        do {
            try reachibility?.startNotifier()
        } catch let error as NSError {
            print("===\(error.localizedDescription)")
        }

        if (reachibility?.isReachable)! {
            // 下載server資料更新到local DB
            syncToServer(by: "get", sync: nil, sync: nil)
        } else {
            readTasksAndUpdateUI()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    //MARK:- User method
    func readTasksAndUpdateUI() {
        let originalTasks = uiRealm.objects(Task.self)
        
        tasks = uiRealm.objects(Task.self).filter("isDelete = false AND isUpload IN {true,false}")
        taskListTableView.reloadData()
        
        print("===original:\(originalTasks)")
    }
    
    func reachabilityChanged(noti: NSNotification) {
        let reachibility = noti.object as! Reachability
        if reachibility.isReachable {
            // 有網路連接
            print("Network Reachable")
            
            DispatchQueue.main.async {
                // get
                self.syncToServer(by: "get", sync: nil)
                // post
                let uploadTasks = uiRealm.objects(Task.self).filter("isDelete = false AND isUpload = false")
                if self.tasks != nil && uploadTasks.count > 0 {
                    self.syncToServer(by: "post", sync: uploadTasks)
                }
                // delete
                let deleteTasks = uiRealm.objects(Task.self).filter("isDelete = true AND isUpload = true")
                if self.tasks != nil && deleteTasks.count > 0 {
                    print("deleteTasks:\(deleteTasks)")
                    
                    self.syncToServer(by: "delete", sync: deleteTasks)
                }
            }
        } else {
            print("Network not Reachable")
        }
    }
    
    func syncToServer(by httpMethod: String, sync multiData: Results<Task>? = nil, sync oneData: Task? = nil) {
        switch httpMethod {
        case "get":
            
            let getRequest = request(sheetsuUrlString, method: .get, parameters: nil, encoding: URLEncoding.default)
            getRequest.responseJSON(completionHandler: { (response: DataResponse<Any>) in
                switch response.result {
                case .success(let value):
                    let data = JSON(value)
                    let taskArray = data.arrayValue
                    
                    
                    DispatchQueue.main.async {
                        // 更新 local DB 資料
                        do {
                            try uiRealm.write {
                                for item in taskArray {
                                    let downloadTask = Task()
                                    
                                    let id = item["id"].intValue
                                    let taskName = item["task"].stringValue
                                    let datetime = item["datetime"].stringValue
                                    let isFinish = item["isFinish"].boolValue
                                    
                                    let dateFormatter = DateFormatter()
                                    dateFormatter.dateFormat = "yyyy-MM-dd"
                                    let taskDate = dateFormatter.date(from: datetime)
                                    
                                    if let dateValue = taskDate {
                                        // 確認server端拿回的資料有值
                                        downloadTask.id = id
                                        downloadTask.taskName = taskName
                                        downloadTask.datetime = dateValue
                                        downloadTask.isFinish = isFinish
                                        downloadTask.isUpload = true
                                        
                                        uiRealm.add(downloadTask, update: true)
//                                        uiRealm.create(Task.self, value: ["id": id,
//                                                                          "taskName": taskName,
//                                                                          "datetime": dateValue,
//                                                                          "isFinish": isFinish,
//                                                                          "isDelete": false,
//                                                                          "isModify": false,
//                                                                          "isUpload": true], update: true)
                                    }
                                }
                            }
                        } catch let error as NSError {
                            print("===\(error.localizedDescription)")
                        }
                        
                        self.readTasksAndUpdateUI()
                    }
                case.failure(let error):
                    print("===\(error.localizedDescription)")
                }

            })
        case "post":
            var postArray = [Dictionary<String, Any>]()
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            var dateString: String!
            var dic: [String: Any]!
            
            if oneData != nil {
                // 單筆資料：為local DB新增後upload
                dateString = dateFormatter.string(from: oneData!.datetime)
                dic = ["id":oneData!.id, "datetime":dateString, "task":oneData!.taskName, "isFinish": String(oneData!.isFinish)]
                postArray.append(dic)
            } else if multiData != nil {
                // networking狀態改變時做upload
                for task in multiData! {
                    dateString = dateFormatter.string(from: task.datetime)
                    dic = ["id":task.id, "datetime":dateString, "task":task.taskName, "isFinish": String(task.isFinish)]
                    postArray.append(dic)
                }
            }
            
            let paras: Parameters = ["rows": postArray]
            
            let postRequest = request(sheetsuUrlString, method: .post, parameters: paras, encoding: URLEncoding.default)
            postRequest.responseJSON(completionHandler: { (response: DataResponse<Any>) in
                switch response.result {
                case .success:
                    DispatchQueue.main.async {
                        // 更新 local DB 欄位
                        do {
                            try uiRealm.write {
                                if oneData != nil {
                                    uiRealm.create(Task.self, value: ["id": oneData!.id, "isUpload": true], update: true)
                                } else if multiData != nil {
                                    for task in multiData! {
                                        // Updating Task with primary key : id
                                        // the Task's other property will remain unchanged.
                                        uiRealm.create(Task.self, value: ["id": task.id, "isUpload": true], update: true)
                                    }
                                }
                            }
                        } catch let error as NSError {
                            print("===\(error.localizedDescription)")
                        }
                    }
                case.failure(let error):
                    print("===\(error.localizedDescription)")
                }
            })
        case "delete":
            var deleteUrlString: String!
            var deleteRequest: DataRequest!
            
            if oneData != nil {
                // 單筆資料：為local DB更新刪除記號後後delete
                deleteUrlString = sheetsuUrlString + "/id/\(oneData!.id)"
                
                deleteRequest = request(deleteUrlString, method: .delete, parameters: nil, encoding: URLEncoding.default)
                deleteRequest.responseJSON(completionHandler: { (response: DataResponse<Any>) in
                    switch response.result {
                    case .success(_):
                        return
                    case .failure(let error):
                        print("===\(error.localizedDescription)")
                    }
                })
            } else if multiData != nil {
                // networking狀態改變時做delete
                for task in multiData! {
                    deleteUrlString = sheetsuUrlString + "/id/\(task.id)"
                    
                    deleteRequest = request(deleteUrlString, method: .delete, parameters: nil, encoding: URLEncoding.default)
                    deleteRequest.responseJSON(completionHandler: { (response: DataResponse<Any>) in
                        switch response.result {
                        case .success(_):
                             return
                        case .failure(let error):
                            print("===\(error.localizedDescription)")
                        }
                    })
                }
            }
            default:
            break
        }
    }
}

//MARK:- UITableViewDataSource, UITableViewDelegate
extension TaskListViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tasks == nil {
            return 0
        } else {
            return tasks.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskListCell", for: indexPath) as! TaskListCell
        
        let task = tasks[indexPath.row]
        //自訂時間格式
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: task.datetime)
        
        let finishString = String(task.isFinish)
        
        cell.taskDateLabel.text = "DateTime : " + dateString
        cell.taskNameLabel.text = "TaskName : " + task.taskName
        cell.TaskFinishLabel.text = "Finished : " + finishString
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete") { (action: UITableViewRowAction, indexPath: IndexPath) in
            
            let selectedTask = self.tasks[indexPath.row]
            
            do {
                try uiRealm.write {
                    // 說明：delete動作 -> local DB 上刪除記號，無真正刪除資料，確保id不會錯亂
                    // Updating Task with primary key : id
                    // the Task's other property will remain unchanged.
                    uiRealm.create(Task.self, value: ["id": selectedTask.id, "isDelete": true], update: true)
                    
                    // 有networking
                    if (self.reachibility?.isReachable)! {
                        print("selectedTaskToDelete:\(selectedTask)")
                        self.syncToServer(by: "delete", sync: nil, sync: selectedTask)
                    }
                    
                    // 更新 TableView UI
                    self.readTasksAndUpdateUI()
                }
            } catch let error as NSError{
                print("===\(error.localizedDescription)")
            }
        }
        
        return [deleteAction]
    }
}

