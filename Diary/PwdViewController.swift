//
//  PwdViewController.swift
//  Diary
//
//  Created by KO on 2018/03/29.
//  Copyright © 2018年 KO. All rights reserved.
//

import UIKit

/// パスワード要求画面
class PwdViewController: UIViewController {
  
  /// パスワード入力欄
  @IBOutlet weak var pwdField: UITextField!
  
  /// 失敗の回数を表示するラベル
  @IBOutlet weak var countLabel: UILabel!

  /// メッセージを表示するラベル
  @IBOutlet weak var messageLabel: UILabel!
  
  /// パスワードを管理するオブジェクト
  var pm: PwdManager!
  
  /// 1時間あたりの秒数（この値を変更することで、デバッグ時、すぐに確認できる）
  let secPerHour = 60 * 60
  
  // ビューのロード時に呼び出される
  override func viewDidLoad() {
    super.viewDidLoad()
    
    pm = PwdManager.shared
    update()
    pwdField.delegate = self
  }
  
  /// （パスワードの間違いを受けて）画面の状態を更新する
  private func update() {
    pwdField.text = nil
    messageLabel.text = ""
    countLabel.text = ""
    
    if pm.failureCount > 1 {
      countLabel.text = "連続 \(pm.failureCount) 回失敗"
    } else if pm.failureCount == 1 {
      countLabel.text = "1回失敗"
    }
    if pm.failureCount == 3 {
      lock(hours: 1)
    }
    else if pm.failureCount == 6 {
      lock(hours: 24)
    }
    else if pm.failureCount == 9 {
      lock(hours: 48, releaseHours: 1)
    }
    view.setNeedsDisplay()
  }
  
  /// 指定の時間、入力不可にする
  ///
  /// - parameter hours: 入力不可にする時間数
  /// - parameter releaseHours: パスワードを自動解除するまでの時間数
  /// releaseHoursが指定されている場合、メッセージには hours 時間ロックする旨表示するが、実際には
  /// releaseHours後にパスワードを解除しアプリを停止する（次に立ち上げた時にはパスワード無しで起動できる）
  /// パスワード忘れへの対策
  func lock(hours: Int, releaseHours: Int = 0) {
    let unlockTime = Date(timeInterval: TimeInterval(hours * secPerHour),
                          since: pm.lastFailureTime!)
    let now = Date()
    if unlockTime > now {
      let fmt = DateFormatter()
      fmt.dateFormat = "MM/dd HH:mm"
      fmt.locale = Locale.current
      let unlockTimeStr = fmt.string(from: unlockTime)
      messageLabel.text =
          "\(pm.failureCount)回連続で失敗したため、\n\(unlockTimeStr)まで\n使用できません。"
      pwdField.isEnabled = false
      
      if (releaseHours > 0) {
        DispatchQueue.global(qos: .userInteractive).asyncAfter(wallDeadline: .now() + .seconds(releaseHours * secPerHour)) {
          self.pm.password = nil
          self.pm.succeed()
          exit(0)
        }
      } else {
        DispatchQueue.global(qos: .userInteractive).asyncAfter(wallDeadline: .now()
            + .seconds(hours * secPerHour)) {
          DispatchQueue.main.sync {
            self.pwdField.isEnabled = true
            self.messageLabel.text = nil
          }
        }
      }
    }
  }
}

// MARK: UITextFieldDelegate
extension PwdViewController : UITextFieldDelegate {
  // リターンボタンタップ時に呼び出される
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if textField.text == nil || textField.text?.trimmingCharacters(in: .whitespaces) == "" {
      return false
    }
    if textField.text! != pm.password {
      pm.fail()
      update()
      return false
    }
    pm.succeed()
    textField.resignFirstResponder()
    dismiss(animated: true, completion: nil)
    return true
  }
}
