//
//  Entry.swift
//  Diary
//
//  Created by KO on 2017/11/22.
//  Copyright © 2017年 KO. All rights reserved.
//

import Foundation
import RealmSwift

class Entry {
  let date: String
  let wn: Int8
  let wd: Int8
  var padding = false
  var db: DBEntry?
  
  init(date: Date, weekNumber: Int = 0) {
    let cal = Calendar.current
    self.date = DiaryManager.dateFormatter.string(from: date)
    wd = Int8(cal.component(.weekday, from: date))
    let apiWeek = DiaryManager.weekNumber(of: date)
    if weekNumber == 0 {
      wn = Int8(apiWeek)
    } else {
      wn = Int8(weekNumber)
      if weekNumber != apiWeek {
        padding = true
      }
    }
  }
  
  init(paddingDate: String) {
    self.date = paddingDate
    wn = 0
    wd = 0
    padding = true
  }
}

class DBEntry: Object {
  @objc dynamic var date = ""
  @objc dynamic var wn: Int8 = 0
  @objc dynamic var wd: Int8 = 0
  @objc dynamic var text = ""
  @objc dynamic var photos = ""
  @objc dynamic var deleted = false
  @objc dynamic var modified = Date()
  
  override static func primaryKey() -> String? {
    return "id"
  }
}

