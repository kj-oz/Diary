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

