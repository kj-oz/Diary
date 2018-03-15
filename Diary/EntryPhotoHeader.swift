//
//  EntryPhotoHeader.swift
//  Diary
//
//  Created by KO on 2018/02/17.
//  Copyright © 2018年 KO. All rights reserved.
//

import UIKit

/// コレクションビューの写真ヘッダー部のビュー
class EntryPhotoHeader: UICollectionReusableView {
  /// 親のビューコントローラ
  weak var viewController: EntryViewController!
  
  /// 削除ボタン
  @IBOutlet weak var delButton: UIButton!
  
  // 追加ボタン押下時の処理
  @IBAction func add(_ sender: Any) {
    viewController.addPhoto()
    delButton.isEnabled = false
  }
  
  // 削除ボタン押下時の処理
  @IBAction func del(_ sender: Any) {
    viewController.removePhoto()
    delButton.isEnabled = false
  }
  
  /// 削除ボタンのEnabledを更新する
  func updateDeleteButton() {
    delButton.isEnabled = viewController.isPhotoSelected()
  }
}
