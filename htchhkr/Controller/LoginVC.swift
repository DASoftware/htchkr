//
//  LoginVC.swift
//  htchhkr
//
//  Created by Aris Doxakis on 9/21/18.
//  Copyright © 2018 DASoftware. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class LoginVC: UIViewController, UITextFieldDelegate, Alertable {

    @IBOutlet weak var userCategorySegment: UISegmentedControl!
    @IBOutlet weak var emailText: RoundedCornerTextField!
    @IBOutlet weak var passwordText: RoundedCornerTextField!
    @IBOutlet weak var signuoLoginBtn: RoundedShadowButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        emailText.delegate = self
        passwordText.delegate = self
        
        view.bindToKeyboard()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleScreenTap))
        self.view.addGestureRecognizer(tap)
    }
    
    @IBAction func closeLoginBtnClicked(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func handleScreenTap(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    @IBAction func signupLoginBtnClicked(_ sender: Any) {
        if emailText.text != nil && passwordText.text != nil {
            signuoLoginBtn.animateButton(shouldLoad: true, withMessage: nil)
            self.view.endEditing(true)
            
            if let email = emailText.text, let password = passwordText.text {
                Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                    if error == nil {
                        if let user = user {
                            if self.userCategorySegment.selectedSegmentIndex == 0 {
                                // Passenger.
                                let userData = ["provider": user.providerID] as [String: Any]
                                DataService.instance.createFirebaseDBUser(uid: user.uid, userData: userData, isDriver: false)
                            } else {
                                // Driver.
                                let userData = ["provider": user.providerID, USER_IS_DRIVER: true, ACCOUNT_PICKUP_MODE_ENABLED: false, DRIVER_IS_ON_TRIP: false] as [String: Any]
                                DataService.instance.createFirebaseDBUser(uid: user.uid, userData: userData, isDriver: true)
                            }
                            
                        }
                        print("Email user authenticated succesfully with firebase")
                        self.dismiss(animated: true, completion: nil)
                    } else {
                        if let errorCode = AuthErrorCode(rawValue: error!._code) {
                            switch errorCode {
                            case .wrongPassword:
                                self.showAlert(ERR_MSG_WRONG_PASSWORD)
                            default:
                                self.showAlert(ERR_MSG_UNEXPECTED)
                            }
                            
                            self.signuoLoginBtn.animateButton(shouldLoad: false, withMessage: MSG_SIGNUP_SIGN_IN)
                        }
                        
                        Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
                            if error != nil {
                                if let errorCode = AuthErrorCode(rawValue: error!._code) {
                                    switch errorCode {
                                    case .emailAlreadyInUse:
                                        self.showAlert(ERR_MSG_EMAIL_ALREADY_IN_USE)
                                    case .invalidEmail:
                                        self.showAlert(ERR_MSG_INVALID_EMAIL)
                                    default:
                                        self.showAlert(ERR_MSG_UNEXPECTED)
                                    }
                                }
                            } else {
                                if let user = user {
                                    let uid = user.uid
                                    let providerId = user.providerID
                                    
                                    if self.userCategorySegment.selectedSegmentIndex == 0 {
                                        // Passenger.
                                        let userData = ["provider": providerId] as [String: Any]
                                        DataService.instance.createFirebaseDBUser(uid: uid, userData: userData, isDriver: false)
                                    } else {
                                        // Driver.
                                        let userData = ["provider": providerId, USER_IS_DRIVER: true, ACCOUNT_PICKUP_MODE_ENABLED: false, DRIVER_IS_ON_TRIP: false] as [String: Any]
                                        DataService.instance.createFirebaseDBUser(uid: uid, userData: userData, isDriver: true)
                                    }
                                }
                                print("Email user authenticated succesfully with firebase")
                                self.dismiss(animated: true, completion: nil)
                            }
                        })
                    }
                }
            }
        } else {
            
        }
    }
    
}
