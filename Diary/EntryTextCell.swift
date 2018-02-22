//
//  EntryTextCell.swift
//  Diary
//
//  Created by KO on 2018/02/20.
//  Copyright © 2018年 KO. All rights reserved.
//

import UIKit

class EntryTextCell: UICollectionViewCell {
  @IBOutlet weak var textView: UITextView!
  
  var isEditable = false {
    didSet {
      textView.isEditable = isEditable
    }
  }
  
}
