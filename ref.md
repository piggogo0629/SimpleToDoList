#Simple ToDo List iOS App

##簡短說明

- 這是一個練習一些功能的的小App，說明如下：
	- 可以新增 / 移除 task 記錄
	- 使用 sheetsu.com 當作 server side，欄位有：datetime, task detail, isFinish 這 3 個

- App 上的實作有：
  - 列表方式顯示 task 記錄 
  - 可以在 App 新增 task 記錄
  - 使用 local DB 儲存資料
  - offline 時可以看到 server download 的 task 記錄
  - 如果在 offline 時新增 / 刪除 task 記錄，只要在 online 時就會將新增 / 刪除的 task 紀錄同步上傳到 server side


- 待接續完成的部份：
  - search and edit 功能
  
##library & 參考資料

> ###Mobile Local Database : Realm

- Ref.
  1. [官方網站文件說明](https://realm.io/docs/)
  2. [教學文章一](http://www.appcoda.com/realm-database-swift/)
  3. [教學文章二](http://swift.gg/2015/12/08/building-a-todo-app-using-realm-and-swift/index.html)

- 疑難雜症部份
  1. swift realm::IncorrectThreadException問題     
     - [ref.1](http://stackoverflow.com/questions/40201917/swift-realmincorrectthreadexception-realm-accessed-from-incorrect-thread)
  2. Auto increment ID in Realm, Swift 3.0
     -  [ref.1](http://stackoverflow.com/questions/39579025/auto-increment-id-in-realm-swift-3-0)
     -  [ref.2](http://stackoverflow.com/questions/26252432/how-do-i-set-a-auto-increment-key-in-realm)
  3. How to find my realm file?
     -  [ref.1](http://stackoverflow.com/questions/28465706/how-to-find-my-realm-file)
  4. Change Values without affecting stored objects
     -  [ref.1](http://stackoverflow.com/questions/37656099/change-values-without-affecting-stored-objects-realm-swift) + 第3點的ref.
  

> ###Detecting Network Connectivity : use Reachibility

- **這次App我採用的是swift版本的 3rd library : [Reachability.swift](https://github.com/ashleymills/Reachability.swift
)**

- 一般的Reachibility操作流程：

  1. 下載Reachibility (真正需要的是.h&.m檔案)，[下載網址](https://developer.apple.com/library/content/samplecode/Reachability/Listings/)
  2.  將.h&.m檔案加入到project中,會產生Bridging-Header.h，接著在裡面加上#import "Reachability.h" ( 即把將要加入的objective-c檔案寫在bridging-header中 )
  3. 初始化 Reachibility 物件
```
let reachability = Reachability(hostName: "www.apple.com")
```

  4. 有無連接網路 :

  ```
// 用reachability.currentReachabilityStatus().rawValue 判斷
if let currentStatus = reachability?.currentReachabilityStatus() {
	if currentStatus.rawValue == 0 {
		//NotReachable : 沒有連接網路
                
	} else {
		//有網路
                
	}
}
  ```
- Reachibility : networking 狀態變化通知：
   1. startNotifier
   2. addObserver
   3. 接收notification

- [ref.](http://stackoverflow.com/questions/27310465/detecting-network-connectivity-changes-using-reachability-nsnotification-and-ne)

> ### Networking Library : Alamofire

- [github連結](https://github.com/Alamofire/Alamofire)



