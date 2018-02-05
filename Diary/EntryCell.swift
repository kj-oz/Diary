//
//  EntryCell.swift
//  Diary
//
//  Created by KO on 2017/12/19.
//  Copyright © 2017年 KO. All rights reserved.
//

import UIKit

class EntryCell: UITableViewCell {
  
  @IBOutlet weak var year: UILabel!
  @IBOutlet weak var date: UILabel!
  @IBOutlet weak var weekday: UILabel!
  @IBOutlet weak var entryText: UILabel!
  @IBOutlet weak var photo: UIImageView!
  
  override func awakeFromNib() {
    super.awakeFromNib()
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }
  
  /// セルを描画する
  /// - Parameter entry: 対象の日記
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
    
    if let db = entry.db {
      entryText.text = db.text
      let photos = db.photos.split(separator: ",")
      if photos.count > 0 {
        photo.bounds = CGRect(x:0, y:0, width:66, height:66)
        let photoPath = DiaryManager.docDir.appendingFormat("/%@/%@.jpg", entry.date, String(photos[0]))
        photo.contentMode = .scaleAspectFill
        photo.image = UIImage(contentsOfFile: photoPath)
      }
    }
  }
}
