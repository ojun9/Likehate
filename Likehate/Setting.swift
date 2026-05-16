//
//  Setting.swift
//  Likehate
//
//  Created by jun on 2018/06/26.
//  Copyright © 2018年 jun. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class SettingViewController: UIViewController {
   
   
   var HateArray: [String] = []
   var LikeArray: [String] = []
   let defaults = UserDefaults.standard
   
   
   @IBOutlet weak var CreditsButton: UIButton!
   
   @IBOutlet weak var EraseButton: UIButton!
   
   @IBOutlet weak var ContactUsButton: UIButton!
   
   
   @IBAction func DeletaeButton(_ sender: Any) {
      
      let Appearanse = SCLAlertView.SCLAppearance(showCloseButton: false)
      let ComleateView = SCLAlertView(appearance: Appearanse)
      ComleateView.addButton(NSLocalizedString("delete", comment: "")){
         Analytics.logEvent("delete all date", parameters: nil)
         self.LikeArray = []
         self.HateArray = []
         
         self.defaults.set(self.LikeArray, forKey: "OpenLikeKey")
         self.defaults.synchronize()
         self.defaults.set(self.HateArray, forKey: "OpenHateKey")
         self.defaults.synchronize()
      }
      
      ComleateView.addButton(NSLocalizedString("cancel", comment: "")){
         Analytics.logEvent("delete cannel", parameters: nil)
      }
      ComleateView.showWarning(NSLocalizedString("doyouwanttodelete", comment: ""), subTitle: NSLocalizedString("thisoperation", comment: ""))
   }
   
   @IBAction func CreditsButton(_ sender: Any) {
      
      //labelの設定
      let label: UILabel = UILabel(frame: CGRect(x:10, y: 0, width:self.view.frame.width - 19, height:self.view.frame.height))
      label.text = "HeartLoadingView\n\nCopyright (c) 2018 Dima Shvets <aoedima@gmail.com>\n\nPermission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.\n\n\nPopuDialog\n\nCopyright (c) 2016 Orderella Ltd. (http://orderella.co.uk)\nAuthor - Martin Wildfeuer (http://www.mwfire.de)\n\n Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\n The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.\n\n\nCopyright (c) 2014-2015 Meng To (meng@designcode.io)\n\nPermission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n\n THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE"
      label.numberOfLines = 0;
      label.sizeToFit()
      label.font = UIFont(name: "Hiragino Sans", size: 13)

      //UIScrollViewのインスタンス作成
      let scrollView = UITextView()
      
      //scrollViewの大きさを設定。viewと同じサイズ
      scrollView.frame = self.view.frame
      
      if #available(iOS 13.0, *) {
         scrollView.backgroundColor = UIColor.systemGray3.withAlphaComponent(0.89)
         label.textColor = UIColor.label
      } else {
         scrollView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.88)
      }
      
      //スクロール領域の設定
      scrollView.contentSize = CGSize(width:self.view.frame.width, height:label.frame.height)
      
      
      //labelをscrollViewのSubViewとして追加
      scrollView.addSubview(label)
      scrollView.isEditable = false
      
      //scrollViewをviewのSubViewとして追加
      self.view.addSubview(scrollView)
      
   }
   
   
   @IBAction func TapContactUsButton(_ sender: Any) {
      let url = URL(string: "https://forms.gle/tzrZPy3NDugyyJbc8")
      if let OpenURL = url {
         if UIApplication.shared.canOpenURL(OpenURL){
            Analytics.logEvent("OpenContactUsURL", parameters: nil)
            UIApplication.shared.open(OpenURL)
         }else{
            Analytics.logEvent("CantOpenURL", parameters: nil)
            print("URL nil ちゃうのにひらけない")
         }
      }else{
         Analytics.logEvent("CantOpenURLWithNil", parameters: nil)
         print("URL 開こうとしたらNilやった")
      }
   }
   
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      if #available(iOS 13.0, *) {
         view.backgroundColor = UIColor.systemBackground
      } else {
         view.backgroundColor = UIColor.white
      }
      
      if defaults.object(forKey: "OpenHateKey") != nil {
         
         let object = defaults.object(forKey: "OpenHateKey") as? [String]
         for nameString in object! {
            HateArray.append(nameString as String)
         }
      }else{
         
      }
      
      if defaults.object(forKey: "OpenLikeKey") != nil {
         
         let object = defaults.object(forKey: "OpenLikeKey") as? [String]
         for nameString in object! {
            LikeArray.append(nameString as String)
         }
      }
      
      EraseButton.translatesAutoresizingMaskIntoConstraints = false
      CreditsButton.translatesAutoresizingMaskIntoConstraints = false
      ContactUsButton.translatesAutoresizingMaskIntoConstraints = false
      
      let navi = (self.navigationController?.navigationBar.frame.size.height)!
      let sta = UIApplication.shared.statusBarFrame.size.height
      
      CreditsButton.topAnchor.constraint(equalTo: view.topAnchor, constant: navi + sta + view.frame.width / 8).isActive = true
      CreditsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
      CreditsButton.widthAnchor.constraint(equalToConstant: view.frame.width).isActive = true
      CreditsButton.heightAnchor.constraint(equalToConstant: view.frame.width / 4).isActive = true
      
      EraseButton.topAnchor.constraint(equalTo: CreditsButton.bottomAnchor, constant: view.frame.width / 8).isActive = true
      EraseButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
      EraseButton.widthAnchor.constraint(equalToConstant: view.frame.width).isActive = true
      EraseButton.heightAnchor.constraint(equalToConstant: view.frame.width / 4).isActive = true
      
      ContactUsButton.topAnchor.constraint(equalTo: EraseButton.bottomAnchor, constant: view.frame.width / 8).isActive = true
      ContactUsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
      ContactUsButton.widthAnchor.constraint(equalToConstant: view.frame.width).isActive = true
      ContactUsButton.heightAnchor.constraint(equalToConstant: view.frame.width / 4).isActive = true
      
      if #available(iOS 13.0, *) {
         CreditsButton.backgroundColor = UIColor.systemGray6
         EraseButton.backgroundColor = UIColor.systemGray6
         ContactUsButton.backgroundColor = UIColor.systemGray6
         
         CreditsButton.setTitleColor(.label, for: .normal)
         EraseButton.setTitleColor(.systemPink, for: .normal)
         ContactUsButton.setTitleColor(.label, for: .normal)
      }
   }
   
   override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
   }
   
   
}
