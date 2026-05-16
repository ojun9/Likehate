//
//  ViewController.swift
//  Likehate
//
//  Created by jun on 2018/06/23.
//  Copyright © 2018年 jun. All rights reserved.
//

import UIKit
import Lottie
import SwiftyStoreKit
import Firebase

class ViewController: UIViewController {

   @IBOutlet weak var Top: UIButton!
   @IBOutlet weak var Second: UIButton!
   @IBOutlet weak var Bottom: UIButton!
   
   var noAdsButton: NoAdsButton!
   var restoreButton: RestoreButton!
   
   //Lottieのアニメーション
   let KiraKiraView1 = AnimationView(name: "KiraKira")
   let KiraKiraView2 = AnimationView(name: "KiraKira")
   let Kaminari = AnimationView(name: "Kaminari")
   let Earth = AnimationView(name: "earth")
   
   
   override func viewDidLoad() {
      super.viewDidLoad()
      InitViewSetting()
      InitNotification()
      InitBottom()
      InitSecond()
      InitTop()
      InitButtonLayerSetting(button: Top)
      InitButtonLayerSetting(button: Second)
      InitButtonLayerSetting(button: Bottom)
      InitButtonImage()
      
      SetUpNavigationItemSetting()
      InitKiraView1()
      InitKiraView2()
      InitKaminari()
      InitPurchaseButton()
      InitRestoreButton()
      InitEarth()
      InitAccessibilityIdentifure()
   }
   
   //MARK:- 設定ボタンを押したときの処理
   @objc func TapSettingButton(sender: UIBarButtonItem) {
      Play3DtouchMedium()
      let Storybord = UIStoryboard(name: "SettingTableViewController", bundle: nil)
      let SettingVC = Storybord.instantiateViewController(withIdentifier: "UserSettingNavigationC")
      SettingVC.modalPresentationStyle = .pageSheet
      present(SettingVC, animated: true, completion: {
         print("SettingVC画面にプレゼント完了")
         Analytics.logEvent("OpenSettingNC", parameters: nil)
      })
   }
   
   override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(true)
      SetUpNavigationItemSetting()
      
      if KiraKiraView1.isAnimationPlaying == false {
         KiraKiraView1.play()
         Kira1AniStart()
      }
      
      if KiraKiraView2.isAnimationPlaying == false {
         KiraKiraView2.play()
         Kira2AniStart()
      }
      
      if Kaminari.isAnimationPlaying == false {
         Kaminari.play()
         KaminariAni()
      }
      
      if Earth.isAnimationPlaying == false {
         Earth.play()
      }
   }
   
   @objc func viewWillEnterForeground(_ notification: Notification?) {
      if (self.isViewLoaded && (self.view.window != nil)) {
         print("フォアグラウンド")
         if KiraKiraView1.isAnimationPlaying == false {
            KiraKiraView1.play()
            Kira1AniStart()
         }
         
         if KiraKiraView2.isAnimationPlaying == false {
            KiraKiraView2.play()
            Kira2AniStart()
         }
         
         if Kaminari.isAnimationPlaying == false {
            Kaminari.play()
            KaminariAni()
         }
         
         if Earth.isAnimationPlaying == false {
            Earth.play()
         }
      }
   }

   
   override func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(true)
   }
   
   override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
   }

   
   func Play3DtouchLight()  { TapticEngine.impact.feedback(.light) }
   func Play3DtouchMedium() { TapticEngine.impact.feedback(.medium) }
   func Play3DtouchHeavy()  { TapticEngine.impact.feedback(.heavy) }
   func Play3DtouchError() { TapticEngine.notification.feedback(.error) }
   func Play3DtouchSuccess() { TapticEngine.notification.feedback(.success) }
}

