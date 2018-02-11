//
//  ViewController.swift
//  Diary
//
//  Created by KO on 2017/11/20.
//  Copyright © 2017年 KO. All rights reserved.
//

import UIKit

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
    let tapGR = UITapGestureRecognizer(target: self, action: #selector(searchLabelTapped(_:)))
    tapGR.numberOfTapsRequired = 2
    searchLabel.addGestureRecognizer(tapGR)
    
    dm = DiaryManager()
    // dm.insertData()
    
    dm.delegate = self
    
    let earliestDateString = UserDefaults.standard.string(forKey: "earliestDate") ?? "19980701"
    dm.filter.earliestDate = DiaryManager.dateFormatter.date(from: earliestDateString)!
    dm.searchString = UserDefaults.standard.string(forKey: "search") ?? ""
    
    let filterString = UserDefaults.standard.string(forKey: "filter") ?? "月日"
    dm.filterType = FilterType(rawValue: filterString)!

    update()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  @IBAction func conditionButtonTapped(_ sender: Any) {
    let alert = UIAlertController(title:"百年日記", message: "表示方法を選択してください", preferredStyle: UIAlertControllerStyle.actionSheet)
    for filter in FilterType.selectables {
      let action = UIAlertAction(title: filter.rawValue, style: UIAlertActionStyle.default, handler: { (action: UIAlertAction!) in
        self.dm.filterType = filter
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
  
  @objc func searchLabelTapped(_ sender: Any) {
    dm.resetDate()
    update()
  }
  
  private func update() {
    conditionButton.setTitle(dm.filterType.rawValue, for: .normal)
    conditionButton.setTitle(dm.filterType.rawValue, for: .highlighted)
    if dm.filterType != .検索 {
      searchLabel.text = dm.filter.valueString
      searchBar.isHidden = true
      dateView.isHidden = false
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
    cell.render(entry: entries[indexPath.row])
    return cell
  }
}

extension MainViewController: UITableViewDelegate {
//  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//    <#code#>
//  }
  
}

extension MainViewController: UISearchBarDelegate {
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    if let searchText = searchBar.text {
      dm.searchString = searchText
      dm.filterType = .検索
    }
  }
}

extension MainViewController: DiaryManagerDelegate {
  func entriesBeginLoading() {
  }
  
  func entriesEndLoading(entries: [Entry]) {
    self.entries = entries
    tableView.reloadData()
  }
}

