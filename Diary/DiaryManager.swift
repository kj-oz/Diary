//
//  DiaryManager.swift
//  Diary
//
//  Created by KO on 2017/11/24.
//  Copyright © 2017年 KO. All rights reserved.
//

import Foundation
import RealmSwift

/// 日記のフィルター
public enum DiaryFilter : String {
  case 月日     // 各年 X月Y日
  case 週      // 各年 第X週Y曜日
  case 日      // 各月 Y日
  case 曜日     // 各週 Y曜日
  case 検索     // 検索バーに入力された文字列
  case なし
  static let allCases: [DiaryFilter] = [.月日, .週, .日, .曜日, .検索, .なし]
}

/// 新たな日記セットのロード時の処理を受け持つデリゲート
protocol DiaryManagerDelegate {
  func entriesBeginLoading()
  func entriesEndLoading(entries: [Entry])
}

/// 日記の記事を管理するクラス
///
/// - Description:
/// Diaryでは、全ての年を第1週から第53週の53の週で表す
/// フィルターが週の状態では第1週の1/1より前、第53週の12/31より後は、空白の日付として扱う
/// 20年に一度程度ある第54週の12/31は翌年の第1週として扱う
class DiaryManager {
  
  /// 各月の最大日数（1月は[1]に保持）
  static let maxDaysOfMonth = [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  
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
  /// - Parameter date: 曜日省略形を求める日付
  /// - Returns: 曜日省略形
  static func weekday(of date: Date) -> String {
    return wdFormatter.string(from: date)
  }
  
  /// 指定の日付の週番号を求める
  ///
  /// - Parameter date: 週番号を求める日付
  /// - Returns: 週番号
  /// - Description:
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
  
  /// 日記として扱う最古の日付
  var earliestDate: Date
  
  /// 最古の日付のfilterValue換算値
  var earliestValue = 0
  
  /// フィルター
  var filter: DiaryFilter! {
    didSet {
      let filter = setFilterValeu()
      listEntries(filter: filter)
    }
  }
  
  /// フィルター対象値
  /// .月日：3月21日 → 321
  /// .週　：第3週の月曜日 → 32
  /// .日　：21日 → 21
  /// .曜日：月曜日 → 2
  /// .なし：2018年3月21日 → 20180321
  var filterValue = 0
  
  /// 上位の値（月日、週の場合の年、日の場合の年月）
  var upperValue = 0
  
  /// 最初の該当日
  var firstDate: Date
  
  /// 入力された検索対象文字列
  var searchString = ""
  
  /// 検索キーワード
  var keywords: [String] = []
  
  /// フィルター対象値の文字列表現
  var filterValueString: String {
    let cal = Calendar.current
    switch filter {
    case .月日:
      let m = filterValue / 100
      let d = filterValue % 100
      return "\(m)月\(d)日"
    case .週:
      let wn = filterValue / 10
      let wd = filterValue % 10
      return "第\(wn)週 \(cal.weekdaySymbols[wd - 1])"
    case .日:
      return "\(filterValue)日"
    case .曜日:
      return "\(cal.weekdaySymbols[filterValue - 1])"
    default:
      let y = filterValue / 10000
      let md = filterValue % 10000
      let m = md / 100
      let d = md % 100
      return "\(y)年\(m)月\(d)日"
    }
  }
  
  /// 日記セットが変化した際に処理を行うデリゲート
  var delegate: DiaryManagerDelegate?
  
  /// 初期化
  init() {
    let cal = Calendar.current
    firstDate = cal.startOfDay(for: Date())
    earliestDate = Date(timeIntervalSinceReferenceDate: 0)
    print(DiaryManager.docDir)
    
    //test()
  }
  
  /// フィルターと最初の日に応じて各種のプロパティを更新する
  func setFilterValeu() -> DiaryFilter {
    var result = filter!
    let cal = Calendar.current
    switch filter {
    case .月日:
      filterValue = cal.component(.month, from: firstDate) * 100 +
        cal.component(.day, from: firstDate)
      upperValue = cal.component(.year, from: firstDate)
      earliestValue = cal.component(.year, from: earliestDate)
    case .週:
      filterValue = DiaryManager.weekNumber(of: firstDate) * 10 +
        cal.component(.weekday, from: firstDate)
      upperValue = cal.component(.year, from: firstDate)
      earliestValue = cal.component(.year, from: earliestDate)
    case .日:
      filterValue = cal.component(.day, from: firstDate)
      upperValue = cal.component(.year, from: firstDate) * 100 +
        cal.component(.month, from: firstDate)
      earliestValue = cal.component(.year, from: earliestDate) * 100 +
        cal.component(.month, from: earliestDate)
    case .曜日:
      filterValue = cal.component(.weekday, from: firstDate)
    case .検索:
      result = parseSearchText()
    default:
      filterValue = Int(DiaryManager.dateFormatter.string(from: firstDate))!
    }
    return result
  }
  
  func parseSearchText() -> DiaryFilter {
    let cal = Calendar.current
    var filter = DiaryFilter.なし
    keywords = []
    let parts = searchString.components(separatedBy: .whitespaces)
    let first = parts[0]
    if let value = Int(first) {
      if value > 1231 {
        // 年月日、年月、年
      } else if value > 100 {
        // 月日
        filter = .月日
        filterValue = value
        upperValue = cal.component(.year, from: firstDate)
        earliestValue = cal.component(.year, from: earliestDate)
      } else {
        // 日
        filter = .日
        filterValue = value
        upperValue = cal.component(.year, from: firstDate) * 100 +
          cal.component(.month, from: firstDate)
        earliestValue = cal.component(.year, from: earliestDate) * 100 +
          cal.component(.month, from: earliestDate)
      }
      keywords = Array(parts.dropFirst())
    } else if first.prefix(1) == "@", let value = Int(first.suffix(first.count - 1)) {
      if value > 10 {
        // 週
        filter = .週
        filterValue = value
        upperValue = cal.component(.year, from: firstDate)
        earliestValue = cal.component(.year, from: earliestDate)
      } else {
        // 曜日
        filter = .曜日
        filterValue = value
      }
      keywords = Array(parts.dropFirst())
    } else {
      // キーワード
      keywords = parts
    }
    return filter
  }
  
  /// 各種の条件が変化した際に、条件に合致する日記セットを取得し直す
  func listEntries(filter: DiaryFilter) {
    print("▷ listEntries start")
    print("firstDate: \(firstDate)")
    print("filter: \(filter.rawValue)")
    print("filterValue: \(filterValue)")
    print("upperValue: \(upperValue)")
    
    delegate?.entriesBeginLoading()
    let entries = listDates(filter: filter)
    let dbs = queryDatabase()
    mergeEntries(entries: entries, dbs: dbs)
    delegate?.entriesEndLoading(entries: entries)
    print("▷ listEntries end")
  }
  
  /// 最初の日を1日後にずらす
  func moveNext() {
    let cal = Calendar.current
    firstDate = cal.date(byAdding: .day, value: 1, to: firstDate)!
    switch filter {
    case .月日:
      if filterValue == 1231 {
        filterValue = 101
        upperValue += 1
      } else {
        var m = filterValue / 100
        var d = filterValue % 100
        if d == DiaryManager.maxDaysOfMonth[m] {
          d = 1
          m += 1
          filterValue = m * 100 + d
        } else {
          filterValue += 1
        }
      }
    case .週:
      if filterValue == 537 {
        filterValue = 11
        upperValue += 1
      } else {
        var wn = filterValue / 10
        var wd = filterValue % 10
        if wd == 7 {
          wd = 1
          wn += 1
          filterValue = wn * 10 + wd
        } else {
          filterValue += 1
        }
      }
    case .日:
      if filterValue == 31 {
        filterValue = 1
        upperValue += 1
      } else {
        filterValue += 1
      }
    case .曜日:
      if filterValue == 7 {
        filterValue = 1
      } else {
        filterValue += 1
      }
    default:
      break
    }
    listEntries(filter: filter)
  }
  
  /// 最初の日を1日前にずらす
  func movePrev() {
    let cal = Calendar.current
    firstDate = cal.date(byAdding: .day, value: -1, to: firstDate)!
    switch filter {
    case .月日:
      if filterValue == 101 {
        filterValue = 1231
        upperValue -= 1
      } else {
        var m = filterValue / 100
        var d = filterValue % 100
        if d == 1 {
          m -= 1
          d = DiaryManager.maxDaysOfMonth[m]
          filterValue = m * 100 + d
        } else {
          filterValue -= 1
        }
      }
    case .週:
      if filterValue == 11 {
        filterValue = 537
        upperValue -= 1
      } else {
        var wn = filterValue / 10
        var wd = filterValue % 10
        if wd == 1 {
          wd = 7
          wn -= 1
          filterValue = wn * 10 + wd
        } else {
          filterValue -= 1
        }
      }
    case .日:
      if filterValue == 1 {
        filterValue = 31
        upperValue -= 1
      } else {
        filterValue -= 1
      }
    case .曜日:
      if filterValue == 1 {
        filterValue = 7
      } else {
        filterValue -= 1
      }
    default:
      break
    }
    listEntries(filter: filter)
  }
  
  func resetDate() {
    let cal = Calendar.current
    firstDate = cal.startOfDay(for: Date())
    let filter = setFilterValeu()
    listEntries(filter: filter)
  }

  /// 条件に合致する日付群を抽出する
  func listDates(filter: DiaryFilter) -> [Entry] {
    if filter == .月日 {
      return listDatesMD()
    } else if filter == .週 {
      return listDatesWE()
    } else if filter == .日 {
      return listDatesD()
    }
    
    var results: [Entry] = []
    let cal = Calendar.current
    var comps = DateComponents()
    if filter == .曜日 {
      comps.weekday = filterValue
    } else {
      comps.hour = 6
    }
    let startDate = cal.date(byAdding: .day, value: 1, to: firstDate)!

    cal.enumerateDates(startingAfter: startDate, matching: comps, matchingPolicy: .strict, repeatedTimePolicy: .first, direction: .backward) { (date, match, stop) in
      if let date = date {
        if date < earliestDate {
          stop = true
          return
        }
        results.append(Entry(date: date))
      }
    }
    return results
  }
  
  /// 条件が月日の際に条件に合致する日付群を抽出する
  func listDatesMD() -> [Entry] {
    var results: [Entry] = []
    let cal = Calendar.current
    var comps = DateComponents()
    comps.day = filterValue % 100
    comps.month = filterValue / 100
    let startDate = cal.date(byAdding: .day, value: 1, to: firstDate)!
    
    var target = upperValue
    cal.enumerateDates(startingAfter: startDate, matching: comps, matchingPolicy: .nextTime, repeatedTimePolicy: .first, direction: .backward) { (date, match, stop) in
      if let date = date {
        if date < earliestDate {
          stop = true
          return
        }
        if match {
          results.append(Entry(date: date))
        } else {
          results.append(Entry(paddingDate: String(target)))
        }
        target -= 1
      }
    }
    return results
  }
  
  /// 条件が日の際に条件に合致する日付群を抽出する
  func listDatesD() -> [Entry] {
    var results: [Entry] = []
    let cal = Calendar.current
    var comps = DateComponents()
    comps.day = filterValue
    let startDate = cal.date(byAdding: .day, value: 1, to: firstDate)!
    
    var target = upperValue
    cal.enumerateDates(startingAfter: startDate, matching: comps, matchingPolicy: .nextTime, repeatedTimePolicy: .first, direction: .backward) { (date, match, stop) in
      if let date = date {
        if date < earliestDate {
          stop = true
          return
        }
        if match {
          if target == upperValue {
            // filterValue が 31から1に変わったときに、firstDateを補正
            firstDate = date
          }
          results.append(Entry(date: date))
        } else {
          results.append(Entry(paddingDate: String(target)))
        }
        target -= (target % 100 == 1 ? 89 : 1)
      }
    }
    return results
  }
  
  /// 条件が週の際に条件に合致する日付群を抽出する
  private func listDatesWE() -> [Entry] {
    let cal = Calendar.current

    // 検索対象週を確定する
    let wn = filterValue / 10
    let wd = filterValue % 10

    // 検索を実行する
    // enumerateDates仕様：
    // comps.weekOfYear と comps.weekday 両方は指定できない
    // （comps.weekOfYear を指定すると、startingAfter の曜日で検索される）
    // comps.weekOfYearに53を指定すると、翌年の第1週ではない本当の53週の日付しか返ってこない
    // ⇒ 第1週で検索し、前週が53週だったら前週の日付に訂正
    // startingAfterの週番号とcomps.weekOfYear が異なっているとstartingAfterの曜日が無視され、
    // callbackには日曜日の日付が渡されてくる ⇒ startingAfter が本当の53週だったら曜日分シフト
    var results: [Entry] = [Entry(date: firstDate, weekNumber: wn)]
    var comps = DateComponents()
    var shift = 0
    if wn == 53 {
      comps.weekOfYear = 1
      if cal.component(.weekOfYear, from: firstDate) > 50 {
        shift = wd - 1
      }
    } else {
      comps.weekOfYear = wn
    }
    cal.enumerateDates(startingAfter: firstDate, matching: comps, matchingPolicy: .nextTimePreservingSmallerComponents, repeatedTimePolicy: .first, direction: .backward) { (date, match, stop) in
      if var date = date {
        if date < earliestDate {
          stop = true
          return
        }
        if wn == 53 {
          if shift > 0 {
            date = cal.date(byAdding: .day, value: shift, to: date)!
          }
          let aWeekAgo = cal.date(byAdding: .day, value: -7, to: date)!
          let prevWeek = cal.component(.weekOfYear, from: aWeekAgo)
          // prevWeek == 53 だと1/1が日曜で53週が正式にあるケースか、まれにある54週目の12/31が日曜だったケース
          if prevWeek == 53 {
            date = aWeekAgo
          }
        }
        results.append(Entry(date: date, weekNumber: wn))
      }
    }
    return results
  }
  
  func queryDatabase() -> Results<DBEntry> {
    let realm = try! Realm()
    let results = realm.objects(DBEntry.self).filter("deleted == false").sorted(byKeyPath: "date", ascending: false)
    let dates: Results<DBEntry>
    switch filter! {
    case .月日, .日:
      dates = results.filter("date ENDSWITH %@", String(filterValue))
    case .週:
      let wn = filterValue / 10
      let wd = filterValue % 10
      dates = results.filter("wn == %@ AND wd == %@", wn, wd)
    case .曜日:
      dates = results.filter("wd == %@", filterValue)
    default:
      dates = results
    }
    return dates
  }
  
  func mergeEntries(entries: [Entry], dbs: Results<DBEntry>) {
    var eIndex = 0
    var dIndex = 0
    let eMax = entries.count
    let dMax = dbs.count
    var eDate: String
    var dDate: String

    while eIndex < eMax && dIndex < dMax {
      eDate = entries[eIndex].date
      dDate = dbs[dIndex].date
      if eDate < dDate {
        dIndex += 1
      } else if eDate > dDate {
        eIndex += 1
      } else {
        entries[eIndex].db = dbs[dIndex]
        eIndex += 1
        dIndex += 1
      }
    }
  }
}
