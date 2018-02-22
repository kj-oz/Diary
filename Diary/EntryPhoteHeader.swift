//
//  EntryPhoteHeader.swift
//  Diary
//
//  Created by KO on 2018/02/17.
//  Copyright © 2018年 KO. All rights reserved.
//

import UIKit

class EntryPhoteHeader: UICollectionReusableView {
  weak var viewController: EntryViewController!
        
  @IBOutlet weak var delButton: UIButton!
  
  @IBAction func add(_ sender: Any) {
    viewController.addPhoto()
    delButton.isEnabled = false
  }
  
  @IBAction func del(_ sender: Any) {
    viewController.removePhoto()
    delButton.isEnabled = false
  }
  
  func updateDeleteButton() {
    delButton.isEnabled = viewController.isPhotoSelected()
  }
}
