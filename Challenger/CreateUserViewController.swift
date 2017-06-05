//
//  CreateUserViewController.swift
//  Challenger
//
//  Created by Chris Blust on 5/28/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import UIKit
import SwiftyJSON
class CreateUserViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var repeatPasswordTextField: UITextField!
    @IBOutlet weak var bioTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        Global.setupBannerAd(self, tab: false)
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        repeatPasswordTextField.delegate = self
        bioTextField.delegate = self
        emailTextField.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    @IBAction func acceptButtonPressed(_ sender: UIButton) {
        if Global.textIsSafe(textField: usernameTextField, here: self) && Global.textIsSafe(textField: passwordTextField, here: self) && Global.textIsSafe(textField: bioTextField, here: self) && Global.textIsSafe(textField: emailTextField, here: self){
            if passwordTextField.text! == repeatPasswordTextField.text!{
                if !usernameTextField.text!.characters.contains(" "){
                let params = [
                    "username":usernameTextField.text!,
                    "password":passwordTextField.text!,
                    "bio":bioTextField.text!,
                    "email": emailTextField.text!
                ]
                URLSession.shared.dataTask(with: Global.createServerRequest(params: params, intent: "createUser")){data, response, error in
                    if let data = data{
                        let json = JSON(data: data)
                        self.completeUserCreation(json["success"].stringValue, self.usernameTextField.text!, sender)
                    }
                }.resume()
                }else{
                        Global.showAlert(title: "Username contains illegal characters", message: "username cannot contain spaces", here: self)
                    }
            }else{
                Global.showAlert(title: "Passwords do not match", message: "please ensure your password is entered correctly in both fields", here: self)
            }
        }
    }
    
    func completeUserCreation(_ response: String, _ username: String, _ sender: UIButton){
        switch response{
            case "true":
                
                let getLoginParams = [
                    "usernames[0]": username
                ]
                let getLoginRequest = Global.createServerRequest(params: getLoginParams, intent: "getUsers")
                URLSession.shared.dataTask(with: getLoginRequest){data, response, error in
                    if let data = data{
                        let json = JSON(data: data)
                        Global.global.loggedInUser = Global.jsonToUser(json: json[0].dictionaryValue)
                        OperationQueue.main.addOperation {
                            self.performSegue(withIdentifier: "createUserToHome", sender: sender)
                        }
                    }
                }.resume()
            break
            case "false":
                Global.showAlert(title: "Username Taken", message: "please choose another username", here: self)
            break
        default:break
        }
    }
    
    //MARK: UITextFieldDelegate methods
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }
    
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
}
