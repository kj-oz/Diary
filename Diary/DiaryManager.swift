
//
//  DiaryManager.swift
//  Diary
//
//  Created by KO on 2017/11/24.
//  Copyright © 2017年 KO. All rights reserved.
//

import Foundation
import RealmSwift
import CloudKit
import UIKit

/// ログを出力する
///
/// - parameter text: ログに記入する文字列
public func slog(_ text: String) {
  print("[Diary] " + text)
}

/// 新たな日記セットのロード時の処理を受け持つデリゲート
protocol DiaryManagerDelegate {
  func entriesBeginLoading()
  func entriesEndLoading(entries: [Entry])
}

/// 日記の記事を管理するクラス
///
/// - description:
/// Diaryでは、全ての年を第1週から第53週の53の週で表す
/// フィルターが週の状態では第1週の1/1より前、第53週の12/31より後は、空白の日付として扱う
/// 20年に一度程度ある第54週の12/31は翌年の第1週として扱う
class DiaryManager {
  /// 祝日判定ライブラリ
  private static let ccl = CalculateCalendarLogic()
  
  /// サンドボックスのDocumentsディレクトリのフルパス
  static let docDir: String = {
    var docDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, false)[0]
    docDir = NSString(string: docDir).expandingTildeInPath
    return docDir
  }()
  
  /// Dateと日本時間のyyyyMMddを相互変換するフォーマッタ
  static let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter();
    dateFormatter.dateFormat = "yyyyMMdd"
    dateFormatter.locale = Locale(identifier: "ja_JP")
    return dateFormatter
  }()
  
  /// Dateから日本時間の曜日省略形を得るフォーマッタ
  private static let wdFormatter: DateFormatter = {
    let dateFormatter = DateFormatter();
    dateFormatter.dateFormat = "E"
    dateFormatter.locale = Locale(identifier: "ja_JP")
    return dateFormatter
  }()
  
  /// 指定の日付の曜日省略形を求める
  ///
  /// - parameter date: 曜日省略形を求める日付
  /// - returns: 曜日省略形
  static func weekday(of date: Date) -> String {
    return wdFormatter.string(from: date)
  }
  
  /// 指定の日付の週番号を求める
  ///
  /// - parameter date: 週番号を求める日付
  /// - returns: 週番号
  /// - description:
  /// 米国式週番号（1/1の属する週が第1週、日曜開始）を返す
  /// 週の途中で年が変わる場合、12月部分は53を、1月からは1を返す
  /// ただし20年に一度程度ある第54週の12/31は翌年の第1週として扱う（1を返す）
  static func weekNumber(of date: Date) -> Int {
    let cal = Calendar.current
    var currWeek = cal.component(.weekOfYear, from: date)
    if currWeek == 1 {
      let month = cal.component(.month, from: date)
      if month == 12 {
        let aWeekAgo = cal.date(byAdding: .day, value: -7, to: date)
        let prevWeek = cal.component(.weekOfYear, from: aWeekAgo!)
        // prevWeek == 53だと、まれにある第54週で1を返せば良い。それ以外は53
        if prevWeek < 53 {
          currWeek = 53
        }
      }
    }
    return currWeek
  }
  
  /// 与えられた年月日文字列のさす日付が祝日かどうかを判定する
  ///
  /// - parameter date: 年月日文字列
  /// - returns: 祝日かどうか
  static func isHoliday(_ date: String) -> Bool {
    let yaer = Int(date.prefix(4))!
    let md = date.suffix(4)
    let month = Int(md.prefix(2))!
    let day = Int(md.suffix(2))!
    
    return ccl.judgeJapaneseHoliday(year: yaer, month: month, day: day)
  }
  
  /// 唯一のインスタンス
  static var shared = DiaryManager()
  
  /// ユーザの選択したフィルタ種別
  var filterType: FilterType! {
    didSet {
      if filterType != .検索 {
        searchString = ""
      } else if searchString == "" {
        return
      }
      filter.set(type: filterType, searchString: searchString)
      listEntries()
    }
  }
  
  /// 入力された検索対象文字列
  var searchString = "" {
    didSet {
      if filterType == .検索 {
        filter.set(type: filterType, searchString: searchString)
        listEntries()
      }
    }
  }
  
  /// フィルタ
  var filter: DiaryFilter
  
  /// 日記セットが変化した際に処理を行うデリゲート
  var delegate: DiaryManagerDelegate?
  
  /// iCloudとの同期を受け持つオブジェクト
  private var syncHandler: SyncHandler
  
  /// iCloudにログインしているかどうか
  private var hasConnection = false
  
  /// 初期化
  private init() {
    filter = DiaryFilter()
    syncHandler = SyncHandler()
    
    print(DiaryManager.docDir)
    // test()
  }
  
  /// iCloudにログインしているかチェックする
  ///
  /// - parameter completionHandler: ログインしているかどうか判定がついた際に行う処理
  func checkCloudConnection(_ completionHandler:
      @escaping (_ status: CKAccountStatus, _ error: Error?) -> ()) {
    syncHandler.container.accountStatus(completionHandler: { (status, error) in
      if !self.hasConnection {
        // completionHandlerの中でErrorが発生すると、何故かここに
        // 2度到達（且つ2度目がエラー）するため、2度めは無視する
        if error == nil && status != .noAccount {
          self.hasConnection = true
        }
        completionHandler(status, error)
      }
    })
  }
  
  /// クラウドとの同期処理を開始する
  func sync() {
    if hasConnection {
      syncHandler.startSync() {
        DispatchQueue.main.async {
          self.listEntries()
        }
      }
    }
  }
  
  /// 各種の条件が変化した際に、条件に合致する日記セットを取得し直す
  private func listEntries() {
    print("▷ listEntries start")
    print("firstDate: \(filter.originDate)")
    print("filter: \(filter.type.rawValue)")
    print("filterValue: \(filter.value)")
    
    delegate?.entriesBeginLoading()
    var entries: [Entry] = []
    if filter.needDb {
      let data = queryDatabase()
      entries = wrapDatabases(data: data)
    } else {
      entries = filter.listDates()
      let data = queryDatabase()
      mergeEntries(entries: entries, data: data)
    }
    delegate?.entriesEndLoading(entries: entries)
    print("▷ listEntries end")
  }
  
  /// 日付を更新する
  func updateDate() {
    if filter.updateDate() {
      listEntries()
    }
  }
  
  /// 検索の対象を1日後にずらす
  func moveNext() {
    filter.moveNext()
    listEntries()
  }
  
  /// 検索の対象を1日前にずらす
  func movePrev() {
    filter.movePrev()
    listEntries()
  }
  
  /// 検索の起点を当日にする
  func resetDate() {
    filter.reset()
    listEntries()
  }

  /// DBから指定の条件に合致した記事を得る
  ///
  /// - returns: 条件に合致する記事
  private func queryDatabase() -> Results<DBEntry> {
    let realm = try! Realm()
    let results = realm.objects(DBEntry.self).filter(
      "deleted == false").sorted(byKeyPath: "date", ascending: false)
    return filter.applyTo(data: results)
  }
  
  /// filterから得られた合致日付に、DBから得られたレコードをセットする
  ///
  /// - parameter entries: filterから得られた合致日付
  /// - parameter data: DBから得られたレコード
  private func mergeEntries(entries: [Entry], data: Results<DBEntry>) {
    var eIndex = 0
    var dIndex = 0
    let eMax = entries.count
    let dMax = data.count
    var eDate: String
    var dDate: String

    while eIndex < eMax && dIndex < dMax {
      eDate = entries[eIndex].date
      dDate = data[dIndex].date
      if eDate < dDate {
        dIndex += 1
      } else if eDate > dDate {
        eIndex += 1
      } else {
        entries[eIndex].data = data[dIndex]
        eIndex += 1
        dIndex += 1
      }
    }
  }
  
  /// DBから得られたレコードから日記のエントリーを生成する
  ///
  /// - parameter data: DBから得られたレコード
  /// - returns: 日記のエントリー
  private func wrapDatabases(data: Results<DBEntry>) -> [Entry] {
    return data.map() {
      return Entry(data: $0)
    }
  }
}

