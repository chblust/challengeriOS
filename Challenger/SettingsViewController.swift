//
//  SettingsViewController.swift
//  Challenger
//
//  Created by Chris Blust on 6/14/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import UIKit
import SwiftyJSON
class SettingsViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var acceptedNotificationLabel: UILabel!
    @IBOutlet weak var followNotificationLabel: UILabel!
    @IBOutlet weak var likeNotificationLabel: UILabel!
    @IBOutlet weak var rechallengeNotificationLabel: UILabel!
    @IBOutlet weak var commentNotificationLabel: UILabel!
    @IBOutlet weak var passwordSaveButton: UIButton!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailSaveButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var bioSaveButton: UIButton!
    @IBOutlet weak var bioTextField: UITextField!
    
    
    @IBOutlet weak var acceptSwitch: UISwitch!
    @IBOutlet weak var followSwitch: UISwitch!
    @IBOutlet weak var likeSwitch: UISwitch!
    @IBOutlet weak var rechallengeSwitch: UISwitch!
    @IBOutlet weak var commentSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bioTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        setupFields()
            }
    
    func stringToBool(_ str: String) -> Bool{
        if str == "true"{
            return true
        }else{
            return false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Global.global.currentViewController = self
        URLSession.shared.dataTask(with: Global.createServerRequest(params: [
            "username": Global.global.loggedInUser.username!,
            "type":"getSettings"
            ], intent: "notifications")){data, response, error in
                if let data = data{
                    let json = JSON(data: data)
                    if let settings = json.dictionaryObject as? [String: String]{
                        OperationQueue.main.addOperation {
                            self.acceptSwitch.setOn(self.stringToBool(settings["accept"]!), animated: true)
                            self.followSwitch.setOn(self.stringToBool(settings["follow"]!), animated: true)
                            self.likeSwitch.setOn(self.stringToBool(settings["like"]!), animated: true)
                            self.rechallengeSwitch.setOn(self.stringToBool(settings["rechallenge"]!), animated: true)
                            self.commentSwitch.setOn(self.stringToBool(settings["comment"]!), animated: true)
                        }
                        
                    }
                }
            }.resume()

    }
    
    func setupFields(){
        bioTextField.placeholder = Global.global.loggedInUser.bio!
        bioTextField.text = ""
        emailTextField.placeholder = Global.global.loggedInUser.email!
        emailTextField.text = ""
        passwordTextField.text = ""
        
        bioSaveButton.isHidden = true
        emailSaveButton.isHidden = true
        passwordSaveButton.isHidden = true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == bioTextField{
            bioSaveButton.isHidden = false
        }else if textField == emailTextField{
            emailSaveButton.isHidden = false
        }else if textField == passwordTextField{
            passwordSaveButton.isHidden = false
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField)-> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func bioSaveButtonPressed(_ sender: UIButton) {
        let newBio = bioTextField.text!
        bioSaveButton.isHidden = true
        bioTextField.placeholder = bioTextField.text!
        bioTextField.text = ""
        let params = [
            "username":Global.global.loggedInUser.username!,
            "newBio":newBio
        ]
        URLSession.shared.dataTask(with: Global.createServerRequest(params: params, intent: "edit")).resume()
    }
    
    @IBAction func emailSaveButtonPressed(_ sender: UIButton) {
        let newEmail = emailTextField.text!
        emailSaveButton.isHidden = true
        emailTextField.placeholder = emailTextField.text!
        emailTextField.text = ""
        let params = [
            "username":Global.global.loggedInUser.username!,
            "newEmail":newEmail,
            ]
        URLSession.shared.dataTask(with: Global.createServerRequest(params: params, intent: "edit")).resume()
    }
    
    //shows a protective sequence before a password change
    @IBAction func passwordSaveButtonPressed(_ sender: UIButton) {
        let alert = UIAlertController(title: "Confirm Password Change", message: "enter current password", preferredStyle: .alert)
        alert.addTextField(configurationHandler: {(textField) in
            
        })
        alert.addAction(UIAlertAction(title: "Change", style: .destructive, handler: {(UIAlertAction) in
                URLSession.shared.dataTask(with: Global.createServerRequest(params: [
                    "username":Global.global.loggedInUser.username!,
                    "password":alert.textFields![0].text!
                    ], intent: "login")){data, response, error in
                if let data = data{
                    let json = JSON(data: data)
                    OperationQueue.main.addOperation {
                        if json["success"] == "true"{
                            
                            //reset password
                            let newPassword = self.passwordTextField.text!
                            self.passwordSaveButton.isHidden = true
                            let params = [
                                "username":Global.global.loggedInUser.username!,
                                "newPassword":newPassword
                            ]
                            URLSession.shared.dataTask(with: Global.createServerRequest(params: params, intent: "edit")).resume()
                            
                        }else{
                            Global.global.showAlert(title: "Wrong Password", message: "your password is incorrect!", here: self)
                        }
                    }
                }
                }.resume()}))
        alert.addAction(UIAlertAction(title: "cancel", style: .default, handler: { (UIAlertAction) in
            alert.dismiss(animated: true, completion: {})
        }))
        present(alert, animated: true, completion: {})
    }
    //returns fields to how they first were before editing commenced
    @IBAction func viewTapped(_ sender: UITapGestureRecognizer) {
        bioTextField.resignFirstResponder()
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        setupFields()
    }
    
    @IBAction func logoutButtonPressed(_ sender: UIButton) {
        UserDefaults.standard.removeObject(forKey: "loginUsername")
        Global.pusher.nativePusher.unsubscribe(interestName: Global.global.loggedInUser.username!)
        performSegue(withIdentifier: "unwindToLogin", sender: sender)
    }
    
    //sets the character limits on the individual text fields
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let str = textField.text
        if textField == bioTextField{
            if str!.characters.count <= 100 {
                return true
            }
            textField.text = str!.substring(to: str!.index(str!.startIndex, offsetBy: 100))
        }else{
            if str!.characters.count <= 40 {
                return true
            }
            textField.text = str!.substring(to: str!.index(str!.startIndex, offsetBy: 40))
        }
        
        return false
    }

    
    //misc methods
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func acceptedSwitchChanged(_ sender: UISwitch) {
        updateNotificationSetting(to: sender.isOn, forSetting: "accept")
    }
    @IBAction func followSwitchChanged(_ sender: UISwitch) {
        updateNotificationSetting(to: sender.isOn, forSetting: "follow")
    }
    @IBAction func likeSwitchChanged(_ sender: UISwitch) {
        updateNotificationSetting(to: sender.isOn, forSetting: "like")
    }
    @IBAction func rechallengeSwitchChanged(_ sender: UISwitch) {
        updateNotificationSetting(to: sender.isOn, forSetting: "rechallenge")
    }
    @IBAction func commentSwitchChanged(_ sender: UISwitch) {
        updateNotificationSetting(to: sender.isOn, forSetting: "comment")
    }
    
    func updateNotificationSetting(to: Bool, forSetting: String){
        var update: String!
        if to{
            update = "true"
        }else{
            update = "false"
        }
        URLSession.shared.dataTask(with: Global.createServerRequest(params: [
            "username": Global.global.loggedInUser.username!,
            "type": "set",
            "setting": forSetting,
            "update": update,
            ], intent: "notifications")).resume()
    }

}
