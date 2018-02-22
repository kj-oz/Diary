//
//  EntryPhotoCell.swift
//  Diary
//
//  Created by KO on 2018/02/17.
//  Copyright © 2018年 KO. All rights reserved.
//

import UIKit

class EntryPhotoCell: UICollectionViewCell {
    
  @IBOutlet weak var imageView: UIImageView!
  
  override var isSelected: Bool {
    didSet {
      imageView.layer.borderWidth = isSelected ? 10 : 0
    }
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    imageView.layer.borderColor = UIColor.red.cgColor
    isSelected = false
  }
}
