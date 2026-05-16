//
//  RestoreButton.swift
//  Likehate
//
//  Created by jun on 2019/07/09.
//  Copyright © 2019 jun. All rights reserved.
//


import UIKit
import SwiftyStoreKit
import Firebase

class RestoreButton: FUIButton {
   
   
   override init(frame: CGRect) {
      super.init(frame: frame)
      
      InitSelf()

   }
   
   private func InitSelf() {
      self.setTitle(NSLocalizedString("Restore", comment: ""), for: UIControl.State.normal)
      self.buttonColor = UIColor.flatPowderBlue()
      self.shadowColor = UIColor.flatPowderBlueColorDark()
      self.shadowHeight = 3.0
      self.cornerRadius = 6.0
      self.titleLabel?.font = UIFont.boldFlatFont(ofSize: 50)
      self.titleLabel?.adjustsFontSizeToFitWidth = true
      self.setTitleColor(UIColor.clouds(), for: UIControl.State.normal)
      self.setTitleColor(UIColor.clouds(), for: UIControl.State.highlighted)
      self.addTarget(self, action: #selector(self.restore), for: UIControl.Event.touchUpInside)
   }
   
   private func CompleateBuyRemoveADS() {
      let Appearanse = SCLAlertView.SCLAppearance(showCloseButton: false)
      let ComleateView = SCLAlertView(appearance: Appearanse)
      ComleateView.addButton("OK"){
         print("tap")
         NotificationCenter.default.post(name: .BuyNoAdsInClearView, object: nil, userInfo: nil)
         
      }
      ComleateView.showSuccess(NSLocalizedString("Passed.", comment: ""), subTitle: "Purchase complete")
   }
   
   //リストアボタンを押した時の処理
   @objc func restore(sender: UIButton) {
      SwiftyStoreKit.restorePurchases(atomically: true) { results in
         if results.restoreFailedPurchases.count > 0 {
            //リストアに失敗
            print("リストアに失敗")
         }
         else if results.restoredPurchases.count > 0 {
            print("リストアに成功")
            //購入成功
            let defaults = UserDefaults.standard
            defaults.set(true, forKey: "BuyRemoveAd")
            print("リストアに成功しました")
            print("購入フラグを　\(defaults.bool(forKey: "BuyRemoveAd"))　に変更しました")
            self.CompleateRestore()
         }
         else {
            print("リストアするものがない")
            print("Restorボタン押したけどなんも買ってないパターン")
         }
      }
   }
   
   //リストア完了した時にViewを表示する関数
   private func CompleateRestore() {
      let Appearanse = SCLAlertView.SCLAppearance(showCloseButton: false)
      let ComleateView = SCLAlertView(appearance: Appearanse)
      ComleateView.addButton("OK"){
         print("tap")
         
      }
      ComleateView.showSuccess(NSLocalizedString("Passed.", comment: ""), subTitle: "Restore successful")
   }
   
   
   
   
   required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }
   
}

