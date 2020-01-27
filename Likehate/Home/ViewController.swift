//
//  ViewController.swift
//  Likehate
//
//  Created by jun on 2018/06/23.
//  Copyright © 2018年 jun. All rights reserved.
//

import UIKit
import Lottie
import ChameleonFramework
import FlatUIKit
import SwiftyStoreKit
import Firebase
import TapticEngine

class ViewController: UIViewController {

   @IBOutlet weak var Top: UIButton!
   
   @IBOutlet weak var Second: UIButton!
   
   @IBOutlet weak var Bottom: UIButton!
   
   var noAdsButton: NoAdsButton!
   var restoreButton: RestoreButton!
   
   let KiraKiraView1 = AnimationView(name: "KiraKira")
   let KiraKiraView2 = AnimationView(name: "KiraKira")
   
   let Kaminari = AnimationView(name: "Kaminari")
   
   let Earth = AnimationView(name: "earth")
   
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      Play3DtouchMedium()
      
      if #available(iOS 13.0, *) {
         view.backgroundColor = UIColor.systemGray6
      } else {
         view.backgroundColor = UIColor.white
      }
      
      Top.accessibilityIgnoresInvertColors = true
      Second.accessibilityIgnoresInvertColors = true
      Bottom.accessibilityIgnoresInvertColors = true
      
      Top.translatesAutoresizingMaskIntoConstraints = false
      Second.translatesAutoresizingMaskIntoConstraints = false
      Bottom.translatesAutoresizingMaskIntoConstraints = false
      

      NotificationCenter.default.addObserver(self, selector: #selector(self.viewWillEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
      
      
      Bottom.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -5).isActive = true
      Bottom.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: self.view.frame.width / 20).isActive = true
      Bottom.widthAnchor.constraint(equalToConstant: self.view.frame.width / 20 * 18).isActive = true
      Bottom.heightAnchor.constraint(equalToConstant: self.view.frame.height / 5).isActive = true
      
      Second.bottomAnchor.constraint(equalTo: Bottom.topAnchor, constant: -self.view.frame.width / 20).isActive = true
      Second.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: self.view.frame.width / 20).isActive = true
      Second.widthAnchor.constraint(equalToConstant: self.view.frame.width / 20 * 18).isActive = true
      Second.heightAnchor.constraint(equalToConstant: self.view.frame.height / 5).isActive = true
      
      Top.bottomAnchor.constraint(equalTo: Second.topAnchor, constant: -self.view.frame.width / 20).isActive = true
      Top.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: self.view.frame.width / 20).isActive = true
      Top.widthAnchor.constraint(equalToConstant: self.view.frame.width / 20 * 18).isActive = true
      Top.heightAnchor.constraint(equalToConstant: self.view.frame.height / 5).isActive = true
      
    
      
      print(self.view.frame)
      
      Top.layer.borderWidth = 1.5
      Top.layer.borderColor = UIColor.flatBlack()?.cgColor
      Top.layer.cornerRadius = 25
      Top.layer.masksToBounds = true
      Top.layer.shadowOffset = CGSize(width: 0, height: 1)
      Top.layer.shadowColor = UIColor.black.cgColor
      //1にすれば真っ黒，0にすれば透明に
      Top.layer.shadowOpacity = 0.5
      Top.layer.shadowRadius = 20
      
      Second.layer.borderWidth = 1.5
      Second.layer.borderColor = UIColor.flatBlack()?.cgColor
      Second.layer.cornerRadius = 25
      Second.layer.masksToBounds = true
      Second.layer.shadowOffset = CGSize(width: 0, height: 1)
      Second.layer.shadowColor = UIColor.black.cgColor
      Second.layer.shadowOpacity = 0.5
      Second.layer.shadowRadius = 20
      
      Bottom.layer.borderWidth = 1.5
      Bottom.layer.borderColor = UIColor.flatBlack()?.cgColor
      Bottom.layer.cornerRadius = 25
      Bottom.layer.masksToBounds = true
      Bottom.layer.shadowOffset = CGSize(width: 0, height: 1)
      Bottom.layer.shadowColor = UIColor.black.cgColor
      Bottom.layer.shadowOpacity = 0.5
      Bottom.layer.shadowRadius = 20

      Second.setImage(UIImage(named: NSLocalizedString("like", comment: "")), for: .normal)
      Bottom.setImage(UIImage(named: NSLocalizedString("hate", comment: "")), for: .normal)
      Top.setImage(UIImage(named: NSLocalizedString("set", comment: "")), for: .normal)
      
      
      
      SetUpNavigationItemSetting()
      InitKiraView1()
      InitKiraView2()
      InitKaminari()
      InitPurchaseButton()
      InitRestoreButton()
      InitEarth()
      
      InitAccessibilityIdentifure()
   }
   
   func InitAccessibilityIdentifure() {
      Top.accessibilityIdentifier = "RegiButton"
      Second.accessibilityIdentifier = "GoLikeButton"
      Bottom.accessibilityIdentifier = "GoHateButton"
      
      noAdsButton.accessibilityIdentifier = "NoAdButton"
      restoreButton.accessibilityIdentifier = "RestoreButton"
      
      
   }
   
   private func InitPurchaseButton() {
      let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
      let navigationBarHeight = self.navigationController?.navigationBar.frame.size.height
      let StartX = self.view.frame.width / 20
      let StartY = statusBarHeight + navigationBarHeight! + self.view.frame.width / 20 * 2
      let size = self.view.frame.height / 10
      
      noAdsButton = NoAdsButton(frame: CGRect(x: StartX, y: StartY, width: size, height: size))

      self.view.addSubview(noAdsButton)
      
   }
   private func InitRestoreButton() {
      let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
      let navigationBarHeight = self.navigationController?.navigationBar.frame.size.height
      let StartX = (self.view.frame.width / 20) * 2 + self.view.frame.height / 10
      let StartY = statusBarHeight + navigationBarHeight! + self.view.frame.width / 20 * 2
      let size = self.view.frame.height / 10
      
      restoreButton = RestoreButton(frame: CGRect(x: StartX, y: StartY, width: size, height: size))
      
      self.view.addSubview(restoreButton)
   }
   
   private func InitEarth() {
      let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
      let navigationBarHeight = self.navigationController?.navigationBar.frame.size.height
      
      let StartY = statusBarHeight + navigationBarHeight! + self.view.frame.width / 20 * 2
      let size = self.view.frame.height / 10
      let StartX = self.view.frame.width - (size + self.view.frame.width / 20)
      let Rect = CGRect(x: StartX, y: StartY, width: size, height: size)
      
      Earth.frame = Rect
      Earth.loopMode = .loop
      Earth.isUserInteractionEnabled = false
      Earth.play()
      self.view.addSubview(Earth)
   }

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
   
   private func SetUpNavigationItemSetting() {
      var image = UIImage()
      if #available(iOS 13, *) {
         image = UIImage(systemName: "gear")!
      } else {
         image = UIImage(named: "setting")!
      }
      let ButtonItems = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(TapSettingButton(sender:)))
      ButtonItems.accessibilityIdentifier = IdenMane.first.SettingButton
      self.navigationItem.setLeftBarButton(ButtonItems, animated: true)
      self.navigationItem.title = NSLocalizedString("home", comment: "")
      self.navigationController?.navigationBar.barTintColor = UIColor.flatMagenta()
      self.navigationController?.navigationBar.tintColor = .white
      self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
   }
   
   private func Kira1AniStart() {
      UIView.animate(withDuration: 4,
                     delay: 0.25,
                     options: [.autoreverse, .repeat, .curveEaseInOut],
                     animations: {
                        self.KiraKiraView1.transform = CGAffineTransform(scaleX: 2.9, y: 2.9)
                     },
                     completion: { _ in
                        self.KiraKiraView1.transform = CGAffineTransform.identity
                     })
   }
   
   private func Kira2AniStart() {
      UIView.animate(withDuration: 4.85,
                     delay: 0.1,
                     options: [.autoreverse, .repeat, .curveEaseOut],
                     animations: {
                        self.KiraKiraView2.transform = CGAffineTransform(scaleX: 2.9, y: 2.9)
                     },
                     completion: { _ in
                        self.KiraKiraView2.transform = CGAffineTransform.identity
                     })
   }
   
   private func KaminariAni() {
      UIView.animate(withDuration: 4.25,
                     delay: 0.25,
                     options: [.autoreverse, .repeat, .curveEaseInOut],
                     animations: {
                        let frame = self.Kaminari.frame
                        let aniX = frame.minX + self.view.frame.width / 3 * 1.5
                        self.Kaminari.frame = CGRect(x: aniX, y: frame.minY, width: frame.width, height: frame.height)
                     },
                     completion: { _ in
                        let frame = self.Kaminari.frame
                        let aniX = frame.minX - self.view.frame.width / 3 * 1.5
                        self.Kaminari.frame = CGRect(x: aniX, y: frame.minY, width: frame.width, height: frame.height)
                     })
   }

   
   private func InitKiraView1() {
      let StartY = self.view.frame.height - (self.view.frame.height / 20 * 9.5 + self.view.frame.height / 20)
      let StartX = self.view.frame.width / 20
      let Wide = StartX * 18 / 2
      let Hight = self.view.frame.height / 5
      let Rect = CGRect(x: StartX, y: StartY, width: Wide, height: Hight)
      
      KiraKiraView1.frame = Rect
      KiraKiraView1.alpha = 0.8
      KiraKiraView1.loopMode = .loop
      KiraKiraView1.isUserInteractionEnabled = false
      KiraKiraView1.play()
      self.view.addSubview(KiraKiraView1)
      Kira1AniStart()
   }
   
   private func InitKiraView2() {
      let StartY = self.view.frame.height - (self.view.frame.height / 20 * 9.5 - self.view.frame.height / 20)
      let StartX = self.view.frame.width / 20 * 9
      let Wide = self.view.frame.width / 20 * 18 / 2
      let Hight = self.view.frame.height / 5
      let Rect = CGRect(x: StartX, y: StartY, width: Wide, height: Hight)
      
      KiraKiraView2.frame = Rect
      KiraKiraView2.alpha = 0.8
      KiraKiraView2.loopMode = .loop
      KiraKiraView2.isUserInteractionEnabled = false
      KiraKiraView2.play()
      self.view.addSubview(KiraKiraView2)
      Kira2AniStart()
   }
   
   private func InitKaminari() {
      print(self.view.safeAreaInsets.bottom)
      let StartY = self.view.frame.height - (self.view.frame.height / 5 + 15)
      let StartX = self.view.frame.width / 20
      let Wide = self.view.frame.height / 5
      let Hight = self.view.frame.height / 5
      let Rect = CGRect(x: StartX, y: StartY, width: Wide, height: Hight)
      
      Kaminari.frame = Rect
      Kaminari.alpha = 0.7
      Kaminari.loopMode = .loop
      Kaminari.isUserInteractionEnabled = false
      Kaminari.play()
      self.view.addSubview(Kaminari)
      KaminariAni()
   }
   
   override func viewWillLayoutSubviews() {
      super.viewWillLayoutSubviews()
      
      
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

