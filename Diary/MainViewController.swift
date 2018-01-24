//
//  ViewController.swift
//  Diary
//
//  Created by KO on 2017/11/20.
//  Copyright © 2017年 KO. All rights reserved.
//

import UIKit
import RealmSwift

class MainViewController: UIViewController {

  @IBOutlet weak var conditionButton: UIButton!
  
  @IBOutlet weak var searchBar: UISearchBar!
  
  @IBOutlet weak var searchLabel: UILabel!
  
  @IBOutlet weak var tableView: UITableView!
  
  @IBOutlet weak var dateView: UIView!
  
  var dm: DiaryManager!
  
  var entries: [Entry] = []
  
  //var topRow = 0
  
  var maxRow = 100
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.delegate = self
    tableView.dataSource = self
    searchBar.delegate = self
    
    dm = DiaryManager()
    dm.changeFilter(dm.filter) {
      self.entries = self.dm.entries
      self.tableView.reloadData()
    }
    // dm.test()
    update()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  @IBAction func conditionButtonTapped(_ sender: Any) {
    let alert = UIAlertController(title:"百年日記", message: "表示方法を選択してください", preferredStyle: UIAlertControllerStyle.actionSheet)
    for filter in DiaryFilter.allCases {
      let action = UIAlertAction(title: filter.rawValue, style: UIAlertActionStyle.default, handler: { (action: UIAlertAction!) in
        self.dm.changeFilter(filter) {
          print("Enter completionHandler")
          self.entries = self.dm.entries
          self.tableView.reloadData()
        }
        self.update()
      })
      alert.addAction(action)
    }
    
    let cancel = UIAlertAction(title: "キャンセル", style: UIAlertActionStyle.cancel, handler: {
      (action: UIAlertAction!) in
      print("キャンセル")
    })
    alert.addAction(cancel)
    self.present(alert, animated: true, completion: nil)
  }
  
  @IBAction func backButtonTapped(_ sender: Any) {
    dm.movePrev()
    update()
  }
  
  @IBAction func forwardButtonTapped(_ sender: Any) {
    dm.moveNext()
    update()
  }
  
  private func update() {
    conditionButton.setTitle(dm.filter.rawValue, for: .normal)
    conditionButton.setTitle(dm.filter.rawValue, for: .highlighted)
    if dm.filter != .検索 {
      searchLabel.text = dm.filterValueString
      searchBar.isHidden = true
      dateView.isHidden = false
//      entries = []
//      tableView.reloadData()
//      print("▶ table reloadData done")
    } else {
      searchBar.text = ""
      searchBar.isHidden = false
      dateView.isHidden = true
    }
  }
}

extension MainViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return min(entries.count, maxRow)
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "EntryCell") as! EntryCell
    let entry = entries[indexPath.row]
    let date = DiaryManager.dateFormatter.date(from: entry.date)!
    let cal = Calendar.current

    cell.year.text = "\(entry.date.prefix(4))"
    cell.date.text = "\(cal.component(.month, from: date))/\(cal.component(.day, from: date))"
    cell.weekday.text = DiaryManager.weekday(of: date)
    cell.photo.image = nil
    if let db = entry.db {
      cell.entryText.text = db.text
      let photos = db.photos.split(separator: ",")
      if photos.count > 0 {
        let docDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, false)
        let photoPath = docDir[0].appendingFormat("/%@/%@.jpg", entry.date, String(photos[0]))
        cell.photo.image = UIImage(contentsOfFile: photoPath)
      }
    } else {
      cell.entryText.text = ""
    }
    return cell
  }
}

extension MainViewController: UITableViewDelegate {
//  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//    <#code#>
//  }
  
}

extension MainViewController: UISearchBarDelegate {
  
  
}

