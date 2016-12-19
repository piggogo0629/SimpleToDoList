//
//  TaskListCell.swift
//  SimpleToDoList
//
//  Created by Ollie on 2016/12/16.
//  Copyright © 2016年 Ollie. All rights reserved.
//

import UIKit

class TaskListCell: UITableViewCell {
    
    @IBOutlet weak var taskDateLabel: UILabel!
    @IBOutlet weak var taskNameLabel: UILabel!
    @IBOutlet weak var TaskFinishLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
