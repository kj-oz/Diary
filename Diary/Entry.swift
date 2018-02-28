//
//  Entry.swift
//  Diary
//
//  Created by KO on 2017/11/22.
//  Copyright © 2017年 KO. All rights reserved.
//

import Foundation
import RealmSwift

/// 日記の1件の記事を表すクラス
class Entry {
  /// 日付（yyyyMMdd形式の文字列）
  let date: String
  
  /// 週番号
  let wn: Int8
  
  /// 週の曜日
  let wd: Int8
  
  /// 存在しない日の穴埋めのためのエントリー
  var padding = false
  
  /// DBに登録されている内容
  var data: DBEntry?
  
  /// 初期化
  ///
  /// - parameter date: 日付
  /// - parameter weekNumber: 週番号（省略可）
  /// - description:
  /// 年末は第53週と第1週が同じ週を指す場合がある
  /// その場合第53週の後半（1月）、第1週の前半（12月）はpaddingとして扱う
  init(date: Date, weekNumber: Int = 0) {
    let cal = Calendar.current
    wd = Int8(cal.component(.weekday, from: date))
    var dateStr = DiaryManager.dateFormatter.string(from: date)
    let apiWeek = DiaryManager.weekNumber(of: date)
    if weekNumber == 0 {
      wn = Int8(apiWeek)
    } else {
      wn = Int8(weekNumber)
      if weekNumber != apiWeek {
        padding = true
        let year = cal.component(.year, from: date)
        dateStr = String(weekNumber == 1 ? year + 1 : year - 1)
      }
    }
    self.date = dateStr
  }
  
  /// 穴埋め用エントリーの初期化
  ///
  /// - parameter paddingDate: 穴埋め時の日付文字列
  init(paddingDate: String) {
    self.date = paddingDate
    wn = 0
    wd = 0
    padding = true
  }
  
  /// DBレコードに基づいたエントリーの初期化
  ///
  /// - parameter data: DBのレコード
  init(data: DBEntry) {
    date = data.date
    wn = data.wn
    wd = data.wd
    self.data = data
  }
  
  /// DBレコード部分を更新する
  ///
  /// - parameter text: 記事
  /// - parameter photos: 写真定義
  /// - throws: DBへの書き込みに失敗した場合
  public func updateData(text: String, photos: String) throws {
    let realm = try Realm()
    try realm.write {
      var target: DBEntry
      if let data = data {
        target = data
      } else {
        target = DBEntry()
        target.date = date
        target.wn = wn
        target.wd = wd
      }
      target.text = text
      target.photos = photos
      target.modified = Date()
      if data == nil {
        realm.add(target)
        data = target
      }
    }
  }
}

/// DBのレコードを表すクラス、Realmのオブジェクトを継承する
class DBEntry: Object {
  /// 日付（yyyyMMdd形式の文字列）
  @objc dynamic var date = ""
  
  /// 週番号
  @objc dynamic var wn: Int8 = 0
  
  /// 曜日
  @objc dynamic var wd: Int8 = 0
  
  /// 日記の記事
  @objc dynamic var text = ""
  
  /// 写真の定義、Documents/yyyyMMddフォルダ下の画像ファイルの海洋師なしの名称をカンマ区切りでつなげた文字列
  @objc dynamic var photos = ""
  
  /// 削除されたどうかのフラグ、実際の削除は削除フラグの同期後に行う
  @objc dynamic var deleted = false
  
  /// 最終更新日時
  @objc dynamic var modified = Date()
  
  /// 主キーを返す、主キーは日付
  override static func primaryKey() -> String? {
    return "date"
  }
}

