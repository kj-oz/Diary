//
//  EntryTextCell.swift
//  Diary
//
//  Created by KO on 2018/02/20.
//  Copyright © 2018年 KO. All rights reserved.
//

import UIKit

/// コレクションビューのテキストセル
class EntryTextCell: UICollectionViewCell {
  
  /// テキストビュー
  @IBOutlet weak var textView: UITextView!
  
  /// テキストが編集可能かどうか
  var isEditable = false {
    didSet {
      textView.isEditable = isEditable
    }
  }
}
