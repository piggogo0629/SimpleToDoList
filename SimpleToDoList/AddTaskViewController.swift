//
//  AddTaskViewController.swift
//  SimpleToDoList
//
//  Created by Ollie on 2016/12/15.
//  Copyright © 2016年 Ollie. All rights reserved.
//

import UIKit
import RealmSwift
import ReachabilitySwift
import Alamofire

class AddTaskViewController: UIViewController {
    //MARK:Variable
    let reachibility = Reachability(hostname: "www.apple.com")
    
    //MARK:- @IBOutlet
    @IBOutlet weak var myDatePicker: UIDatePicker!
    @IBOutlet weak var myTextField: UITextField!
    @IBOutlet weak var mySegment: UISegmentedControl!
    
    //MARK:- @IBAction
    @IBAction func addNewTask(_ sender: Any) {
        let taskName = myTextField.text!
        let taskDate = myDatePicker.date
        let isFinish = (mySegment.selectedSegmentIndex == 0) ? false : true
        
        if taskName == "" {
            let alertController = UIAlertController(title: "Alert", message: "Please type task name", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
            
            return
        }
        
        let newTask = Task()
        
        let frontViewController = self.navigationController?.childViewControllers[0] as! TaskListViewController
        
        // 有networking
        if (reachibility?.isReachable)! {

            newTask.id = newTask.incrementID()
            newTask.datetime = taskDate
            newTask.taskName = taskName
            newTask.isFinish = isFinish
            
            // 新增資料到local DB
            do {
                try uiRealm.write {
                    uiRealm.add(newTask)
                }
            } catch let error as NSError {
                print("===\(error.localizedDescription)")
            }
            
            // 再將新增完的資料upload到server
            frontViewController.syncToServer(by: "post", sync: nil, sync: newTask)
        } else {
            
            newTask.id = newTask.incrementID()
            newTask.datetime = taskDate
            newTask.taskName = taskName
            newTask.isFinish = isFinish
            
            do {
                try uiRealm.write {
                    uiRealm.add(newTask)
                }
            } catch let error as NSError{
                print("===\(error.localizedDescription)")
            }
            
            frontViewController.readTasksAndUpdateUI()
        }
        
        let _ = self.navigationController?.popToViewController(frontViewController, animated: true)
    }
    
    //MARK:- ViewController Func
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mySegment.setTitle("False", forSegmentAt: 0)
        mySegment.setTitle("True", forSegmentAt: 1)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
