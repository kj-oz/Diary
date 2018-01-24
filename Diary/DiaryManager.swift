//
//  DiaryManager.swift
//  Diary
//
//  Created by KO on 2017/11/24.
//  Copyright © 2017年 KO. All rights reserved.
//

import Foundation
import RealmSwift

enum DiaryFilter : String {
  case 月日
  case 週
  case 日
  case 曜日
  case 検索
  case なし
  static let allCases: [DiaryFilter] = [.月日, .週, .日, .曜日, .検索, .なし]
}

/// 日記の記事を管理するクラス
///
/// - Description:
/// Diaryでは、全ての年を第1週から第53週の53の週で表す
/// フィルターが週番号＋曜日の状態では第1週の1/1より前、第53週の12/31より後は、空白の日付として扱う
/// 20年に一度程度ある第54週の12/31は翌年の第1週として扱う
class DiaryManager {
  static let maxDaysOfMonth = [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  
  static let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter();
    dateFormatter.dateFormat = "yyyyMMdd"
    dateFormatter.locale = Locale.current
    return dateFormatter
  }()
  
  static private let wdFormatter: DateFormatter = {
    let dateFormatter = DateFormatter();
    dateFormatter.dateFormat = "E"
    dateFormatter.locale = Locale.current
    return dateFormatter
  }()
  
  static func weekday(of date: Date) -> String {
    return wdFormatter.string(from: date)
  }
  
  /// 指定の日付の週番号を求める
  ///
  /// - Parameter of: 週番号を求める日付
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
  
  /// 最古の日付
  var earliestDate: Date
  
  ///
  var earliestValue = 0
  
  /// フィルター
  var filter: DiaryFilter
//  {
//    didSet {
//      setFilterValeu()
//      listEntries()
//    }
//  }
  
  /// フィルター対象
  var filterValue = 0
  
  /// 上位の値（月日、週の場合の年、日の場合の年月）
  var upperValue = 0
  
  /// 最初の該当日
  var firstDate: Date
  
  /// 検索対象文字列
  var searchString: String
  
  /// 条件に合致したエントリー
  private var _entries: [Entry] = []
  var entries: [Entry] {
    return _entries
  }
  
  ///
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
  
  init() {
    let earliestDateString = UserDefaults.standard.string(forKey: "earliestDate") ?? "19980701"
    earliestDate = DiaryManager.dateFormatter.date(from: earliestDateString)!
    
    searchString = UserDefaults.standard.string(forKey: "search") ?? ""
    
    let cal = Calendar.current
    firstDate = cal.startOfDay(for: Date())
    let filterString = UserDefaults.standard.string(forKey: "filter") ?? "月日"
    filter = DiaryFilter.init(rawValue: filterString)!
    setFilterValeu()
    listEntries()
  }
  
  func changeFilter(_ filter: DiaryFilter, completionHandler: (()->Void)?) {
    self.filter = filter
    if filter != .検索 {
      setFilterValeu()
      listEntries()
      completionHandler?()
    }
  }
  
  func setFilterValeu() {
    print("▷ setFilterValue start")
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
    default:
      filterValue = Int(DiaryManager.dateFormatter.string(from: firstDate))!
    }
  }
  
  func listEntries() {
    print("▷ listEntries start")
    let entries = listDates()
    self._entries = entries
  }
  
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
  }
  
  func movePrev() {
    let cal = Calendar.current
    firstDate = cal.date(byAdding: .day, value: 1, to: firstDate)!
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
  }

  
  func listDates() -> [Entry] {
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
          print("▷ listEntries end")
          return
        }
        results.append(Entry(date: date))
      }
    }
    return results
  }
  
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
          print("▷ listEntries end")
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
          print("▷ listEntries end")
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
      if cal.component(.weekOfYear, from: firstDate) == 53 {
        shift = wd - 1
      }
    } else {
      comps.weekOfYear = wn
    }
    cal.enumerateDates(startingAfter: firstDate, matching: comps, matchingPolicy: .nextTimePreservingSmallerComponents, repeatedTimePolicy: .first, direction: .backward) { (date, match, stop) in
      if var date = date {
        if date < earliestDate {
          stop = true
          print("▷ listEntries end")
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
}
