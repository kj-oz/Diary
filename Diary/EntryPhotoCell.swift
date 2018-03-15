//
//  EntryPhotoCell.swift
//  Diary
//
//  Created by KO on 2018/02/17.
//  Copyright © 2018年 KO. All rights reserved.
//

import UIKit

/// コレクションビューの写真セル
class EntryPhotoCell: UICollectionViewCell {
  
  /// イメージビュー
  @IBOutlet weak var imageView: UIImageView!
  
  //　選択されているか（選択時ボーダーを幅10で描画）
  override var isSelected: Bool {
    didSet {
      imageView.layer.borderWidth = isSelected ? 10 : 0
    }
  }
  
  // ビューの生成時に呼び出される
  override func awakeFromNib() {
    super.awakeFromNib()
    imageView.layer.borderColor = UIColor.red.cgColor
    isSelected = false
  }
}
