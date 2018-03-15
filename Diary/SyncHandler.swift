//
//  SyncHandler.swift
//  Diary
//
//  Created by KO on 2018/03/01.
//  Copyright © 2018年 KO. All rights reserved.
//

import Foundation

import RealmSwift
import CloudKit
import UIKit

/// 同期時の環境
struct SyncContext {
  /// 前回同期した日付
  var lastSync: Date
  
  /// クラウド側のデータベース
  let database: CKDatabase
  
  /// ローカルのデータベース
  let realm: Realm
}

/// 同期中の状態
enum SyncState {
  /// まだ始まっていない
  case notStarted
  
  /// ダウンロード処理開始済み
  case startDownloading
  
  /// ダウンロード処理終了
  case endDownloading
  
  /// アップロード処理開始済み
  case startUploading
  
  /// アップロード処理終了
  case endUploading
  
  /// エラー発生
  case errorOccured
}

/// ローカルとクラウドの同期を処理するクラス
class SyncHandler {
  /// 同期の環境
  var context: SyncContext
  
  /// 写真テーブルの同期処理
  private var photoSync: TableSyncHandler<DBPhoto>?
  
  /// 記事テーブルの同期処理
  private var entrySync: TableSyncHandler<DBEntry>?
  
  /// クラウドのデータ保存域
  var container: CKContainer
  
  /// コンストラクタ
  init() {
    container = CKContainer(identifier: "iCloud.kj.okzk.Diary")
    let database = container.privateCloudDatabase
    let realm = try! Realm()
    let lastSync = (UserDefaults.standard.object(forKey: "lastSync") as? Date) ?? Date.distantPast
    context = SyncContext(lastSync: lastSync, database: database, realm: realm)
  }
  
  /// 同期を開始する
  func startSync() {
    if photoSync != nil || entrySync != nil {
      return
    }
    
    photoSync = TableSyncHandler(context: context)
    entrySync = TableSyncHandler(context: context)

    photoSync?.downloadRecords(completionHandler: downloadCompleted)
    entrySync?.downloadRecords(completionHandler: downloadCompleted)
  }
  
  /// ダウンロード処理終了時に呼び出される処理
  func downloadCompleted() {
    if photoSync!.state == .endDownloading && entrySync!.state == .endDownloading {
      photoSync!.uploadRecords(completionHandler: uploadCompleted)
      entrySync!.uploadRecords(completionHandler: uploadCompleted)
    } else if photoSync!.state != .startDownloading && entrySync!.state != .startDownloading {
      initializeSync()
    }
  }
  
  /// アップロード処理終了時に呼び出される処理
  func uploadCompleted() {
    if photoSync!.state == .endUploading && entrySync!.state == .endUploading {
      context.lastSync = Date()
      UserDefaults.standard.setValue(context.lastSync, forKey: "lastSync")
    } else if photoSync!.state == .startUploading || entrySync!.state == .startUploading {
      return
    }
    initializeSync()
  }
  
  /// 同期処理を初期化する
  func initializeSync() {
    photoSync = nil
    entrySync = nil
  }
}

/// テーブル毎の同期処理を行うクラス
class TableSyncHandler<T: SyncronizableObject> {
  /// 前回同期以降にローカルで追加・更新されたデータ
  var localUpdates: [CKRecord] = []
  
  /// 前回同期以降にローカルで削除されたデータのID
  var localDeletes: [CKRecordID] = []
  
  /// 同期の状態
  var state: SyncState
  
  /// 同期の環境
  let context: SyncContext
  
  /// コンストラクタ、与えられた環境の同期処理オブジェクトを得る
  ///
  /// - parameter context: 同期の環境
  init(context: SyncContext) {
    self.context = context
    
    let localData = context.realm.objects(T.self).filter("modified > %@", context.lastSync)
    for data in localData {
      if data.deleted {
        localDeletes.append(data.recordID)
      } else {
        localUpdates.append(data.record)
      }
    }
    state = .notStarted
  }
  
  /// クラウドから前回同期以降に更新されたデータを得る
  func downloadRecords(completionHandler: @escaping () -> (), inputCursor: CKQueryCursor? = nil) {
    let operation: CKQueryOperation
    state = .startDownloading
    
    // We may be starting a new query or continuing a previous one if there are many results
    if let cursor = inputCursor {
      operation = CKQueryOperation(cursor: cursor)
    } else {
      let predicate = NSPredicate(format: "modificationDate > %@", context.lastSync as CVarArg)
      let query = CKQuery(recordType: T.recordType, predicate: predicate)
      operation = CKQueryOperation(query: query)
    }
    
    operation.queryCompletionBlock = { [weak self] cursor, error in
      if let error = error {
        self?.handleOperationError(error: error, completionHandler: completionHandler, retry: {
          self?.downloadRecords(completionHandler: completionHandler, inputCursor: inputCursor)
        })
        return
      }

      if let cursor = cursor {
        self?.downloadRecords(completionHandler: completionHandler, inputCursor: cursor)
      } else {
        self?.state = .endDownloading
        completionHandler()
      }
    }
    
    operation.recordFetchedBlock = { [weak self] record in
      // When a note is fetched from the cloud, process it into the local database
      let modified = try? T.self.importFromCloud(record: record)
      if let modified = modified, modified {
        self?.removeModified(id: record.recordID)
      }
    }
    
    context.database.add(operation)
  }

  
  func uploadRecords(completionHandler: @escaping () -> ()) {
    let operation = CKModifyRecordsOperation(recordsToSave: localUpdates, recordIDsToDelete: localDeletes)
    operation.savePolicy = .changedKeys
    state = .startUploading
    
    operation.modifyRecordsCompletionBlock = { [weak self] _, _, error in
      if let error = error {
        self?.handleOperationError(error: error, completionHandler: completionHandler, retry: {
          self?.uploadRecords(completionHandler: completionHandler)
        })
        return
      }
      self?.state = .endUploading
      completionHandler()
    }
    
    context.database.add(operation)
  }
  
  private func handleOperationError(error: Error, completionHandler: @escaping () -> (),
                                    retry: @escaping () -> ()) {
    if let ckerror = error as? CKError,
        let retryAfter = ckerror.userInfo[CKErrorRetryAfterKey] as? NSNumber {
      DispatchQueue.main.asyncAfter(deadline: .now() + retryAfter.doubleValue) {
        retry()
      }
    } else {
      print(error)
      if let ckerror = error as? CKError {
        print(ckerror.userInfo)
      }
      state = .errorOccured
      completionHandler()
    }
  }

  private func removeModified(id: CKRecordID) {
    for (index, element) in localUpdates.enumerated() {
      if element.recordID == id {
        localUpdates.remove(at: index)
        break
      }
    }
    for (index, element) in localDeletes.enumerated() {
      if element == id {
        localDeletes.remove(at: index)
        break
      }
    }
  }
}
