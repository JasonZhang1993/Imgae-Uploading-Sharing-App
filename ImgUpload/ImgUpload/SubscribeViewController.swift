//
//  SubscribeViewController.swift
//  ImgUpload
//
//  Created by Jason Zhang on 9/8/17.
//  Copyright © 2017 Jason Zhang. All rights reserved.
//

import UIKit
import AWSCore
import AWSSNS
import EasyToast

class SubscribeViewController: UIViewController, UITextFieldDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.status.text = "You can subscribe our app through your email, and share your awesome images with your firends!"
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        dismissKeyboard()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dismissKeyboard()
        return true
    }
    
    func dismissKeyboard() {
        self.Email_Addr.resignFirstResponder()
    }
    
    @IBOutlet weak var Email_Addr: UITextField!
    
    @IBOutlet weak var status: UILabel!
    
    @IBAction func subscribe_Action(_ sender: UIButton) { // subscribe the user to SNS so that he/she can receive the email notification
        
        if Email_Addr.text == "" {
            self.view.toastBackgroundColor = UIColor.black.withAlphaComponent(0.7)
            self.view.toastTextColor = UIColor.white
            self.view.toastFont = UIFont.systemFont(ofSize: 19)
            self.view.showToast("The email address is empty", position: .bottom, popTime: kToastNoPopTime, dismissOnTap: true)

            return
        }
        
        if !isValidEmial(str: Email_Addr.text!) {
            
            self.view.showToast("The email address is not valid", position: .bottom, popTime: kToastNoPopTime, dismissOnTap: true)
            return
        }
        
        let newSubscriber = AWSSNSSubscribeInput.init()
        newSubscriber?.topicArn = AppInfo.myArn
        newSubscriber?.protocols = "email"
        newSubscriber?.endpoint = Email_Addr.text!
        
        let SNSClient = AWSSNS.default()
        SNSClient.subscribe(newSubscriber!).continueWith { (task) -> AnyObject! in
            if let error = task.error {
                print("error: \(error)")
            }
            if let _ = task.result {
                DispatchQueue.main.async {
                    self.status.text = "A confirmation message is sent to your email, please check. Thanks for your subscribtion."
                    self.view.showToast("Subscribe success!", position: .bottom, popTime: 2.0, dismissOnTap: true)
                    print("subscribe successful")
                }
            }
            return nil
        }
    }
    
    func isValidEmial(str: String) -> Bool {
        let RegExp = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format: "SELF MATCHES %@", RegExp)
        
        return emailTest.evaluate(with: str)
    }

}
