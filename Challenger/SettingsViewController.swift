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

    @IBOutlet weak var passwordSaveButton: UIButton!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailSaveButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var bioSaveButton: UIButton!
    @IBOutlet weak var bioTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        bioTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        bioTextField.placeholder = Global.global.loggedInUser.bio!
        emailTextField.placeholder = Global.global.loggedInUser.email!
        self.navigationController!.navigationBar.isHidden = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController!.setNavigationBarHidden(false, animated: true)
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
        bioTextField.resignFirstResponder()
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
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
    
    @IBAction func passwordSaveButtonPressed(_ sender: UIButton) {
        let alert = UIAlertController(title: "Confirm Password Change", message: "enter current password", preferredStyle: .alert)
        alert.addTextField(configurationHandler: {(textField) in
            
        })
        alert.addAction(UIAlertAction(title: "Change", style: .destructive, handler: {(UIAlertAction) in
            let params = [
                "username":Global.global.loggedInUser.username!,
                "password":alert.textFields![0].text!
            ]
            URLSession.shared.dataTask(with: Global.createServerRequest(params: params, intent: "login")){data, response, error in
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
                        Global.showAlert(title: "Wrong Password", message: "your password is incorrect!", here: self)
                    }
                    }
                }
            }.resume()}))
        alert.addAction(UIAlertAction(title: "cancel", style: .default, handler: { (UIAlertAction) in
            alert.dismiss(animated: true, completion: {})
        }))
        present(alert, animated: true, completion: {})
    }
    
    @IBAction func viewTapped(_ sender: UITapGestureRecognizer) {
        bioTextField.resignFirstResponder()
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
    @IBAction func logoutButtonPressed(_ sender: UIButton) {
        UserDefaults.standard.removeObject(forKey: "loginUsername")
        performSegue(withIdentifier: "unwindToLogin", sender: sender)
    }
}
