//
//  EntryViewController.swift
//  Diary
//
//  Created by KO on 2018/02/17.
//  Copyright © 2018年 KO. All rights reserved.
//

import UIKit

/// 個々の記事を表示するビュー
class EntryViewController: UICollectionViewController {
  
  /// タイトル
  @IBOutlet weak var entryTitle: UINavigationItem!
  
  /// ナビゲーションバーの左ボタン
  @IBOutlet weak var leftButton: UIBarButtonItem!
  
  /// ナビゲーションバーの右ボタン
  @IBOutlet weak var rightButton: UIBarButtonItem!
  
  /// 左ボタン（＜/キャンセル）タップ時
  @IBAction func leftButtonTapped(_ sender: Any) {
    if isEditable && !isNew {
      initializeData()
      isEditable = false
    } else {
      performSegue(withIdentifier: "HideEntryDetail", sender: self)
    }
  }
  
  /// 右ボタン（編集/完了）タップ時
  @IBAction func rightButtonTapped(_ sender: Any) {
    if isEditable {
      var text = ""
      // 何故かtetxCell が nilのケースがある
      if let textCell = collectionView?.cellForItem(at: IndexPath(row: 0, section: 0))
        as? EntryTextCell {
        text = textCell.textView.text
      }
      do {
        try entry.updatePhotos(addedImages: addedImages, deletedPhotos: deletedPhotos)
        try entry.updateData(text: text, photos: photos.joined(separator: ","))
        DiaryManager.shared.sync()
        updated = true
        if isNew {
          performSegue(withIdentifier: "HideEntryDetail", sender: self)
        } else {
          initializeData()
        }
      } catch {
        alert(viewController: self, message: "編集内容の保存に失敗しました")
      }
    }
    isEditable = !isEditable
  }
  
  /// 編集状態かどうか
  private var isEditable = false {
    didSet {
      if isEditable {
        leftButton.title = "キャンセル"
        rightButton.title = "完了"
      } else {
        leftButton.title = "＜"
        rightButton.title = "編集"
      }
      collectionView?.reloadData()
    }
  }
  
  /// 記事が更新されたかどうか
  var updated = false
  
  /// 新規の記事か既存の編集か
  private var isNew = false
  
  /// 写真セクションのヘッダー（＋ーのボタンを持つ）
  private weak var photoHeader: EntryPhotoHeader?
  
  /// 対象の記事の元データ
  var entry: Entry!
  
  /// 対象の記事に対する写真ディレクトリ
  private var photoDir: String!
  
  /// 本文の編集内容を保持する変数
  private var text = ""

  /// 写真の編集内容を保持する配列
  /// 写真は配列の順番通りに並ぶ、すでに登録済みの写真はファイル名（拡張子なし）のみ、
  /// 新規追加分は「add-ｎ」（nはaddedImagesの中のindex）
  private var photos: [String] = []
  
  /// 追加された写真のID（3桁の連番）とイメージの辞書
  private var addedImages: [String:UIImage] = [:]
  
  /// 削除された写真のID（3桁の連番）の配列
  private var deletedPhotos: [String] = []
  
  /// 写真のIDの最大値
  private var maxPhotoNo = 0
  
  /// インセット
  private let sectionInsets = UIEdgeInsets(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0)
  
  /// 1行あたりの写真の表示数
  private let itemsPerRow = 1
  
  // ビューのロード時に呼び出される
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupEnterForegroundEvent()

    let date = DiaryManager.dateFormatter.date(from: entry.date)!
    let cal = Calendar.current
    self.entryTitle.title = "\(cal.component(.year, from: date))年"
      + "\(cal.component(.month, from: date))月\(cal.component(.day, from: date))日"
    photoDir = DiaryManager.docDir.appending("/" + entry.date)
    initializeData()
    isNew = (entry.data == nil)
    isEditable = isNew
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    print("▷ viewDidAppear(Entry)")
  }
  
  /// アプリがフォアグラウンド化された際のイベントの待ち受けを登録する
  private func setupEnterForegroundEvent() {
    let nc = NotificationCenter.default;
    nc.addObserver(self, selector: #selector(EntryViewController.applicationWillEnterForeground),
                   name: NSNotification.Name(rawValue: "applicationWillEnterForeground"),
                   object: nil);
  }
  
  /// アプリ・フォアグラウンド化時に、クラウドとの同期を行う
  @objc func applicationWillEnterForeground() {
    print("▷ applicationWillEnterForeground(Entry)")
    PwdManager.shared.showDialog(self, completion: nil)
  }
  
  /// 編集内容を保持するデータを初期化する
  private func initializeData() {
    if let data = entry.data {
      if data.photos.count > 0 {
        photos = data.photos.components(separatedBy: ",")
        let fm = FileManager.default
        for (index, photo) in photos.enumerated() {
          maxPhotoNo = max(maxPhotoNo, Int(photo)!)
          if !fm.fileExists(atPath: filePathOf(photo)) {
            deletedPhotos.append(photo)
            photos.remove(at: index)
          }
        }
      } else {
        photos = []
      }
      text = data.text
    } else {
      photos = []
      text = ""
    }
  }
  
  /// 指定のIDの写真のファイルパスを返す
  ///
  /// - parameter photo: 写真のID
  /// - returns: その写真のイメージを保存するパス
  private func filePathOf(_ photo: String) -> String {
    return photoDir.appendingFormat("/%@.jpg", photo)
  }
  
  /// 指定の連番の写真のIDを返す
  ///
  /// - parameter no: 写真の番号
  private func photoIdOf(_ no: Int) -> String {
    return String(format: "%03d", no)
  }
  
  /// イメージピッカーを表示して追加する写真を指示させる
  public func addPhoto() {
    let imagePickerController = UIImagePickerController()
    imagePickerController.modalPresentationStyle = UIModalPresentationStyle.currentContext
    imagePickerController.allowsEditing = true
    imagePickerController.sourceType = .photoLibrary
    imagePickerController.delegate = self
    present(imagePickerController, animated:true, completion:nil)
  }
  
  /// 選択されている写真を削除する
  public func removePhoto() {
    if let indexPath = collectionView?.indexPathsForSelectedItems?[0], indexPath.section == 1 {
      let photo = photos.remove(at: indexPath.row)
      deletedPhotos.append(photo)
      addedImages.removeValue(forKey: photo)
      collectionView?.deleteItems(at: [indexPath])
      photoHeader?.updateDeleteButton()
    }
  }
  
  /// 写真が1つでも選択されているかどうかを返す
  ///
  /// -returns: 写真が1つでも選択されているかどうか
  public func isPhotoSelected() -> Bool {
    if let indexPath = collectionView?.indexPathsForSelectedItems?.first, indexPath.section == 1 {
      return true
    }
    return false
  }
}

// MARK: UICollectionViewDataSource
extension EntryViewController {
  // セクション数を返す
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 2
  }
  
  // 与えられたindexPath、kindの補助ビューを返す
  override func collectionView(_ collectionView: UICollectionView,
                               viewForSupplementaryElementOfKind kind: String,
                               at indexPath: IndexPath) -> UICollectionReusableView {
    switch kind {
    case UICollectionElementKindSectionHeader:
      let photoHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "PhotoHeader", for: indexPath) as! EntryPhotoHeader
      if indexPath.section == 1 {
        photoHeader.viewController = self
        self.photoHeader = photoHeader
        photoHeader.updateDeleteButton()
      }
      return photoHeader
    default:
      fatalError("Unexpected element kind")
    }
  }
  
  // 各セクションのアイテム数を返す
  override func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
    return section == 0 ? 1 : photos.count
  }
  
  // 与えられたindxePathのセルを返す
  override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if indexPath.section == 0 {
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: "TextCell", for: indexPath) as! EntryTextCell
      cell.textView.text = text
      cell.isEditable = isEditable
      return cell
    } else {
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: "PhotoCell", for: indexPath) as! EntryPhotoCell
      
      let photo = photos[indexPath.row]
      if let image = addedImages[photo] {
        cell.imageView.image = image
      } else {
        cell.imageView.image = UIImage(contentsOfFile: filePathOf(photo))
      }
      return cell
    }
  }
}

// MARK: UICollectionViewDelegateFlowLayout
extension EntryViewController: UICollectionViewDelegateFlowLayout {
  // セルのサイズを返す
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {
    if indexPath.section == 0 {
      let paddingSpace = sectionInsets.left * 2
      let width = collectionView.bounds.width - paddingSpace
      let font = UIFont.systemFont(ofSize: 16)
      let height = textHeight(s: text, font: font, width: width)
      return CGSize(width: width, height: height + font.lineHeight * 4)
    } else {
      let paddingSpace = sectionInsets.left * CGFloat(itemsPerRow + 1)
      let availableWidth = view.frame.width - paddingSpace
      let width = availableWidth / CGFloat(itemsPerRow)
      return CGSize(width: width, height: width)
    }
  }
  
  /// 与えれれた条件の複数行文字列の必要高さを返す
  ///
  /// - parameter s: 文字列
  /// - parameter font: フォント
  /// - parameter width: 文字列の幅
  /// - returns: 文字列の必要高さ
  private func textHeight(s: String, font: UIFont, width: CGFloat) -> CGFloat {
    let str: NSString = NSString(string: s)
    let size: CGSize = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
    let att: [NSAttributedStringKey: Any] = [NSAttributedStringKey.font: font]
    
    let rect: CGRect = str.boundingRect(with: size, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: att, context: nil)
    return rect.height
  }
  
  // ヘッダービューのサイズを返す
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
    let width = collectionView.bounds.width
    let height = (!isEditable || section == 0) ? 0 : 50
    return CGSize(width: width, height: CGFloat(height))
  }

  // 各セクションのインセットを返す
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      insetForSectionAt section: Int) -> UIEdgeInsets {
    return sectionInsets
  }
  
  // 各セクションの行間隔を返す
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return sectionInsets.left
  }
  
  // 指定のセルが選択可能かどうかを返す
  override func collectionView(_ collectionView: UICollectionView,
                               shouldSelectItemAt indexPath: IndexPath) -> Bool {
    return isEditable && indexPath.section == 1
  }
  
  // 指定のセルが選択された直後に呼び出される
  override func collectionView(_ collectionView: UICollectionView,
                               didSelectItemAt indexPath: IndexPath) {
    photoHeader?.updateDeleteButton()
  }
  
  // 指定のセルの選択が解除された直後に呼び出される
  override func collectionView(_ collectionView: UICollectionView,
                               didDeselectItemAt indexPath: IndexPath) {
    photoHeader?.updateDeleteButton()
  }

  // 与えれれたセルが移動可能かどうかを返す
  override func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
    return isEditable && indexPath.section == 1
  }
  
  // originalIndexPathから移動されてきたアイテムが、proposedIndexPathで指定されたアイテムの前に挿入しようとしているが
  // それで良いかを、挿入可能な位置のindexPathを言う形で返す
  override func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveFromItemAt originalIndexPath: IndexPath, toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
    return proposedIndexPath.section == 0 ? IndexPath(row: 0, section: 1) : proposedIndexPath
  }
  
  // セルがドラッグ移動された直後に呼び出される
  override func collectionView(_ collectionView: UICollectionView,
                               moveItemAt sourceIndexPath: IndexPath,
                               to destinationIndexPath: IndexPath) {
    let photo = photos.remove(at: sourceIndexPath.row)
    photos.insert(photo, at: destinationIndexPath.row)
    if let selected = collectionView.indexPathsForSelectedItems?.first, selected == sourceIndexPath {
      collectionView.selectItem(at: destinationIndexPath, animated: true, scrollPosition: .centeredVertically)
    }
  }
}

// MARK: UIImagePickerControllerDelegate
extension EntryViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  // ライブラリーから写真を選択した後呼び出される
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    let image = info[UIImagePickerControllerOriginalImage] as! UIImage
    maxPhotoNo += 1
    let id = photoIdOf(maxPhotoNo)
    addedImages[id] = image
    photos.append(id)
    let indexPath = IndexPath(row: photos.count - 1, section: 1)
    collectionView?.insertItems(at: [indexPath])
    photoHeader?.updateDeleteButton()
    dismiss(animated: true, completion: nil)
  }
}

