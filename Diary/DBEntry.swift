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

/// CloudKitとの同期をサポートしたオブジェクト
class SyncronizableObject: Object {
  
  /// 与えられたCKRecordから、Realm用のオブジェクトを返す
  ///
  /// - parameter record: クラウドから取得したCKRecord
  /// - returns: recordに対応するオブジェクト
  class func from(record: CKRecord) -> Self? {
    return nil
  }
  
  /// 自分自身のデータ型に対応するCloudKit上のレコードタイプ
  class var recordType: String {
    return "Object"
  }
  
  /// 自分自身と対応するCloudKit上のレコードのID
  var recordID: CKRecordID {
      return CKRecordID(recordName: "0000")
  }
  
  /// 自分自身と対応するCloudKit上のレコード
  var record: CKRecord {
      return CKRecord(recordType: "Object", recordID: recordID)
  }
  /// 削除されたどうかのフラグ、実際の削除は削除フラグの同期後に行う
  @objc dynamic var deleted = false
  
  /// 最終更新日時（クライアント上での更新日時）
  @objc dynamic var modified = Date()
  
  /// CloudKitから得られたレコードによってデータが更新された際に呼び出される
  func updateFromCloud(record: CKRecord) {
  }
  
  /// CloudKitから得られたレコードによってデータが削除された際に呼び出される
  func deleteFromCloud(record: CKRecord) {
  }
  
  /// クラウドから得られたレコードをRealmに反映する
  ///
  /// - parameter record: クラウドから得られたレコード
  /// - returns: ローカルデータの更新が行われた場合にtrue、行われなければfalse
  class func importFromCloud(record: CKRecord) throws -> Bool {
    let object = from(record: record)!
    guard let primaryKey = primaryKey(),
        let primaryKeyValue = object.value(forKey: primaryKey) else {
      fatalError("主キーのないデータ")
    }
    
    let realm = try! Realm()
    
    if let existingObject = realm.object(ofType: self, forPrimaryKey: primaryKeyValue) {
      // 対応するオブジェクトがすでにDBに存在する場合
      if object.modified >= existingObject.modified {
        // ダウンロードしたオブジェクトの更新日時の方が、DBのオブジェクトより新しい場合
        // （ダウンロードのみ成功し、アップロードに失敗した場合、次の回に同じレコードを再度ダウンロードしてくるが、
        // 　前回のものをアップロードさせないため等号もつける）
        realm.beginWrite()
        if object.deleted {
          // クラウド側が削除されていたら物理削除
          existingObject.deleteFromCloud(record: record)
          realm.delete(existingObject)
          slog("\(self.recordType) \(primaryKeyValue) deleted")
        } else {
          // 削除以外は更新
          realm.add(object, update: true)
          object.updateFromCloud(record: record)
          slog("\(self.recordType) \(primaryKeyValue) modified")
        }
        try realm.commitWrite()
        return true
      }
    } else {
      // 対応するオブジェクトが存在しない、すなわち追加
      if !object.deleted {
        realm.beginWrite()
        realm.add(object)
        object.updateFromCloud(record: record)
        try realm.commitWrite()
        slog("\(self.recordType) \(primaryKeyValue) added")
      }
    }
    return false
  }
}


/// DBのEntryレコードを表すクラス、同期可能オブジェクトを継承する
class DBEntry: SyncronizableObject {
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
  
  // 主キーを返す、主キーは日付
  override static func primaryKey() -> String? {
    return "date"
  }
  
  // レコードタイプを返す
  override static var recordType: String {
    return "Entry"
  }
  
  // レコードIDを返す
  override var recordID: CKRecordID {
    return CKRecordID(recordName: date)
  }
  
  // レコードを返す
  override var record: CKRecord {
    let record = CKRecord(recordType: DBEntry.recordType, recordID: recordID)
    
    record["wn"] = wn as CKRecordValue
    record["wd"] = wd as CKRecordValue
    record["text"] = text as CKRecordValue
    record["photos"] = photos as CKRecordValue
    record["deleted"] = (deleted ? 1 : 0) as CKRecordValue
    record["modified"] = modified as CKRecordValue
    return record
  }
  
  // レコードからオブジェクトを生成する
  override static func from(record: CKRecord) -> DBEntry? {
    let entry = DBEntry()
    let date = record.recordID.recordName
    guard let wn = record["wn"] as? Int8,
      let wd = record["wd"] as? Int8,
      let text = record["text"] as? String,
      let photos = record["photos"] as? String,
      let deleted = record["deleted"] as? Int,
      let modified = record["modified"] as? Date else {
        return nil
    }
    entry.date = date
    entry.wn = wn
    entry.wd = wd
    entry.text = text
    entry.photos = photos
    entry.deleted = deleted == 1
    entry.modified = modified
    return entry
  }
}

/// DBのPhotoレコードを表すクラス、Realmのオブジェクトを継承する
class DBPhoto: SyncronizableObject {
  /// 日付（yyyyMMdd形式の文字列）+ 連番3桁
  @objc dynamic var id = ""
  
  // 主キーを返す、主キーは日付＋連番
  override static func primaryKey() -> String? {
    return "id"
  }
  
  // レコードタイプを返す
  override static var recordType: String {
    return "Photo"
  }
  
  // レコードIDを返す
  override var recordID: CKRecordID {
    return CKRecordID(recordName: id)
  }
  
  // レコードを返す
  override var record: CKRecord {
    let path = DiaryManager.docDir.appendingFormat("/%@/%@.jpg", String(id.prefix(8)), String(id.dropFirst(8)))
    let record = CKRecord(recordType: DBPhoto.recordType, recordID: recordID)
    
    record["deleted"] = (deleted ? 1 : 0) as CKRecordValue
    record["modified"] = modified as CKRecordValue
    record["photo"] = CKAsset(fileURL: URL(fileURLWithPath: path))
    return record
  }
  
  // レコードからオブジェクトを生成する
  override static func from(record: CKRecord) -> DBPhoto? {
    let photo = DBPhoto()
    let id = record.recordID.recordName
    guard let deleted = record["deleted"] as? Int,
      let modified = record["modified"] as? Date else {
        return nil
    }
    photo.id = id
    photo.deleted = deleted == 1
    photo.modified = modified
    return photo
  }
  
  // クラウドからダウンロードされたレコードでオブジェクトが更新されたときに呼び出される
  override func updateFromCloud(record: CKRecord) {
    let id = record.recordID.recordName
    let datePath = DiaryManager.docDir.appendingFormat("/%@", String(id.prefix(8)))
    let path = datePath.appendingFormat("/%@.jpg", String(id.suffix(3)))
    let asset = record["photo"] as! CKAsset
    let fm = FileManager.default
    if fm.fileExists(atPath: datePath) {
      if fm.fileExists(atPath: path, isDirectory: nil) {
        try? fm.removeItem(atPath: path)
      }
    } else {
      try? fm.createDirectory(atPath: datePath, withIntermediateDirectories: false, attributes: nil)
    }
    try? fm.copyItem(atPath: asset.fileURL.path, toPath: path)
  }
  
  // クラウドからダウンロードされたレコードでオブジェクトが削除されたときに呼び出される
  override func deleteFromCloud(record: CKRecord) {
    let id = record["id"] as! String
    let path = DiaryManager.docDir.appendingFormat("/%@/%@.jpg", String(id.prefix(8)), String(id.suffix(3)))
    try? FileManager.default.removeItem(atPath: path)
  }
}



