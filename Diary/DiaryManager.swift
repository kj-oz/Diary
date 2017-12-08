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
  case MMdd
  case wE
  case dd
  case E
  case none
}

/// 日記の記事を管理するクラス
///
/// - Description:
/// Diaryでは、全ての年を第1週から第53週の53の週で表す
/// フィルターが週番号＋曜日の状態では第1週の1/1より前、第53週の12/31より後は、空白の日付として扱う
/// 20年に一度程度ある第54週の12/31は翌年の第1週として扱う
class DiaryManager {
  
  static let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter();
    dateFormatter.dateFormat = "yyyyMMdd"
    dateFormatter.locale = Locale.current
    return dateFormatter
  }()
  
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
  
  var startDate: Date
  
  var filter: DiaryFilter
  
  init() {
    let startDateString = UserDefaults.standard.string(forKey: "startDate") ?? "19980701"
    startDate = DiaryManager.dateFormatter.date(from: startDateString)!
    
    let filterString = UserDefaults.standard.string(forKey: "filter") ?? "MMdd"
    filter = DiaryFilter.init(rawValue: filterString)!
  }
  
  
  func entries(filter: DiaryFilter, offset: Int) -> [Entry] {
    
    return []
  }
  
  func test() {
    let cal = Calendar.current
    var comps = DateComponents()
    var dates = [Entry]()
    
    print("wE 2017/12/2")
    comps.year = 2017
    comps.month = 12
    comps.day = 2
    dates = listDates(filter: .wE, firstDate: cal.date(from: comps)!)
    printDates(dates: dates)
    
    print("wE 2017/12/31")
    comps.year = 2017
    comps.month = 12
    comps.day = 31
    dates = listDates(filter: .wE, firstDate: cal.date(from: comps)!)
    printDates(dates: dates)

    print("wE 2016/12/28")
    comps.year = 2016
    comps.month = 12
    comps.day = 28
    dates = listDates(filter: .wE, firstDate: cal.date(from: comps)!)
    printDates(dates: dates)

    print("wE 2015/12/30")
    comps.year = 2015
    comps.month = 12
    comps.day = 30
    dates = listDates(filter: .wE, firstDate: cal.date(from: comps)!)
    printDates(dates: dates)
    
    print("wE 2016/12/31")
    comps.year = 2016
    comps.month = 12
    comps.day = 31
    dates = listDates(filter: .wE, firstDate: cal.date(from: comps)!)
    printDates(dates: dates)

    print("wE 2017/1/1")
    comps.year = 2017
    comps.month = 1
    comps.day = 1
    dates = listDates(filter: .wE, firstDate: cal.date(from: comps)!)
    printDates(dates: dates)

    print("wE 2017/1/4")
    comps.year = 2017
    comps.month = 1
    comps.day = 4
    dates = listDates(filter: .wE, firstDate: cal.date(from: comps)!)
    printDates(dates: dates)

    print("wE 2017/1/7")
    comps.year = 2017
    comps.month = 1
    comps.day = 7
    dates = listDates(filter: .wE, firstDate: cal.date(from: comps)!)
    printDates(dates: dates)

    print("wE 2000/12/31")
    comps.year = 2000
    comps.month = 12
    comps.day = 31
    dates = listDates(filter: .wE, firstDate: cal.date(from: comps)!)
    printDates(dates: dates)
  }
  
  private func printDates(dates: [Entry]) {
    let df = DateFormatter()
    df.locale = Locale.current
    df.dateFormat = "yyyyMMdd w E"
    for date in dates {
      print(df.string(from: DiaryManager.dateFormatter.date(from: date.date)!))
    }
  }
  
  private func listDates(filter: DiaryFilter, firstDate: Date, weekNumber: Int = 0) -> [Entry] {
    if filter == .wE {
      return listDatesWE(firstDate: firstDate, weekNumber: weekNumber)
    }
    
    var results: [Entry] = [Entry(date: firstDate, weekNumber: weekNumber)]
    let cal = Calendar.current
    var comps = DateComponents()
    switch filter {
    case .MMdd:
      comps.day = cal.component(.day, from: firstDate)
      comps.month = cal.component(.month, from: firstDate)
    case .wE:
      return results // ここには絶対に到達しない
    case .dd:
      comps.day = cal.component(.day, from: firstDate)
    case .E:
      comps.weekday = cal.component(.weekday, from: firstDate)
    default:
      comps.hour = cal.component(.hour, from: firstDate)
    }

    cal.enumerateDates(startingAfter: firstDate, matching: comps, matchingPolicy: .nextTimePreservingSmallerComponents, repeatedTimePolicy: .first, direction: .backward) { (date, match, stop) in
      if let date = date {
        if date < startDate {
          stop = true
          return
        }
        results.append(Entry(date: date))
      }
    }
    return results
  }
  
  private func listDatesWE(firstDate: Date, weekNumber: Int) -> [Entry] {
    let cal = Calendar.current
    
    // 検索対象週を確定する
    let wn = weekNumber == 0 ? DiaryManager.weekNumber(of: firstDate) : weekNumber
    
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
        shift = cal.component(.weekday, from: firstDate) - 1
      }
    } else {
      comps.weekOfYear = wn
    }
    cal.enumerateDates(startingAfter: firstDate, matching: comps, matchingPolicy: .nextTimePreservingSmallerComponents, repeatedTimePolicy: .first, direction: .backward) { (date, match, stop) in
      if var date = date {
        if date < startDate {
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
}
