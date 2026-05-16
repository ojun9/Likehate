//
//  WriteHate.swift
//  Likehate
//
//  Created by jun on 2018/06/23.
//  Copyright © 2018年 jun. All rights reserved.
//

import UIKit
import GoogleMobileAds
import Firebase

class WritteHateViewController: UIViewController, UITextFieldDelegate, GADBannerViewDelegate, GADInterstitialDelegate  {
   
   
   @IBOutlet weak var HateLabel: UILabel!
   @IBOutlet weak var HateTextField: FUITextField!
   var HateArray: [String] = []
   var num = 0
   let defaults = UserDefaults.standard
   
   var interstitial: GADInterstitial!
   let request:GADRequest = GADRequest()
   
   let AdBannerView_ID = "ca-app-pub-1460017825820383/8035481899"
   let AdBannerView_TEST_ID = "ca-app-pub-3940256099942544/2934735716"
   
   let Interstitial_ID = "ca-app-pub-1460017825820383/9263543904"
   let Interstitial_TEST_ID = "ca-app-pub-3940256099942544/4411468910"
   
   
   @IBOutlet weak var RegiButton: FUIButton!
   
   @IBOutlet weak var bannerView: GADBannerView!
   
   
   @IBAction func done(_ sender: Any) {
      if HateTextField.text == "" {
         Play3DtouchError()
         return
      }
      Play3DtouchSuccess()
      Analytics.logEvent("RegiHate", parameters: nil)
      HateArray.append((self.HateTextField.text)!)
      defaults.set(HateArray, forKey: "OpenHateKey")
      defaults.synchronize()
      
      if defaults.bool(forKey: "BuyRemoveAd") == true {
         self.navigationController?.popToRootViewController(animated: true)
         return
      }
      
      if interstitial.isReady {
         print("Ins  READY //^ ^//\n")
         interstitial.present(fromRootViewController: self)
         //request.testDevices = [(kGADSimulatorID as! String)]
         interstitial = GADInterstitial(adUnitID: "ca-app-pub-1460017825820383/9263543904")
         interstitial.load(request)
      } else {
         print("Ins Dont READY........\n")
         self.navigationController?.popToRootViewController(animated: true)
      }
      
   }
   
   
  
   override func viewDidLoad() {
      super.viewDidLoad()
      Play3DtouchMedium()
      HateTextField.delegate = self
      
      
      if #available(iOS 13.0, *) {
         view.backgroundColor = UIColor.systemBackground
         HateTextField.textColor = UIColor.label
         HateTextField.backgroundColor = UIColor.systemGray
         HateLabel.textColor = UIColor.label
      }
      
      if defaults.object(forKey: "OpenHateKey") != nil {
         let object = defaults.object(forKey: "OpenHateKey") as? [String]
         for nameString in object! {
            HateArray.append(nameString as String)
         }
      }
      
      HateLabel.text = NSLocalizedString("WhatHate", comment: "")
      HateLabel.adjustsFontSizeToFitWidth = true
      
      InitTextField()
      InitRegiButton()
      
      HateTextField.accessibilityIdentifier = "HateTextField"
      RegiButton.accessibilityIdentifier = "HateRegiButton"
      
      //Init ad
      if defaults.bool(forKey: "BuyRemoveAd") == false {
         InitInstitial()
         InitBannerView()
      }
      
      
      SetUpNavigationItemSetting()
   }
   
   private func InitTextField() {
      HateTextField?.font = UIFont.boldFlatFont (ofSize: 16)
      HateTextField?.backgroundColor = .clear
      HateTextField?.edgeInsets = UIEdgeInsets(top: 4.0, left: 15.0, bottom: 4.0, right: 15.0)
      HateTextField?.textFieldColor = .white
      HateTextField?.borderColor = UIColor.turquoise()
      HateTextField?.borderWidth = 2.0;
      HateTextField?.cornerRadius = 3.0;
      HateTextField?.frame.size.height = 50
   }
   
   private func InitRegiButton() {
      RegiButton?.setTitle(NSLocalizedString("register", comment: ""), for: .normal)
      RegiButton?.titleLabel?.adjustsFontSizeToFitWidth = true
      RegiButton?.titleLabel?.adjustsFontForContentSizeCategory = true
      RegiButton?.buttonColor = UIColor.flatPowderBlue()
      RegiButton?.shadowColor = UIColor.flatPowderBlueColorDark()
      RegiButton?.shadowHeight = 3.0
      RegiButton?.cornerRadius = 6.0
      RegiButton?.titleLabel?.font = UIFont.boldFlatFont (ofSize: 16)
      RegiButton?.setTitleColor(UIColor.clouds(), for: UIControl.State.normal)
      RegiButton?.setTitleColor(UIColor.clouds(), for: UIControl.State.highlighted)
   }
   
   override func viewWillAppear(_ animated: Bool) {
      SetUpNavigationItemSetting()
   }
   
   private func SetUpNavigationItemSetting() {
      self.navigationItem.title = NSLocalizedString("Hate", comment: "")
      self.navigationController?.navigationBar.barTintColor = UIColor.flatPowderBlue()
      self.navigationController?.navigationBar.tintColor = .white
      self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
   }
   
   private func InitBannerView() {
      #if DEBUG
      print("\n\n--------INFO ADMOB--------------\n")
      self.bannerView.adUnitID = AdBannerView_TEST_ID
      print("バナー広告：テスト環境\n\n")
      #else
      print("\n\n--------INFO ADMOB--------------\n")
      self.bannerView.adUnitID = AdBannerView_ID
      print("バナー広告：本番環境")
      #endif
      
      //bannerView.translatesAutoresizingMaskIntoConstraints = false
      self.view.addSubview(bannerView)
      self.view.bringSubviewToFront(bannerView)
      
      bannerView.rootViewController = self
      bannerView.load(request)
   }
   
   private func InitInstitial() {
      #if DEBUG
      print("インターステイシャル:テスト環境")
      interstitial = GADInterstitial(adUnitID: Interstitial_TEST_ID)
      if let ADID = interstitial.adUnitID {
         print("インタースティシャルテスト広告ID読み込み完了")
         print("TestID = \(ADID)")
      }else{
         print("インタースティシャルテスト広告ID読み込み失敗")
      }
      #else
      print("インターステイシャル:本番環境")
      interstitial = GADInterstitial(adUnitID: Interstitial_ID)
      #endif
      
      self.interstitial.delegate = self
      interstitial.load(GADRequest())
   }
   
   
   func interstitialWillDismissScreen(_ ad: GADInterstitial) {
      
      print("?")
   }
   //広告をクリックして開いた画面を閉じる直後
   func interstitialDidDismissScreen(_ ad: GADInterstitial) {

      self.navigationController?.popToRootViewController(animated: true)

   }
   //広告をクリックした時
   func interstitialWillLeaveApplication(_ ad: GADInterstitial) {
      print("click")

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
   
}
