//
//  PwdViewController.swift
//  Diary
//
//  Created by KO on 2018/03/29.
//  Copyright © 2018年 KO. All rights reserved.
//

import UIKit

class PwdViewController: UIViewController {
  
  @IBOutlet weak var pwdField: UITextField!
  
  @IBOutlet weak var countLabel: UILabel!

  @IBOutlet weak var messageLabel: UILabel!
  
  var pm: PwdManager!
  
  let secPerHour = 60 * 60
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    pm = PwdManager.shared
    update()
    pwdField.delegate = self
  }
  
  private func update() {
    pwdField.text = nil
    messageLabel.text = ""
    countLabel.text = ""
    
    if pm.failureCount > 1 {
      countLabel.text = "連続 \(pm.failureCount) 回失敗"
    } else {
      countLabel.text = "\(pm.failureCount) 回失敗"
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

extension PwdViewController : UITextFieldDelegate {
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
