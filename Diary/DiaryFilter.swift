//
//  Diaryswift
//  Diary
//
//  Created by KO on 2018/02/08.
//  Copyright © 2018年 KO. All rights reserved.
//

import Foundation
import RealmSwift

/// 日記のフィルタ種別
public enum FilterType : String {
  case 月日     // 各年 X月Y日
  case 週      // 各年 第X週Y曜日
  case 日      // 各月 Y日
  case 曜日     // 各週 Y曜日
  case 検索     // 検索バーに入力された文字列
  case 毎日     // 全ての日
  case 年      // X年の全ての日
  case 年月     // X年Y月の全ての日
  case 年月日    // X年Y月Z日の前後21日
  
  /// ユーザが選択可能な種別リスト
  static let selectables: [FilterType] = [.月日, .週, .日, .曜日, .検索, .毎日]
}

/// 日記の記事に対するフィルタ
class DiaryFilter {
  /// 各月の最大日数（1月は[1]に保持）
  static let maxDaysOfMonth = [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  
  /// 検索の起点となる（最近の）日
  var originDate = Date()
  
  /// 取り扱う最古の日
  var earliestDate = Date()
  
  /// 種別
  var type: FilterType = .毎日
  
  /// フィルタ対象値
  var value = 0
  
  /// 記事のない日を許容しないかどうか
  var needDb = false
  
  /// 記事に含まれるべき検索ワード
  var keywords: [String] = []

  /// フィルター対象値の文字列表現
  var valueString: String {
    let cal = Calendar.current
    switch type {
    case .年月日:
      let y = value / 10000
      let md = value % 10000
      let m = md / 100
      let d = md % 100
      return "\(y)年\(m)月\(d)日"
    case .年月:
      let y = value / 100
      let m = value % 100
      return "\(y)年\(m)月"
    case .年:
      return "\(value)年"
    case .月日:
      let m = value / 100
      let d = value % 100
      return "\(m)月\(d)日"
    case .週:
      let wn = value / 10
      let wd = value % 10
      return "第\(wn)週 \(cal.weekdaySymbols[wd - 1])"
    case .日:
      return "\(value)日"
    case .曜日:
      return "\(cal.weekdaySymbols[value - 1])"
    case .毎日:
      let cal = Calendar.current
      let y = cal.component(.year, from: originDate)
      let m = cal.component(.month, from: originDate)
      let d = cal.component(.day, from: originDate)
      return "\(y)年\(m)月\(d)日"
    default:
      return ""
    }
  }
  
  /// フィルタ種別と起点日あるいは検索文字列に応じてフィルタの内容を更新する
  ///
  /// - parameter type: ユーザの指定したフィルタ種別
  /// - parameter searchString: ユーザの指定した検索文字列（種別が.検索時のみ有効)
  func set(type: FilterType, searchString: String = "") {
    if FilterType.selectables.contains(type) {
      self.type = type
      needDb = false
      keywords = []
      let cal = Calendar.current
      switch type {
      case .月日:
        value = cal.component(.month, from: originDate) * 100 +
          cal.component(.day, from: originDate)
      case .週:
        value = DiaryManager.weekNumber(of: originDate) * 10 +
          cal.component(.weekday, from: originDate)
      case .日:
        value = cal.component(.day, from: originDate)
      case .曜日:
        value = cal.component(.weekday, from: originDate)
      case .検索:
        parseSearchText(searchString: searchString)
      default:
        value = Int(DiaryManager.dateFormatter.string(from: originDate))!
      }
    }
  }

  /// 入力された検索文字列から、実際に使用するフィルタの内容を得る
  ///
  /// - parameter searchString: 検索文字列
  private func parseSearchText(searchString: String) {
    let parts = searchString.components(separatedBy: .whitespaces)
    let first = parts[0]
    if let value = Int(first) {
      self.value = value
      if value > 10000000 {
        type = .年月日
      } else if value > 100000 {
        type = .年月
      } else if value > 1231 {
        type = .年
      } else if value > 100 {
        type = .月日
      } else {
        type = .日
      }
      keywords = Array(parts.dropFirst())
    } else if first.prefix(1) == "@", let value = Int(first.suffix(first.count - 1)) {
      self.value = value
      if value > 10 {
        type = .週
      } else {
        type = .曜日
      }
      keywords = Array(parts.dropFirst())
    } else {
      keywords = parts
    }
    needDb = keywords.count > 0
    for (index, keyword) in keywords.enumerated() {
      if keyword == "*" {
        keywords.remove(at: index)
        break
      }
    }
  }
  
  /// 検索の起点を当日にする
  /// - description:
  /// reset, movePrev, moveNext は、インターフェース上の操作が可能な月日、週、日、曜日にのみ対応する
  func reset() {
    if FilterType.selectables.contains(type) && type != .検索 {
      let cal = Calendar.current
      originDate = cal.startOfDay(for: Date())
      set(type: type)
    }
  }

  /// 検索の対象を1日後にずらす
  func moveNext() {
    if FilterType.selectables.contains(type) && type != .検索 {
      let cal = Calendar.current
      originDate = cal.date(byAdding: .day, value: 1, to: originDate)!
      switch type {
      case .月日:
        if value == 1231 {
          value = 101
        } else {
          var m = value / 100
          var d = value % 100
          if d == DiaryFilter.maxDaysOfMonth[m] {
            d = 1
            m += 1
            value = m * 100 + d
          } else {
            value += 1
          }
        }
      case .週:
        if value == 537 {
          value = 11
        } else {
          var wn = value / 10
          var wd = value % 10
          if wd == 7 {
            wd = 1
            wn += 1
            value = wn * 10 + wd
          } else {
            value += 1
          }
        }
      case .日:
        if value == 31 {
          value = 1
        } else {
          value += 1
        }
      case .曜日:
        if value == 7 {
          value = 1
        } else {
          value += 1
        }
      default:
        break
      }
    }
  }

  /// 検索の対象を1日前にずらす
  func movePrev() {
    if FilterType.selectables.contains(type) && type != .検索 {
      let cal = Calendar.current
      originDate = cal.date(byAdding: .day, value: -1, to: originDate)!
      switch type {
      case .月日:
        if value == 101 {
          value = 1231
        } else {
          var m = value / 100
          var d = value % 100
          if d == 1 {
            m -= 1
            d = DiaryFilter.maxDaysOfMonth[m]
            value = m * 100 + d
          } else {
            value -= 1
          }
        }
      case .週:
        if value == 11 {
          value = 537
        } else {
          var wn = value / 10
          var wd = value % 10
          if wd == 1 {
            wd = 7
            wn -= 1
            value = wn * 10 + wd
          } else {
            value -= 1
          }
        }
      case .日:
        if value == 1 {
          value = 31
        } else {
          value -= 1
        }
      case .曜日:
        if value == 1 {
          value = 7
        } else {
          value -= 1
        }
      default:
        break
      }
    }
  }
  
  /// 条件に合致する日付群を抽出する
  ///
  /// - returns: 条件に合致する(記事が空の）日付群
  func listDates() -> [Entry] {
    let cal = Calendar.current
    var comps = DateComponents()
    switch type {
    case .年:
      comps.year = value
      comps.month = 1
      comps.day = 1
      let from = cal.date(from: comps)!
      let to = cal.date(byAdding: .year, value: 1, to: from)!
      return listDatesPeriod(from: from, to: to)
    case .年月:
      comps.year = value / 100
      comps.month = value % 100
      comps.day = 1
      let from = cal.date(from: comps)!
      let to = cal.date(byAdding: .month, value: 1, to: from)!
      return listDatesPeriod(from: from, to: to)
    case .年月日:
      comps.year = value / 10000
      let md = value % 10000
      comps.month = md / 100
      comps.day = md % 100
      let origin = cal.date(from: comps)!
      // 年月日が指定された場合、前後10日＋指定日の21日を選択する
      let from = cal.date(byAdding: .day, value: -10, to: origin)!
      let to = cal.date(byAdding: .day, value: 11, to: origin)!
      return listDatesPeriod(from: from, to: to)
    case .月日:
      return listDatesMD()
    case .週:
      return listDatesWE()
    case .日:
      return listDatesD()
    case .曜日:
      comps.weekday = value
    default:
      comps.hour = 6
    }
    
    var results: [Entry] = []
    let startDate = cal.date(byAdding: .day, value: 1, to: originDate)!
    
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
  ///
  /// - returns: 条件に合致する日付群
  private func listDatesMD() -> [Entry] {
    var results: [Entry] = []
    let cal = Calendar.current
    var comps = DateComponents()
    comps.day = value % 100
    comps.month = value / 100
    let startDate = cal.date(byAdding: .day, value: 1, to: originDate)!
    
    var target = cal.component(.year, from: originDate)
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
  ///
  /// - returns: 条件に合致する日付群
  private func listDatesD() -> [Entry] {
    var results: [Entry] = []
    let cal = Calendar.current
    var comps = DateComponents()
    comps.day = value
    let startDate = cal.date(byAdding: .day, value: 1, to: originDate)!
    
    var target = cal.component(.year, from: originDate) * 100 + cal.component(.month, from: originDate)
    let currentValue = target
    cal.enumerateDates(startingAfter: startDate, matching: comps, matchingPolicy: .nextTime, repeatedTimePolicy: .first, direction: .backward) { (date, match, stop) in
      if let date = date {
        if date < earliestDate {
          stop = true
          return
        }
        if match {
          if target == currentValue {
            // moveNext/Prev で存在しない日を通過すると実際の日付firstDateがずれるので補正
            originDate = date
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
  ///
  /// - returns: 条件に合致する日付群
  private func listDatesWE() -> [Entry] {
    let cal = Calendar.current
    
    // 検索対象週を確定する
    let wn = value / 10
    let wd = value % 10
    
    // 検索を実行する
    // enumerateDates仕様：
    // comps.weekOfYear と comps.weekday 両方は指定できない
    // （comps.weekOfYear を指定すると、startingAfter の曜日で検索される）
    // comps.weekOfYearに53を指定すると、翌年の第1週ではない本当の53週の日付しか返ってこない
    // ⇒ 第1週で検索し、前週が53週だったら前週の日付に訂正
    // startingAfterの週番号とcomps.weekOfYear が異なっているとstartingAfterの曜日が無視され、
    // callbackには日曜日の日付が渡されてくる ⇒ startingAfter が本当の53週だったら曜日分シフト
    var results: [Entry] = []
    var comps = DateComponents()
    if wn == 53 {
      comps.weekOfYear = 1
    } else {
      comps.weekOfYear = wn
    }
    let fwn = cal.component(.weekOfYear, from: originDate)
    let fwd = cal.component(.weekday, from: originDate)
    var startDate = originDate
    var shift = 0
    if fwn != comps.weekOfYear {
      // 開始日と指定の週番号が一致しない場合は、検索結果は日曜なので、shift分進める
      shift = wd - 1
    } else {
      if fwd != wd {
        startDate = cal.date(byAdding: .day, value: wd - fwd, to: originDate)!
      }
      // 開始日と週番号が一致していれば、開始日の曜日で検索されるが、開始日自体は含まないので
      // 開始日を予め登録しておく
      results.append(Entry(date: startDate, weekNumber: wn))
    }
    
    cal.enumerateDates(startingAfter: startDate, matching: comps, matchingPolicy: .nextTimePreservingSmallerComponents, repeatedTimePolicy: .first, direction: .backward) { (date, match, stop) in
      if var date = date {
        if date < earliestDate {
          stop = true
          return
        }
        if shift > 0 {
          date = cal.date(byAdding: .day, value: shift, to: date)!
        }
        if wn == 53 {
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
  
  /// ある期間に含まれる日付群を抽出する
  ///
  /// - parameter from: 開始日
  /// - parameter to: 終了日＋1
  /// - returns: 指定の期間に含まれる日付群
  private func listDatesPeriod(from: Date, to: Date) -> [Entry] {
    var results: [Entry] = []
    let cal = Calendar.current
    var comps = DateComponents()
    comps.hour = 6
    
    cal.enumerateDates(startingAfter: to, matching: comps, matchingPolicy: .strict, repeatedTimePolicy: .first, direction: .backward) { (date, match, stop) in
      if let date = date {
        if date < from {
          stop = true
          return
        }
        results.append(Entry(date: date))
      }
    }
    return results
  }
  
  /// DBのレコードから指定の条件に合致したレコードを抽出する
  ///
  /// - parameter data: レコード
  /// - returns: 条件に合致するレコード
  func applyTo(data: Results<DBEntry>) -> Results<DBEntry> {
    var filtered: Results<DBEntry>
    switch type {
    case .年, .年月, .年月日:
      filtered = data.filter("date BEGINSWITH %@", String(value))
    case .月日, .日:
      filtered = data.filter("date ENDSWITH %@", String(value))
    case .週:
      filtered = data.filter("wn == %@ AND wd == %@", value / 10, value % 10)
    case .曜日:
      filtered = data.filter("wd == %@", value)
    default:
      filtered = data
    }
    for keyword in keywords {
      filtered = filtered.filter("text CONTAINS %@", keyword)
    }
    return filtered
  }
}

