//
//  DiaryManagerTest.swift
//  Diary
//
//  Created by KO on 2018/01/19.
//  Copyright © 2018年 KO. All rights reserved.
//

import Foundation

extension DiaryManager {
  func test() {
    let cal = Calendar.current
    var comp = DateComponents()
    earliestDate = cal.date(byAdding: .year, value: -18, to: Date())!
    var entries: [Entry] = []
    
    //    filter = .月日
    //    comp.year = 2020
    //    comp.month = 2
    //    comp.day = 28
    //    firstDate = cal.date(from: comp)!
    //    setFilterValeu()
    //
    //    entries = listDates()
    //    printDates(dates: entries)
    //
    //    comp.year = 2020
    //    comp.month = 2
    //    comp.day = 29
    //    firstDate = cal.date(from: comp)!
    //    setFilterValeu()
    //
    //    entries = listDates()
    //    printDates(dates: entries)
    //
    //    filter = .日
    //    comp.year = 2020
    //    comp.month = 1
    //    comp.day = 31
    //    firstDate = cal.date(from: comp)!
    //    setFilterValeu()
    //
    //    entries = listDates()
    //    printDates(dates: entries)
    //
    //    earliestDate = cal.date(byAdding: .year, value: -1, to: Date())!
    //    filter = .曜日
    //    comp.year = 2018
    //    comp.month = 1
    //    comp.day = 1
    //    firstDate = cal.date(from: comp)!
    //    setFilterValeu()
    //
    //    entries = listDates()
    //    printDates(dates: entries)
    //
    //    filter = .なし
    //    comp.year = 2018
    //    comp.month = 1
    //    comp.day = 1
    //    firstDate = cal.date(from: comp)!
    //    setFilterValeu()
    //
    //    entries = listDates()
    //    printDates(dates: entries)
    
    filter = .週
    print("wE 2017/12/2")
    comp.year = 2017
    comp.month = 12
    comp.day = 2
    firstDate = cal.date(from: comp)!
    setFilterValeu()
    
    entries = listDates()
    printDates(dates: entries)
    
    print("wE 2017/12/31")
    comp.year = 2017
    comp.month = 12
    comp.day = 31
    firstDate = cal.date(from: comp)!
    setFilterValeu()
    
    entries = listDates()
    printDates(dates: entries)
    
    print("wE 2016/12/28")
    comp.year = 2016
    comp.month = 12
    comp.day = 28
    firstDate = cal.date(from: comp)!
    setFilterValeu()
    
    entries = listDates()
    printDates(dates: entries)
    
    print("wE 2015/12/30")
    comp.year = 2015
    comp.month = 12
    comp.day = 30
    firstDate = cal.date(from: comp)!
    setFilterValeu()
    
    entries = listDates()
    printDates(dates: entries)
    
    print("wE 2016/12/31")
    comp.year = 2016
    comp.month = 12
    comp.day = 31
    firstDate = cal.date(from: comp)!
    setFilterValeu()
    
    entries = listDates()
    printDates(dates: entries)
    
    print("wE 2017/1/1")
    comp.year = 2017
    comp.month = 1
    comp.day = 1
    firstDate = cal.date(from: comp)!
    setFilterValeu()
    
    entries = listDates()
    printDates(dates: entries)
    
    print("wE 2017/1/4")
    comp.year = 2017
    comp.month = 1
    comp.day = 4
    firstDate = cal.date(from: comp)!
    setFilterValeu()
    
    entries = listDates()
    printDates(dates: entries)
    
    print("wE 2017/1/7")
    comp.year = 2017
    comp.month = 1
    comp.day = 7
    firstDate = cal.date(from: comp)!
    setFilterValeu()
    
    entries = listDates()
    printDates(dates: entries)
    
    print("wE 2000/12/31")
    comp.year = 2000
    comp.month = 12
    comp.day = 31
    firstDate = cal.date(from: comp)!
    setFilterValeu()
    
    entries = listDates()
    printDates(dates: entries)
  }
  
  private func printDates(dates: [Entry]) {
    for date in dates {
      if date.padding {
        print("padding \(date.date)")
      } else {
        print("\(date.date)")
      }
    }
  }

}
