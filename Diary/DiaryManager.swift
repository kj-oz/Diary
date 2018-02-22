
//
//  DiaryManager.swift
//  Diary
//
//  Created by KO on 2017/11/24.
//  Copyright © 2017年 KO. All rights reserved.
//

import Foundation
import RealmSwift

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
    dateFormatter.locale = Locale.current
    return dateFormatter
  }()
  
  /// Dateから日本時間の曜日省略形を得るフォーマッタ
  static private let wdFormatter: DateFormatter = {
    let dateFormatter = DateFormatter();
    dateFormatter.dateFormat = "E"
    dateFormatter.locale = Locale.current
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
  
  /// .検索の際の実際の検索条件
  var filter = DiaryFilter()
  
  /// 日記セットが変化した際に処理を行うデリゲート
  var delegate: DiaryManagerDelegate?
  
  /// 初期化
  init() {
    let cal = Calendar.current
    filter.originDate = cal.startOfDay(for: Date())
    filter.earliestDate = Date(timeIntervalSinceReferenceDate: 0)
    print(DiaryManager.docDir)
    
    //test()
  }
  
  /// 各種の条件が変化した際に、条件に合致する日記セットを取得し直す
  func listEntries() {
    print("▷ listEntries start")
    print("firstDate: \(filter.originDate)")
    print("filter: \(filter.type.rawValue)")
    print("filterValue: \(filter.value)")
    
    delegate?.entriesBeginLoading()
    var entries: [Entry] = []
    if filter.needDb {
      let records = queryDatabase()
      entries = wrapDatabases(records: records)
    } else {
      entries = filter.listDates()
      let records = queryDatabase()
      mergeEntries(entries: entries, records: records)
    }
    delegate?.entriesEndLoading(entries: entries)
    print("▷ listEntries end")
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
  func queryDatabase() -> Results<Record> {
    let realm = try! Realm()
    let results = realm.objects(Record.self).filter(
      "deleted == false").sorted(byKeyPath: "date", ascending: false)
    return filter.applyTo(records: results)
  }
  
  /// filterから得られた合致日付に、DBから得られたレコードをセットする
  ///
  /// - parameter entries: filterから得られた合致日付
  /// - parameter records: DBから得られたレコード
  func mergeEntries(entries: [Entry], records: Results<Record>) {
    var eIndex = 0
    var dIndex = 0
    let eMax = entries.count
    let dMax = records.count
    var eDate: String
    var dDate: String

    while eIndex < eMax && dIndex < dMax {
      eDate = entries[eIndex].date
      dDate = records[dIndex].date
      if eDate < dDate {
        dIndex += 1
      } else if eDate > dDate {
        eIndex += 1
      } else {
        entries[eIndex].record = records[dIndex]
        eIndex += 1
        dIndex += 1
      }
    }
  }
  
  /// DBから得られたレコードから日記のエントリーを生成する
  ///
  /// - parameter records: DBから得られたレコード
  /// - returns: 日記のエントリー
  func wrapDatabases(records: Results<Record>) -> [Entry] {
    return records.map() {
      return Entry(record: $0)
    }
  }
}
