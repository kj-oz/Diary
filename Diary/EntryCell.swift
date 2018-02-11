//
//  EntryCell.swift
//  Diary
//
//  Created by KO on 2017/12/19.
//  Copyright © 2017年 KO. All rights reserved.
//

import UIKit

/// 日記を表示するセル
class EntryCell: UITableViewCell {
  
  /// 年表示ラベル
  @IBOutlet weak var year: UILabel!
  
  /// 月日表示ラベル
  @IBOutlet weak var date: UILabel!
  
  /// 曜日表示ラベル
  @IBOutlet weak var weekday: UILabel!
  
  /// 本文のラベル
  @IBOutlet weak var entryText: UILabel!
  
  /// リストに表示されるサムネイル画像を表示するイメージビュー
  @IBOutlet weak var photo: UIImageView!
  
  override func awakeFromNib() {
    super.awakeFromNib()
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }
  
  /// セルを描画する
  ///
  /// - parameter entry: 対象の記事
  func render(entry: Entry) {
    year.text = String(entry.date.prefix(4))
    date.text = ""
    weekday.text = ""
    entryText.text = ""
    photo.bounds = CGRect(x:0, y:0, width:0, height:66)
    photo.image = nil
    backgroundColor = UIColor.white
    
    if entry.date.count == 8 {
      let date = DiaryManager.dateFormatter.date(from: entry.date)!
      let cal = Calendar.current
      self.date.text = "\(cal.component(.month, from: date))/\(cal.component(.day, from: date))"
      weekday.text = DiaryManager.weekday(of: date)
    } else if entry.date.count == 6 {
      self.date.text = "\(Int(entry.date.suffix(2))!)月"
    }
    
    if entry.padding {
      backgroundColor = UIColor.lightGray
      return
    }
    
    if let record = entry.record {
      entryText.text = record.text
      let photos = record.photos.split(separator: ",")
      if photos.count > 0 {
        photo.bounds = CGRect(x:0, y:0, width:66, height:66)
        let photoPath = DiaryManager.docDir.appendingFormat("/%@/%@.jpg", entry.date, String(photos[0]))
        photo.contentMode = .scaleAspectFill
        photo.image = UIImage(contentsOfFile: photoPath)
      }
    }
  }
}
