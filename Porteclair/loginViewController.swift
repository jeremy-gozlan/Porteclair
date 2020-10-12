//
//  loginViewController.swift
//  Porteclair
//
//  Created by Jeremy on 12/03/2018.
//  Copyright © 2018 Jeremy. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseAuth


class loginViewController : UIViewController , UITextFieldDelegate {
    
    var originx : CGFloat?
    var originy : CGFloat?
    var keyboardHeight : CGFloat?
    var buttonOldFrame : CGRect?
    
    
    var activeTextField = UITextField()
    
    
    @IBOutlet weak var usernameTextField: UITextField!
    
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    
    @IBOutlet weak var loginButton: UIButton!
    
    
    @IBOutlet weak var ForgotButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        originx = self.view.center.x
        originy = self.view.center.y
        
        self.usernameTextField.delegate = self
        self.passwordTextField.delegate = self
        self.usernameTextField.autocorrectionType = .no
        self.passwordTextField.autocorrectionType = .no
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
        
        let str = NSAttributedString(string: "Email", attributes: [NSAttributedStringKey.foregroundColor:UIColor.lightGray])
        let str2 = NSAttributedString(string: "Password", attributes: [NSAttributedStringKey.foregroundColor:UIColor.lightGray])
        
        usernameTextField.attributedPlaceholder = str
        passwordTextField.attributedPlaceholder = str2
        
        
        usernameTextField.layer.borderColor = secondColor.cgColor
        usernameTextField.layer.borderWidth = CGFloat(1)
        usernameTextField.layer.cornerRadius = CGFloat(6)
        
        passwordTextField.layer.borderColor = secondColor.cgColor
        passwordTextField.layer.borderWidth = CGFloat(1)
        passwordTextField.layer.cornerRadius = CGFloat(6)
       
        passwordTextField.isSecureTextEntry = true
        

        
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        self.usernameTextField.layer.backgroundColor = UIColor.clear.cgColor
        self.passwordTextField.layer.backgroundColor = UIColor.clear.cgColor
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func loginButton(_ sender: Any) {
        
        if usernameTextField.text != "" && passwordTextField.text != ""
        {
                Auth.auth().signIn(withEmail: usernameTextField.text!, password: passwordTextField.text!) { (user, error) in
                    if user != nil {
                        
                        self.dismiss(animated: true, completion: nil)
                    }
                    else {
                        if let myError = error?.localizedDescription
                        {
                            // Alert user in case of error with a Firestore notification
                            let alertController = UIAlertController(title: "Porteclair", message: myError, preferredStyle: UIAlertControllerStyle.alert)
                    
                            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
                            {
                                (result : UIAlertAction) -> Void in
                            }
                            alertController.addAction(okAction)
                            self.present(alertController, animated: true)
                        }
                        else{ print ("ERROR") }
                    }
            }
        }
    }
    
    
    @IBAction func resetPassword(_ sender: Any) {
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurEffectView)
        
        let alertController = UIAlertController(title: "Porteclair", message: "Forgot your password?", preferredStyle: .alert)
        alertController.addTextField(configurationHandler: {(_ textField: UITextField) -> Void in
            textField.placeholder = "Email address"
        })
        let sendEmail = UIAlertAction(title: "Send email", style: .default, handler: {(_ action: UIAlertAction) -> Void in
            Auth.auth().sendPasswordReset(withEmail: alertController.textFields![0].text!) { (error) in
                print ( alertController.textFields![0].text!)
                blurEffectView.removeFromSuperview()
                // dkdkd
            }
        })
        alertController.addAction(sendEmail)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {(_ action: UIAlertAction) -> Void in
            blurEffectView.removeFromSuperview()
        })
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
        
        
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            self.keyboardHeight = keyboardRectangle.height
            let newCenter = CGPoint (x : self.originx! , y : self.originy! - self.keyboardHeight!/2)
            
            UIView.animate(withDuration: 1.0, delay: 0.0, options: [.allowAnimatedContent], animations:
                {
                    
                    self.view.center = newCenter
                    
            },
                           completion : nil)
            
        }
    }
    
    @objc func keyboardWillHide(_notification: Notification) {
        
        UIView.animate(withDuration: 1.0, delay: 0.0, options: [.allowAnimatedContent], animations:
            {
                
                self.view.center = CGPoint (x : self.originx! , y : self.originy!)
                
        },
                       completion : nil)
    }
    
    func statusBarFrameWillChange(_notification : Notification)
    {
        self.originy = self.originy! + CGFloat(20)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        self.activeTextField = textField
    }
    
    func textFieldShouldReturn(_ scoreText: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    func showResultView()
    {
        let oldcenter = self.view.center
        
        originx = oldcenter.x
        originy = oldcenter.y
        let newCenter = CGPoint (x : oldcenter.x , y : oldcenter.y - self.keyboardHeight!/2)
        
        
        
        UIView.animate(withDuration: 1.0, delay: 0.0, options: [.allowAnimatedContent], animations:
            {
                
                self.view.center = newCenter
                
        },
                       completion : nil)
    }
    
}
