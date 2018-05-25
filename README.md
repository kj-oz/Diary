Diary
======================
Diaryは、日々の個人的なメモと写真を何年にも渡って記録、閲覧するためのiOS用の日記アプリケーションです。SNSの様に他のユーザーに内容を公開するような機能はなく、あくまで自分だけのプライベートな記録になります。

このソースからビルドされるアプリケーションは、Apple社のAppStoreで **百年日記** という名称で無料で配信予定です。  
　[https://itunes.apple.com/jp/app/百年日記/id1249615235?mt=8][AppStore]

画面イメージや使い方は、以下のページをご覧下さい。  
　[https://centenarian-diary.blogspot.jp/][Blogger]

### アプリケーションの特徴

* 日々の記録として文書と写真を残すことができます。
* データは、端末内とCloud上の両方に保存されます。これによりネットワークのつながっていなときにも操作可能です。
* データは端末内ではRealmというDBに保存され、Cloud上では使用している端末のAppleIDアカウントのiCloud上に保存されます。（同じAppleIDでログインしている複数の端末で、共有されます。）
* 遠い過去や未来の日付に対して記事を入力することも可能です。
* パスワードで画面を保護することが可能です。
* 日記を閲覧する際に、様々な並べ方が可能です。

### ソースコードの特徴

* 使用言語は Swift 4 です。
* コメントは全て日本語です。


### 開発環境

* 2018/5 現在、Mac 0S X 10.13.4、Xcode 9.3.1

### 使用ライブラリ

* Realm/RealmSwift
* CalculateCalendarLogic

動作環境
-----
iOS 9.0以上

ライセンス
-----
 [MIT License][MIT]. の元で公開します。  

-----
Copyright &copy; 2018 Kj Oz  

[AppStore]: https://itunes.apple.com/jp/app/百年日記/id1249615235?mt=8
[Blogger]: https://centenarian-diary.blogspot.jp
[MIT]: http://www.opensource.org/licenses/mit-license.php
