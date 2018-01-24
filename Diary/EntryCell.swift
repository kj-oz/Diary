//
//  EntryCell.swift
//  Diary
//
//  Created by KO on 2017/12/19.
//  Copyright © 2017年 KO. All rights reserved.
//

import UIKit

class EntryCell: UITableViewCell {
  
  @IBOutlet weak var year: UILabel!
  @IBOutlet weak var date: UILabel!
  @IBOutlet weak var weekday: UILabel!
  @IBOutlet weak var entryText: UILabel!
  @IBOutlet weak var photo: UIImageView!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
}
