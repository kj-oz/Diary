//
//  AppDelegate.swift
//  Diary
//
//  Created by KO on 2017/11/20.
//  Copyright © 2017年 KO. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?
  
  // アプリケーションが前面に表示される直前のイベントを通知する
  func applicationWillEnterForeground(_ application: UIApplication) {
    let notification = Notification(name: Notification.Name(rawValue: "applicationWillEnterForeground"), object: self)
    NotificationCenter.default.post(notification)
  }
}

/// メッセージ上部に表示されるアプリケーション名
let appTitle = "百年日記"

/// OKボタン一つの確認画面を表示する
///
/// - parameter viewConroller 表示中のビューコントローラ
/// - parameter message メッセージ文字列
/// - parameter handler ボタンの押下後に実行されるハンドラ
func alert(viewController: UIViewController, message: String, handler: (()->Void)? = nil) {
  let alert = UIAlertController(title:appTitle, message: message, preferredStyle: UIAlertControllerStyle.alert)
  let ok = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { _ in
    handler?()
  }
  alert.addAction(ok)
  alert.popoverPresentationController?.sourceView = viewController.view
  alert.popoverPresentationController?.sourceRect = viewController.view.frame
  viewController.present(alert, animated: true, completion: nil)
}

/// OKボタン、キャンセルボタンの確認画面を表示する
///
/// - parameter viewConroller 表示中のビューコントローラ
/// - parameter message メッセージ文字列
/// - parameter handler いずれかのボタンの押下後に実行されるハンドラ
/// 引数は、OKだったかどうか
func confirm(viewController: UIViewController, message: String, handler: ((Bool)->Void)? = nil) {
  let alert = UIAlertController(title:appTitle, message: message, preferredStyle: UIAlertControllerStyle.alert)
  let ok = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { _ in
    handler?(true)
  }
  alert.addAction(ok)
  let cancel = UIAlertAction(title: "キャンセル", style: UIAlertActionStyle.cancel) { _ in
    handler?(false)
  }
  alert.addAction(cancel)

  alert.popoverPresentationController?.sourceView = viewController.view
  alert.popoverPresentationController?.sourceRect = viewController.view.frame
  viewController.present(alert, animated: true, completion: nil)
}

