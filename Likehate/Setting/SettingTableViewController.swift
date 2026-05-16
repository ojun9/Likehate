//
//  SettingTableViewController.swift
//  Likehate
//
//  Created by jun on 2020/01/26.
//  Copyright © 2020 jun. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import StoreKit

class SettingTableViewController: UITableViewController {
   
   let numOfSection = 2
   let firstNumberOfRowsInSection = 1
   let secondNumberOfRowsInSection = 3
   
   
   @IBOutlet weak var DataErasingLabel: UILabel!
   
   @IBOutlet weak var AppReviewLabel: UILabel!
   @IBOutlet weak var ContacuUsLabel: UILabel!
   @IBOutlet weak var CreditsLabel: UILabel!
   
   let defaults = UserDefaults.standard
   var HateArray: [String] = []
   var LikeArray: [String] = []
   
   override func viewDidLoad() {
      super.viewDidLoad()
      Analytics.logEvent("showSettinVC", parameters: nil)
      SetUpView()
      SetUpNavigationBar()
      SetUpLabelText()
   }
   
   private func SetUpView() {
      if #available(iOS 13.0, *) {
         view.backgroundColor = UIColor.systemGray6
      } else {
         view.backgroundColor = UIColor.white
      }
   }
   
   private func SetUpNavigationBar() {
      let stopItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(TapDoneButton))
      stopItem.tintColor = .black
      self.navigationItem.leftBarButtonItem = stopItem
   }
   
   //MARK:- NaviBarでバツボタン押されたときの処理
   @objc func TapDoneButton() {
      print("完了ボタンタップされた")
      self.dismiss(animated: true, completion: {
         print("SettingVCのdismiss完了")
      })
   }
   
   private func SetUpLabelText() {
      DataErasingLabel.text = NSLocalizedString("deleteErasing", comment: "")
      
      AppReviewLabel.text = NSLocalizedString("AppRevie", comment: "")
      ContacuUsLabel.text = NSLocalizedString("ContactUs", comment: "")
      CreditsLabel.text = NSLocalizedString("Credits", comment: "")

   }
   
   // MARK: - Table view data source
   // セクションの数を返します
   override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
      return numOfSection
   }

   override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
   switch section {
      case 0:
         return firstNumberOfRowsInSection
      case 1:
         return secondNumberOfRowsInSection
      default:
         print("設定ミスってるぞ！！！")
         return 0
      }
   }
   
   override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

      print("section 番号: \(indexPath.section)")
      print("index   番号: \(indexPath.row)")
      
      switch indexPath.section {
      case 0:
         TapDataErasing()
         print("")
      case 1:
         TapOther(rowNum: indexPath.row)
         print("")
      default:
         print("設定ミスってるぞ！！！")
         return
      }
      
      tableView.deselectRow(at: indexPath, animated: true)
   }
   
   
   func TapDataErasing() {
      Analytics.logEvent("TapDataErasing", parameters: nil)
      Play3DtouchHeavy()
      let Appearanse = SCLAlertView.SCLAppearance(showCloseButton: false)
      let ComleateView = SCLAlertView(appearance: Appearanse)
      ComleateView.addButton(NSLocalizedString("delete", comment: "")){
         self.Play3DtouchSuccess()
         Analytics.logEvent("delete all date", parameters: nil)
         self.LikeArray = []
         self.HateArray = []
         
         self.defaults.set(self.LikeArray, forKey: "OpenLikeKey")
         self.defaults.synchronize()
         self.defaults.set(self.HateArray, forKey: "OpenHateKey")
         self.defaults.synchronize()
      }
      
      ComleateView.addButton(NSLocalizedString("cancel", comment: "")){
         self.Play3DtouchLight()
         Analytics.logEvent("delete cannel", parameters: nil)
      }
      ComleateView.showWarning(NSLocalizedString("doyouwanttodelete", comment: ""), subTitle: NSLocalizedString("thisoperation", comment: ""))
   }
   
   func TapOther(rowNum: Int) {
      switch rowNum {
           case 0:
              TapAppReview()
              print("")
           case 1:
              TapContacuUs()
              print("")
           case 2:
              TapCredits()
              print("")
           default:
              print("設定ミスってるぞ！！！")
              return
           }
   }
   
   func TapAppReview() {
      Analytics.logEvent("TapAppReview", parameters: nil)
      Play3DtouchHeavy()
      if #available(iOS 10.3, *) {
          SKStoreReviewController.requestReview()
      }else {
         if let url = URL(string: "itms-apps://itunes.apple.com/app/id1406645257?action=write-review") {
            UIApplication.shared.open(url, options: [:])
         }
      }
   }
   
   func TapContacuUs() {
      Analytics.logEvent("TapContacuUs", parameters: nil)
      Play3DtouchLight()
      let url = URL(string: "https://forms.gle/mSEq7WwDz3fZNcqF6")
      if let OpenURL = url {
         if UIApplication.shared.canOpenURL(OpenURL){
            Analytics.logEvent("OpenContactUsURLSetting", parameters: nil)
            UIApplication.shared.open(OpenURL)
         }else{
            Analytics.logEvent("CantOpenURSettingL", parameters: nil)
            print("URL nil ちゃうのにひらけない")
         }
      }else{
         Analytics.logEvent("CantOpenURLWithNilSetting", parameters: nil)
         print("URL 開こうとしたらNilやった")
      }
   }
   
   func TapCredits() {
      Analytics.logEvent("TapCredits", parameters: nil)
      Play3DtouchMedium()
      Analytics.logEvent("TapCredit", parameters: nil)
      if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
         UIApplication.shared.open(url, options: [:], completionHandler: nil)
      }
   }
   
   
   func Play3DtouchLight()  { TapticEngine.impact.feedback(.light) }
   func Play3DtouchMedium() { TapticEngine.impact.feedback(.medium) }
   func Play3DtouchHeavy()  { TapticEngine.impact.feedback(.heavy) }
   func Play3DtouchError() { TapticEngine.notification.feedback(.error) }
   func Play3DtouchSuccess() { TapticEngine.notification.feedback(.success) }
}
