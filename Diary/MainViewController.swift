//
//  ViewController.swift
//  Diary
//
//  Created by KO on 2017/11/20.
//  Copyright © 2017年 KO. All rights reserved.
//

import UIKit

/// 日記アプリのメイン画面（記事の一覧）
class MainViewController: UIViewController {

  /// 条件ボタン
  @IBOutlet weak var conditionButton: UIButton!
  
  /// 検索バー
  @IBOutlet weak var searchBar: UISearchBar!
  
  /// 検索ラベル（検索対象の表示）
  @IBOutlet weak var searchLabel: UILabel!
  
  ///　テーブルビュー
  @IBOutlet weak var tableView: UITableView!
  
  /// 日付設定ビュー（検索バーと排他表示）
  @IBOutlet weak var dateView: UIView!
  
  /// 日記マネージャ
  var dm: DiaryManager!
  
  /// 検索された全記事
  var entries: [Entry] = []
  
  //var topRow = 0
  
  /// 表示する最大行数
  var maxRow = 100
  
  /// iCloudへのログインを促すダイアログを表示するかどうか
  var showPrompt = false
  
  // ビューのロード時に呼び出される
  override func viewDidLoad() {
    super.viewDidLoad()
    print("▷ viewDidLoad")

    setupEnterForegroundEvent()
    
    tableView.delegate = self
    tableView.dataSource = self
    searchBar.delegate = self
    let tapGR = UITapGestureRecognizer(target: self, action: #selector(searchLabelTapped(_:)))
    tapGR.numberOfTapsRequired = 2
    searchLabel.addGestureRecognizer(tapGR)
    
    dm = DiaryManager.shared
    
    // CloudKit にログインしているかチェック
    dm.checkCloudConnection({ status, error in
      if error != nil || status == .noAccount {
        print("▶ hasConnection: false")
        slog("Not login to iCloud")
        self.showPrompt = true
      } else {
        print("▶ hasConnection: true")
        self.dm.sync()
      }
    })
    dm.delegate = self
    // dm.insertData()
    
    // 各種設定値の読み込み
    let earliestDateString = UserDefaults.standard.string(forKey: "earliestDate") ?? "19980701"
    dm.filter.earliestDate = DiaryManager.dateFormatter.date(from: earliestDateString)!
    let filterString = UserDefaults.standard.string(forKey: "filter") ?? "月日"
    dm.filterType = FilterType(rawValue: filterString)!
    dm.searchString = UserDefaults.standard.string(forKey: "search") ?? ""

    update()
  }
  
  // 画面が表示された直後に呼び出される
  override func viewDidAppear(_ animated: Bool) {
    if showPrompt {
      // iCloudへログインするよう促す
      let alert = UIAlertController(title:"百年日記", message: "iCloudへサインインしてください。またiCloud DriveをONにしてください。", preferredStyle: UIAlertControllerStyle.alert)
      let ok = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
      alert.addAction(ok)
      self.present(alert, animated: true, completion: nil)

      showPrompt = false
    }
  }
  
  /// アプリがフォアグラウンド化された際のイベントの待ち受けを登録する
  fileprivate func setupEnterForegroundEvent() {
    let nc = NotificationCenter.default;
    nc.addObserver(self, selector: #selector(MainViewController.applicationWillEnterForeground),
                   name: NSNotification.Name(rawValue: "applicationWillEnterForeground"),
                   object: nil);
  }
  
  /// アプリ・フォアグラウンド化時に、クラウドとの同期を行う
  @objc func applicationWillEnterForeground() {
    print("▷ applicationWillEnterForeground")
    dm.sync()
  }
  
  // 条件ボタンタップ時の処理
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
  
  // 戻るボタン（日付設定ビュー）タップ時
  @IBAction func backButtonTapped(_ sender: Any) {
    dm.movePrev()
    update()
  }
  
  // 進むボタン（日付設定ビュー）タップ時
  @IBAction func forwardButtonTapped(_ sender: Any) {
    dm.moveNext()
    update()
  }
  
  // 記事詳細画面から戻ってきた
  @IBAction func backFromEntryView(_ segue: UIStoryboardSegue) {
    if let vc = (segue.source as? EntryViewController), vc.updated {
      if let indexPath = tableView.indexPathForSelectedRow {
        tableView.beginUpdates()
        tableView.reloadRows(at: [indexPath], with: .automatic)
        tableView.endUpdates()
      }
    }
  }
  
  // 日付設定ビューの日付タップ時（当日に戻す）
  @objc func searchLabelTapped(_ sender: Any) {
    dm.resetDate()
    update()
  }
  
  // segueによる移動の直前
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    let nvc = segue.destination as! UINavigationController
    
    (nvc.viewControllers[0] as! EntryViewController).entry = entries[(tableView.indexPathForSelectedRow?.row)!]
  }

  /// 日付設定バー等の表示を更新する
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
    
    UserDefaults.standard.set(dm.filterType.rawValue, forKey: "filter")
    UserDefaults.standard.set("", forKey: "search")
  }
}

// MARK: UITableViewDataSource
extension MainViewController: UITableViewDataSource {
  // 各セクションの行数を返す
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return min(entries.count, maxRow)
  }
  
  // セクション数を返す
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  // 指定の indexPath のセルを返す
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "EntryCell") as! EntryCell
    cell.render(entry: entries[indexPath.row])
    return cell
  }
}

// MARK: UITableViewDelegate
extension MainViewController: UITableViewDelegate {
  // 行選択時の処理
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    performSegue(withIdentifier: "ShowEntryDetail", sender: self)
  }
}

// MARK: UISearchBarDelegate
extension MainViewController: UISearchBarDelegate {
  // 検索ボタン押下時
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    if let searchText = searchBar.text {
      dm.searchString = searchText
      UserDefaults.standard.set(searchText, forKey: "search")
    }
  }
}

// MARK: DiaryManagerDelegate
extension MainViewController: DiaryManagerDelegate {
  // 記事の再ロードの開始
  func entriesBeginLoading() {
  }
  
  // 記事の再ロードの終了
  func entriesEndLoading(entries: [Entry]) {
    self.entries = entries
    tableView.reloadData()
  }
}

