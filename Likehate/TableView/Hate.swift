//
//  Hate.swift
//  Likehate
//
//  Created by jun on 2018/06/23.
//  Copyright © 2018年 jun. All rights reserved.
//

import UIKit
import GoogleMobileAds
import Firebase

class HateViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, GADBannerViewDelegate {
   
   


   @IBOutlet weak var tableView: UITableView!
   
   var HateArray: [String] = []
   let defaults = UserDefaults.standard
   
   let SeeHateBannerView = GADBannerView()
   let BannerViewReqest = GADRequest()
   let BANNER_VIEW_TEST_ID: String = "ca-app-pub-3940256099942544/2934735716"
   let BANNER_VIEW_ID: String = "ca-app-pub-1460017825820383/1086930169"

   
   override func viewDidLoad() {
      super.viewDidLoad()
      Play3DtouchMedium()
      Analytics.logEvent("showHateTableView", parameters: nil)
      
      
      if #available(iOS 13.0, *) {
         view.backgroundColor = .systemBackground
      } else {
         view.backgroundColor = UIColor.white
         tableView.backgroundColor = UIColor.white
      }
      tableView.delegate = self
      tableView.dataSource = self
      
      tableView.accessibilityIdentifier = "HateTableView"
      
      if defaults.object(forKey: "OpenHateKey") != nil {
         
         let object = defaults.object(forKey: "OpenHateKey") as? [String]
         for nameString in object! {
            HateArray.append(nameString as String)
         }
      }
      
      tableView.estimatedRowHeight = 10
      tableView.rowHeight = 100
      
      SetUpNavigationItemSetting()
      
      InitAllADCheck()
      
   }
   
   override func setEditing(_ editing: Bool, animated: Bool) {
       super.setEditing(editing, animated: animated)
       tableView.isEditing = editing
   }
   
   private func InitBannerView() {
      #if DEBUG
         print("\n\n--------INFO ADMOB--------------\n")
         self.SeeHateBannerView.adUnitID = BANNER_VIEW_TEST_ID
         print("バナー広告：テスト環境\n\n")
      #else
         print("\n\n--------INFO ADMOB--------------\n")
         self.SeeHateBannerView.adUnitID = BANNER_VIEW_ID
         print("バナー広告：本番環境")
      #endif
      
      //GameClearBannerView.backgroundColor = .black
      SeeHateBannerView.frame = CGRect(x: 0, y: view.frame.height - 50, width: view.frame.width, height: 50)
      view.addSubview(SeeHateBannerView)
      view.bringSubviewToFront(SeeHateBannerView)
      
      SeeHateBannerView.rootViewController = self
      SeeHateBannerView.delegate = self
      
      SeeHateBannerView.load(BannerViewReqest)
   }
   
   //Ad Check
   private func InitAllADCheck() {
      if UserDefaults.standard.bool(forKey: "BuyRemoveAd") == false{
         InitBannerView()
      }else{
         print("課金をしているので広告の初期化は行いません")
      }
   }
   
   //SetUp
   private func SetUpNavigationItemSetting() {
      self.navigationItem.title = NSLocalizedString("hatething", comment: "")
      self.navigationController?.navigationBar.barTintColor = UIColor.flatPowderBlue()
      self.navigationController?.navigationBar.tintColor = .white
      self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
      self.navigationItem.rightBarButtonItem = editButtonItem
   }
   
   /// セルの個数を指定するデリゲートメソッド（必須）
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return HateArray.count
   }
   
   /// セルに値を設定するデータソースメソッド（必須）
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      // セルの型を作る
      let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "myCell")
      // セルに表示するテキストを作る
      cell.textLabel?.text = HateArray[indexPath.row]
      cell.textLabel?.font = UIFont(name: "HiraginoSans-W3", size: 30)
      cell.textLabel?.adjustsFontSizeToFitWidth = true
      // セルをリターンする
      return cell
   }
   
   /// セルが選択された時に呼ばれるデリゲートメソッド
//   func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}
   
   
   /*
    Buttonを拡張する.
    */
   func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
      
     
      // deleteボタン.
      let myArchiveButton: UITableViewRowAction = UITableViewRowAction(style: .normal, title: NSLocalizedString("Delete", comment: "")) { (action, index) -> Void in
         self.HateArray.remove(at: indexPath.row)
         tableView.deleteRows(at: [indexPath], with: .fade)
         self.defaults.set(self.HateArray, forKey: "OpenHateKey")
         self.defaults.synchronize()
         tableView.isEditing = false
         print("Deleted")
         
      }
      myArchiveButton.backgroundColor = UIColor(red: 0.9568627451, green: 0.2745098039, blue: 0.3647058824, alpha: 1)
      
      return [myArchiveButton]
   }
   
   
   func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
   }

   func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
   }
   
   func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
   }

   func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
   
   func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
       let sourceCellItem = HateArray[sourceIndexPath.row]
       guard let indexPath = HateArray.firstIndex(of: sourceCellItem) else { return }
      
       HateArray.remove(at: indexPath)
       HateArray.insert(sourceCellItem, at: destinationIndexPath.row)
      
      
      print(HateArray)
      //save
      defaults.set(HateArray, forKey: "OpenHateKey")
      defaults.synchronize()
   }
   
   private func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
       let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "myCell")
      cell.selectionStyle = UITableViewCell.SelectionStyle.default
       return cell
   }
    
   private func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
      tableView.deselectRow(at: indexPath as IndexPath, animated: true)
   }
   
   
   
   
   
   
   

   override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
   }
   
   
   //MARK:- ADMOB
   /// Tells the delegate an ad request loaded an ad.
   func adViewDidReceiveAd(_ bannerView: GADBannerView) {
      print("広告(banner)のロードが完了しました。")
   }
   
   /// Tells the delegate an ad request failed.
   func bannerView(_ bannerView: GADBannerView,
               didFailToReceiveAdWithError error: Error) {
      print("広告(banner)のロードに失敗しました。: \(error.localizedDescription)")
   }
   
   /// Tells the delegate that a full-screen view will be presented in response
   /// to the user clicking on an ad.
   func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
      print("bannerViewWillPresentScreen")
   }
   
   /// Tells the delegate that the full-screen view will be dismissed.
   func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
      print("bannerViewWillDismissScreen")
   }
   
   /// Tells the delegate that the full-screen view has been dismissed.
   func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
      print("bannerViewDidDismissScreen")
   }
   
   /// Tells the delegate that a user click will open another app (such as
   /// the App Store), backgrounding the current app.
   func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
      print("adViewWillLeaveApplication")
   }
   
   func Play3DtouchLight()  { TapticEngine.impact.feedback(.light) }
   func Play3DtouchMedium() { TapticEngine.impact.feedback(.medium) }
   func Play3DtouchHeavy()  { TapticEngine.impact.feedback(.heavy) }
   func Play3DtouchError() { TapticEngine.notification.feedback(.error) }
   func Play3DtouchSuccess() { TapticEngine.notification.feedback(.success) }
}
