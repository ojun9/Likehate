//
//  ExViewControllerInit.swift
//  Likehate
//
//  Created by jun on 2020/01/27.
//  Copyright © 2020 jun. All rights reserved.
//

import Foundation
import UIKit

extension ViewController {
   func InitViewSetting() {
      if #available(iOS 13.0, *) {
         view.backgroundColor = UIColor.systemGray6
         return
      }
      view.backgroundColor = UIColor.white
   }
   
   func InitNotification() {
      NotificationCenter.default.addObserver(self, selector: #selector(self.viewWillEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
   }
   
   func InitBottom() {
      Bottom.accessibilityIgnoresInvertColors = true
      Bottom.translatesAutoresizingMaskIntoConstraints = false
      Bottom.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -5).isActive = true
      Bottom.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: self.view.frame.width / 20).isActive = true
      Bottom.widthAnchor.constraint(equalToConstant: self.view.frame.width / 20 * 18).isActive = true
      Bottom.heightAnchor.constraint(equalToConstant: self.view.frame.height / 5).isActive = true
   }
   
   func InitSecond() {
      Second.translatesAutoresizingMaskIntoConstraints = false
      Second.accessibilityIgnoresInvertColors = true
      Second.bottomAnchor.constraint(equalTo: Bottom.topAnchor, constant: -self.view.frame.width / 20).isActive = true
      Second.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: self.view.frame.width / 20).isActive = true
      Second.widthAnchor.constraint(equalToConstant: self.view.frame.width / 20 * 18).isActive = true
      Second.heightAnchor.constraint(equalToConstant: self.view.frame.height / 5).isActive = true
   }
   
   func InitTop() {
      Top.accessibilityIgnoresInvertColors = true
      Top.translatesAutoresizingMaskIntoConstraints = false
      Top.bottomAnchor.constraint(equalTo: Second.topAnchor, constant: -self.view.frame.width / 20).isActive = true
      Top.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: self.view.frame.width / 20).isActive = true
      Top.widthAnchor.constraint(equalToConstant: self.view.frame.width / 20 * 18).isActive = true
      Top.heightAnchor.constraint(equalToConstant: self.view.frame.height / 5).isActive = true
   }
   
   func InitButtonLayerSetting(button: UIButton) {
      button.layer.borderWidth = 1.5
      button.layer.borderColor = UIColor.flatBlack()?.cgColor
      button.layer.cornerRadius = 25
      button.layer.masksToBounds = true
      button.layer.shadowOffset = CGSize(width: 0, height: 1)
      button.layer.shadowColor = UIColor.black.cgColor
      //1にすれば真っ黒，0にすれば透明に
      button.layer.shadowOpacity = 0.5
      button.layer.shadowRadius = 20
   }
   
   func InitButtonImage() {
      Top.setImage(UIImage(named: "set"), for: .normal)
      Second.setImage(UIImage(named: "like"), for: .normal)
      Bottom.setImage(UIImage(named: "hate"), for: .normal)
   }
   
   
   func InitAccessibilityIdentifure() {
      Top.accessibilityIdentifier = "RegiButton"
      Second.accessibilityIdentifier = "GoLikeButton"
      Bottom.accessibilityIdentifier = "GoHateButton"
      noAdsButton.accessibilityIdentifier = "NoAdButton"
      restoreButton.accessibilityIdentifier = "RestoreButton"
   }
   
   func InitPurchaseButton() {
      let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
      let navigationBarHeight = self.navigationController?.navigationBar.frame.size.height
      let StartX = self.view.frame.width / 20
      let StartY = statusBarHeight + navigationBarHeight! + self.view.frame.width / 20 * 2
      let size = self.view.frame.height / 10
      
      noAdsButton = NoAdsButton(frame: CGRect(x: StartX, y: StartY, width: size, height: size))

      self.view.addSubview(noAdsButton)
      
   }
   func InitRestoreButton() {
      let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
      let navigationBarHeight = self.navigationController?.navigationBar.frame.size.height
      let StartX = (self.view.frame.width / 20) * 2 + self.view.frame.height / 10
      let StartY = statusBarHeight + navigationBarHeight! + self.view.frame.width / 20 * 2
      let size = self.view.frame.height / 10
      
      restoreButton = RestoreButton(frame: CGRect(x: StartX, y: StartY, width: size, height: size))
      
      self.view.addSubview(restoreButton)
   }
   
   func InitEarth() {
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
   
   func SetUpNavigationItemSetting() {
      var image = UIImage()
      if #available(iOS 13, *) {
         image = UIImage(systemName: "gear")!
      } else {
         image = UIImage(named: "setting")!
      }
      let ButtonItems = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(TapSettingButton(sender:)))
      ButtonItems.accessibilityIdentifier = "SettingButton"
      self.navigationItem.setLeftBarButton(ButtonItems, animated: true)
      self.navigationItem.title = NSLocalizedString("home", comment: "")
      self.navigationController?.navigationBar.barTintColor = UIColor.flatMagenta()
      self.navigationController?.navigationBar.tintColor = .white
      self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
   }
   
   func InitKiraView1() {
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
   
   func InitKiraView2() {
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
   
   func InitKaminari() {
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
}
