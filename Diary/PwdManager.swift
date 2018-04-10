//
//  PwdManager.swift
//  Diary
//
//  Created by KO on 2018/03/29.
//  Copyright © 2018年 KO. All rights reserved.
//

import Foundation
import UIKit

/// パスワードを管理するシングルトン・クラス
class PwdManager {
  /// 唯一のインスタンス
  static var shared = PwdManager()
  
  /// パスワード
  var password: String? {
    didSet {
      UserDefaults.standard.setValue(password, forKey: "pwd")
    }
  }
  
  /// 連続して失敗した回数
  var failureCount = 0
  
  /// 最後に失敗した日時
  var lastFailureTime: Date?
  
  /// 初期化
  private init() {
    password = UserDefaults.standard.string(forKey: "pwd")
    failureCount = UserDefaults.standard.integer(forKey: "pwdFailCount")
    lastFailureTime = UserDefaults.standard.object(forKey: "pwdLastFailureTime") as? Date
  }
  
  /// パスワードが間違っていた場合の処理を行う
  func fail() {
    failureCount += 1
    lastFailureTime = Date()
    UserDefaults.standard.setValue(failureCount, forKey: "pwdFailCount")
    UserDefaults.standard.setValue(lastFailureTime, forKey: "pwdLastFailureTime")
  }
  
  /// パスワードが正しかった場合の処理を行う
  func succeed() {
    failureCount = 0
    lastFailureTime = nil
    UserDefaults.standard.setValue(failureCount, forKey: "pwdFailCount")
    UserDefaults.standard.setValue(lastFailureTime, forKey: "pwdLastFailureTime")
  }
  
  /// パスワード入力画面を表示する
  ///
  /// - parameter parent: 親のビューコントローラ
  /// - parameter completion: パスワード入力終了後の処理
  func showDialog(_ parent: UIViewController, completion: (()->Void)?) {
    if let password = password, password.count > 0 {
      let sb = UIStoryboard(name: "Main", bundle: nil)
      let pwdVC = sb.instantiateViewController(withIdentifier: "PasswordVC") as! PwdViewController
      parent.present(pwdVC, animated: true, completion: completion)
    } else {
      completion?()
    }
  }
}

