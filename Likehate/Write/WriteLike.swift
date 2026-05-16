//
//  WriteLike.swift
//  Likehate
//
//  Created by jun on 2018/06/23.
//  Copyright © 2018年 jun. All rights reserved.
//

import UIKit
import Lottie
import Firebase
import FirebaseRemoteConfig

class WritteLikeViewController: UIViewController, UITextFieldDelegate {
   
   
   @IBOutlet weak var Label: UILabel!
   @IBOutlet weak var TextField: FUITextField!
   
   @IBOutlet  var RegiButton: FUIButton!
   
   
   let AniView1 = AnimationView(name: "MoreHarts")
   let AniView2 = AnimationView(name: "Fuwa")
   let AniView3 = AnimationView(name: "KuruKuru")
   
   //リモートコンフィグろとるやつ
   var RemorteConfigs: RemoteConfig!
   
   
   //@IBOutlet weak var TextNumOfArray: UILabel!
   var LikeArray: [String] = []
   var num = 0
   let defaults = UserDefaults.standard
   
   var stopTapTic = false
   
   @IBAction func done(_ sender: Any) {
      
      
      
      if TextField.text == "" {
         Play3DtouchError()
         return
         
      }
      
      Play3DtouchSuccess()
      
      Analytics.logEvent("RegiLike", parameters: nil)
      
      LikeArray.append((self.TextField.text)!)
      defaults.set(LikeArray, forKey: "OpenLikeKey")
      defaults.synchronize()
   }
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      Play3DtouchMedium()
      
      InitTextField()
      InitRegiButton()
      
      TextField.accessibilityIdentifier = "LikeTextField"
      RegiButton.accessibilityIdentifier = "LikeRegiButton"
      
      if #available(iOS 13.0, *) {
         view.backgroundColor = UIColor.systemBackground
         TextField.textColor = UIColor.label
         TextField.backgroundColor = UIColor.systemGray
         Label.textColor = UIColor.label
      }
      
      TextField.delegate = self
      if defaults.object(forKey: "OpenLikeKey") != nil {
         
         let object = defaults.object(forKey: "OpenLikeKey") as? [String]
         //var nameString:AnyObject
         for nameString in object! {
            LikeArray.append(nameString as String)
         }
      }
      
      Label.text = NSLocalizedString("WhatLike", comment: "")
      Label.adjustsFontSizeToFitWidth = true
      
      SetUpNavigationItemSetting()
      
      InitImageView(AniView: AniView1)
      InitImageView(AniView: AniView2)
      InitImageView(AniView: AniView3)
      
      InitConfig()
      SetUpRemoteConfigDefaults()
      SetUpAniView()
      FetchConfig()
      
      StartTapTic()
   }
   
   override func viewWillAppear(_ animated: Bool) {
      SetUpNavigationItemSetting()
   }
   
   override func viewDidDisappear(_ animated: Bool) {
      super.viewDidDisappear(true)
      stopTapTic = true
   }
   
   private func SetUpRemoteConfigDefaults() {
      let defaultsValues = [
         "LOTKEY" : "MoreHarts" as NSObject
      ]
      
      
      self.RemorteConfigs.setDefaults(defaultsValues)
   }
   
   private func InitConfig() {
      self.RemorteConfigs = RemoteConfig.remoteConfig()
      //MARK: デベロッパモード　出すときはやめろ
      let RemortConfigSetting = RemoteConfigSettings()
      #if DEBUG
      print("RemoConデバッグモード")
      RemortConfigSetting.minimumFetchInterval = 0
      #else
      print("RemoConリリースモードでいくとよ。")
      RemortConfigSetting.minimumFetchInterval = 3600
      #endif
      self.RemorteConfigs.configSettings = RemortConfigSetting
   }
   
   func FetchConfig() {
      // ディベロッパーモードの時、expirationDurationを0にして随時更新できるようにする。
      let expirationDuration = RemorteConfigs.configSettings.minimumFetchInterval
      print("RemoteConfigのフェッチする間隔： \(expirationDuration)")
      RemorteConfigs.fetch(withExpirationDuration: TimeInterval(expirationDuration)) { [unowned self] (status, error) -> Void in
         guard error == nil else {
            print("Firebase Config フェッチあかん買った")
            print("Error: \(error?.localizedDescription ?? "No error available.")")
            return
         }
         
         print("フェッチできたよ")
         self.RemorteConfigs.activate { _, _ in
            self.SetUpAniView()
         }
      }
   }
   
   private func SetUpAniView() {
      let animationKey = RemorteConfigs["LOTKEY"].stringValue
      print(animationKey)
      switch animationKey {
      case "MoreHarts":
         RemoFuwa()
         RemoKuruKuru()
         DisplayMoreHarts()
      case "KuruKuru":
         RemoMoreHarts()
         RemoFuwa()
         DisplayKuruKuru()
      case "Fuwa":
         RemoMoreHarts()
         RemoKuruKuru()
         DisplayFuwa()
      default:
         Analytics.logEvent("ErroRemoCon", parameters: nil)
         RemoFuwa()
         RemoKuruKuru()
         DisplayMoreHarts()
      }
   }
   
   private func RemoMoreHarts() {
      AniView1.isHidden = true
      AniView1.stop()
   }
   
   private func DisplayMoreHarts() {
      AniView1.isHidden = false
      AniView1.play()
   }
   
   private func RemoFuwa() {
      AniView2.isHidden = true
      AniView2.stop()
   }
   
   private func DisplayFuwa() {
      AniView2.isHidden = false
      AniView2.play()
   }
   
   private func RemoKuruKuru() {
      AniView3.isHidden = true
      AniView3.stop()
   }
   
   private func DisplayKuruKuru() {
      AniView3.isHidden = false
      AniView3.play()
   }
   
   private func InitImageView(AniView: AnimationView) {
      let StartX = self.view.frame.width / 50
      let Wide = StartX * 48
      let StartY = RegiButton.frame.maxY + 30
      let RemoveY = self.view.frame.height - StartY
      let Hight = RemoveY - 15
      AniView.frame = CGRect(x: StartX, y: StartY, width: Wide, height: Hight)
      AniView.contentMode = .scaleAspectFit

      AniView.loopMode = .loop
      AniView.isUserInteractionEnabled = false
      self.view.addSubview(AniView)
      AniView.isHidden = true
   }
   
   
   
   private func InitTextField() {
      TextField?.font = UIFont.boldFlatFont (ofSize: 16)
      TextField?.backgroundColor = .clear
      TextField?.edgeInsets = UIEdgeInsets(top: 4.0, left: 15.0, bottom: 4.0, right: 15.0)
      TextField?.textFieldColor = .white
      TextField?.borderColor = UIColor.turquoise()
      TextField?.borderWidth = 2.0;
      TextField?.cornerRadius = 3.0;
   }
   
   private func InitRegiButton() {
      RegiButton?.setTitle(NSLocalizedString("register", comment: ""), for: .normal)
      RegiButton?.titleLabel?.adjustsFontSizeToFitWidth = true
      RegiButton?.titleLabel?.adjustsFontForContentSizeCategory = true
      RegiButton?.buttonColor = UIColor.flatWatermelon()
      RegiButton?.shadowColor = UIColor.flatWatermelonColorDark()
      RegiButton?.shadowHeight = 3.0
      RegiButton?.cornerRadius = 6.0
      RegiButton?.titleLabel?.font = UIFont.boldFlatFont (ofSize: 16)
      RegiButton?.setTitleColor(UIColor.clouds(), for: UIControl.State.normal)
      RegiButton?.setTitleColor(UIColor.clouds(), for: UIControl.State.highlighted)
   }
   
   private func SetUpNavigationItemSetting() {
      self.navigationItem.title = NSLocalizedString("Like", comment: "")
      self.navigationController?.navigationBar.barTintColor = UIColor.flatWatermelon()
      self.navigationController?.navigationBar.tintColor = .white
      self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
   }
   
 
   override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
   }
   
   /*
    UITextFieldが編集された直後に呼ばれるデリゲートメソッド.
    */
   func textFieldDidBeginEditing(_ textField: UITextField){
      print("textFieldDidBeginEditing:" + textField.text!)
   }
   
   /*
    UITextFieldが編集終了する直前に呼ばれるデリゲートメソッド.
    */
   func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
      print("textFieldShouldEndEditing:" + textField.text!)
      
      return true
   }
   
   /*
    改行ボタンが押された際に呼ばれるデリゲートメソッド.
    */
   func textFieldShouldReturn(_ textField: UITextField) -> Bool {
      textField.resignFirstResponder()
      
      return true
   }
   
   
   
   
   func Play3DtouchLight()  { TapticEngine.impact.feedback(.light) }
   func Play3DtouchMedium() { TapticEngine.impact.feedback(.medium) }
   func Play3DtouchHeavy()  { TapticEngine.impact.feedback(.heavy) }
   func Play3DtouchError() { TapticEngine.notification.feedback(.error) }
   func Play3DtouchSuccess() { TapticEngine.notification.feedback(.success) }
   
   
   func StartTapTic() {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.Play3DtouchLight() }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { self.Play3DtouchLight() }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.Play3DtouchLight() }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { self.Play3DtouchLight() }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { self.Play3DtouchLight() }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { self.Play3DtouchLight() }
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { self.Play3DtouchLight() }
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { self.Play3DtouchLight() }
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { self.Play3DtouchLight() }
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { self.Play3DtouchLight() }
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { self.Play3DtouchMedium() }
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { self.Play3DtouchMedium() }
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self.Play3DtouchMedium() }
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { self.Play3DtouchMedium() }
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) { self.Play3DtouchMedium() }
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { self.Play3DtouchMedium() }
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) { self.Play3DtouchMedium() }
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { self.Play3DtouchHeavy() }
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.35) { self.Play3DtouchHeavy() }
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { self.Play3DtouchHeavy() }
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.65) { self.Play3DtouchMedium() }
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) { self.Play3DtouchMedium() }
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.9) { self.Play3DtouchMedium() }
      DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { self.Play3DtouchMedium() }
      DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) { self.Play3DtouchLight() }
      DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) { self.Play3DtouchLight() }
      DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) { self.Play3DtouchLight() }
      DispatchQueue.main.asyncAfter(deadline: .now() + 3.4) { self.Play3DtouchLight() }
      DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { self.Play3DtouchLight() }
      DispatchQueue.main.asyncAfter(deadline: .now() + 3.6) { self.Play3DtouchLight() }
      DispatchQueue.main.asyncAfter(deadline: .now() + 3.7) { self.Play3DtouchLight() }
      DispatchQueue.main.asyncAfter(deadline: .now() + 3.8) {
         if self.stopTapTic { return }
         self.StartTapTic()
      }
   }
   
}
