//
//  LeftSidePanelVC.swift
//  htchhkr
//
//  Created by Aris Doxakis on 9/21/18.
//  Copyright © 2018 DASoftware. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class LeftSidePanelVC: UIViewController {

    let appDelegate = AppDelegate.getAppDelegate()
    let currentUserId = Auth.auth().currentUser?.uid
    
    @IBOutlet weak var usrEmailLbl: UILabel!
    @IBOutlet weak var usrAccountTypeLbl: UILabel!
    @IBOutlet weak var usrImage: RoundImageView!
    @IBOutlet weak var pickupModeLbl: UILabel!
    @IBOutlet weak var loginLogoutBtn: UIButton!
    @IBOutlet weak var pickupModeSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        pickupModeSwitch.isOn = false
        pickupModeSwitch.isHidden = true
        pickupModeLbl.isHidden = true
        
        observePassengersAndDriver()
        
        if Auth.auth().currentUser == nil {
            usrEmailLbl.text = ""
            usrAccountTypeLbl.text = ""
            usrImage.isHidden = true
            loginLogoutBtn.setTitle("Sign Up / Login", for: .normal)
        } else {
            usrEmailLbl.text = Auth.auth().currentUser?.email
            usrAccountTypeLbl.text = ""
            usrImage.isHidden = false
            loginLogoutBtn.setTitle("Logout", for: .normal)
        }
    }
    
    func observePassengersAndDriver() {
        DataService.instance.REF_USERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for snap in snapshot {
                    if snap.key == Auth.auth().currentUser?.uid {
                        self.usrAccountTypeLbl.text = "Passenger"
                    }
                }
            }
        })
        
        DataService.instance.REF_DRIVERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for snap in snapshot {
                    if snap.key == Auth.auth().currentUser?.uid {
                        let pickUpMode = snap.childSnapshot(forPath: "isPickupModeEnabled").value as? Bool
                        self.usrAccountTypeLbl.text = "Driver"
                        
                        self.pickupModeSwitch.isOn = pickUpMode!
                        self.pickupModeSwitch.isHidden = false
                        self.pickupModeLbl.isHidden = false
                    }
                }
            }
        })
    }
    
    @IBAction func pickupModeSelected(_ sender: Any) {
        if pickupModeSwitch.isOn {
            pickupModeLbl.text = "PICKUP MODE ENABLED"
            appDelegate.menuContainerVC.toggleLeftPanel()
            DataService.instance.REF_DRIVERS.child(currentUserId!).updateChildValues(["isPickupModeEnabled": true])
        } else {
            pickupModeLbl.text = "PICKUP MODE DISABLED"
            appDelegate.menuContainerVC.toggleLeftPanel()
            DataService.instance.REF_DRIVERS.child(currentUserId!).updateChildValues(["isPickupModeEnabled": false])
        }
    }
    
    @IBAction func signupLoginBtnClicked(_ sender: Any) {
        if Auth.auth().currentUser == nil {
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as? LoginVC
            present(loginVC!, animated: true, completion: nil)
        } else {
            do {
                try Auth.auth().signOut()
                
                usrEmailLbl.text = ""
                usrAccountTypeLbl.text = ""
                usrImage.isHidden = true
                loginLogoutBtn.setTitle("Sign Up / Login", for: .normal)
                pickupModeSwitch.isOn = false
                pickupModeSwitch.isHidden = true
                pickupModeLbl.isHidden = true
                pickupModeLbl.text = ""
            } catch (let error) {
                print("Error logging out: \(error.localizedDescription)")
            }
        }
    }
}
