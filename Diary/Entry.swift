//
//  Entry.swift
//  Diary
//
//  Created by KO on 2017/11/22.
//  Copyright © 2017年 KO. All rights reserved.
//

import Foundation
import RealmSwift
import CloudKit
import UIKit

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
    let isDeleted = text.count == 0 && photos.count == 0
    let realm = try Realm()
    try realm.write {
      var target: DBEntry
      if let data = data {
        target = data
      } else {
        if isDeleted {
          return
        }
        target = DBEntry()
        target.date = date
        target.wn = wn
        target.wd = wd
      }
      target.text = text
      target.photos = photos
      target.modified = Date()
      target.deleted = isDeleted
      if data == nil {
        realm.add(target)
        data = target
      }
    }
  }

  /// 写真データを更新する
  ///
  /// - parameter addedImage: 追加されたイメージのマップ
  /// - parameter deletedPhotos: 削除された写真のIDの配列
  /// - throws: DBへの保存に失敗した場合、新規イメージの保存に失敗した場合
  func updatePhotos(addedImages: [String:UIImage], deletedPhotos: [String]) throws {
    let photoDir = DiaryManager.docDir.appendingFormat("/%@", date)
    let realm = try Realm()
    let fm = FileManager.default
    try realm.write {
      
      for photo in deletedPhotos {
        // DBデータは、クラウドへ伝搬する必要があるため論理削除
        updateDBPhoto(realm: realm, id: photo, deleted: true)
        
        // ファイルは物理削除
        try? fm.removeItem(atPath: photoDir.appendingFormat("/%@.jpg", photo))
      }
      
      for added in addedImages {
        let path = photoDir.appendingFormat("/%@.jpg", added.key)
        
        // 画像は長辺2048pixel、データサイズ1M以下にする
        let data = added.value.data(maxLength: 2048, maxByte: 1024 * 1024)
        if !fm.fileExists(atPath: photoDir, isDirectory: nil) {
          try fm.createDirectory(atPath: photoDir,
                                 withIntermediateDirectories: false, attributes: nil)
        }
        try data.write(to: URL(fileURLWithPath: path))
        updateDBPhoto(realm: realm, id: added.key)
      }
    }
  }
  
  private func updateDBPhoto(realm: Realm, id: String, deleted: Bool = false) {
    let data = DBPhoto()
    data.id = date + id
    data.deleted = deleted
    data.modified = Date()
    realm.add(data, update: true)
  }
  
  private func resizeImage(image: UIImage, maxLength: Int, maxByte: Int) -> Data {
    print("image.size:\(image.size)")
    let size = image.size
    let length = max(size.width, size.height)
    var scale = min(1.0, Double(maxLength) / Double(length))
    var data: Data = Data()
    while true {
      if (scale < 1.0) {
        let newSize = CGSize(width: Int(Double(size.width) * scale),
                           height: Int(Double(size.height) * scale))
        UIGraphicsBeginImageContext(newSize)
        image.draw(in: CGRect(origin: CGPoint.zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        data = UIImageJPEGRepresentation(newImage, 0.8)!
        print("resize to:\(newSize) -> \(data.count / 1024)KB")
      } else {
        data = UIImageJPEGRepresentation(image, 0.8)!
        print("-> \(data.count / 1024)KB")
      }
      if data.count < maxByte {
        print("")
        return data
      }
      // 単純な計算値だと収束しない恐れがあるので、1割縮小
      let factor = sqrt(Double(maxByte) / Double(data.count)) / 1.1
      scale *= factor
    }
  }
}

extension UIImage {
  func data(maxLength: Int, maxByte: Int) -> Data {
    print("image.size:\(size)")
    let length = max(size.width, size.height)
    var scale = min(1.0, Double(maxLength) / Double(length))
    var data: Data = Data()
    while true {
      if (scale < 1.0) {
        let newSize = CGSize(width: Int(Double(size.width) * scale),
                             height: Int(Double(size.height) * scale))
        UIGraphicsBeginImageContext(newSize)
        draw(in: CGRect(origin: CGPoint.zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        data = UIImageJPEGRepresentation(newImage, 0.8)!
        print("resize to:\(newSize) -> \(data.count / 1024)KB")
      } else {
        data = UIImageJPEGRepresentation(self, 0.8)!
        print("-> \(data.count / 1024)KB")
      }
      if data.count < maxByte {
        print("")
        return data
      }
      // 単純な計算値だと収束しない恐れがあるので、1割縮小
      let factor = sqrt(Double(maxByte) / Double(data.count)) / 1.1
      scale *= factor
    }
  }
}

