//
//  SettingViewController.swift
//  Diary
//
//  Created by KO on 2018/04/07.
//  Copyright © 2018年 KO. All rights reserved.
//

import UIKit

/// 設定画面
class SettingViewController: UITableViewController {
  
  /// パスワード入力欄
  @IBOutlet weak var pwdField: UITextField!
  
  /// 確認入力欄
  @IBOutlet weak var confirmField: UITextField!
  
  /// パスワード・マネジャ
  let pm = PwdManager.shared
  
  /// 何らかの入力を行って未確定の状態かどうか
  var dirty = false
  
  // ビューのロード時に呼び出される
  override func viewDidLoad() {
    super.viewDidLoad()
    pwdField.text = pm.password ?? ""
    confirmField.text = ""
    
    pwdField.delegate = self
    confirmField.delegate = self
  }
  
  // セクション数
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  // 行数
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 2
  }
  
  /// 戻るボタン押下時の処理
  @IBAction func backButtonTapped(_ sender: Any) {
    if dirty {
      confirm(viewController: self, message: "パスワードは変更されていませんが、画面を閉じてよろしいですか？") { isOK in
        if isOK {
          self.performSegue(withIdentifier: "HideSettings", sender: self)
        }
      }
    } else {
      performSegue(withIdentifier: "HideSettings", sender: self)
    }
  }
}

// MARK: UITextFieldDelegate
extension SettingViewController : UITextFieldDelegate {
  // リターンキーがタップされた
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    dirty = true
    if textField === pwdField {
      print("パスワード欄：\(pwdField.text ?? "")")
      confirmField.text = ""
    } else {
      print("確認欄：\(confirmField.text ?? "")")
      if confirmField.text != pwdField.text {
        alert(viewController: self, message: "パスワードが一致しません。")
      } else {
        alert(viewController: self, message: "パスワードが変更されました。")
        pm.password = pwdField.text
        dirty = false
      }
    }
    return true
  }
}
