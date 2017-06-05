///
//  ViewController.swift
//  Challenger
//
//  Created by Chris Blust on 5/13/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import UIKit
import SwiftyJSON
class ViewController: UIViewController, UITextFieldDelegate, URLSessionDelegate {
    @IBOutlet weak var usernameField: UITextField!
    
    @IBOutlet weak var passwordField: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        UserDefaults.standard.removeObject(forKey: "loginUsername")
        super.viewDidLoad()
        self.navigationController?.setToolbarHidden(true, animated: true)
        //establish control over text fields
        usernameField.delegate = self
        passwordField.delegate = self
        
        if let username = UserDefaults.standard.value(forKey: "loginUsername") as? String{
            completeLogin(response: "true", username: username, sender: loginButton)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    @IBAction func loginButtonPressed(_ sender: UIButton) {
        if Global.textIsSafe(textField: usernameField, here: self){
            if Global.textIsSafe(textField: passwordField, here: self){
        //get username for later
        let username = usernameField.text!
        //setup request to attempt login
        let params = [
            "username": usernameField.text!,
            "password": passwordField.text!
        ]
        let loginRequest = Global.createServerRequest(params: params, intent: "login")
        let loginTask = URLSession.shared.dataTask(with: loginRequest){data, response, error in
            if let data = data{
                let json = JSON(data: data)
                //completion handler
                OperationQueue.main.addOperation {
                    UserDefaults.standard.set(username, forKey: "loginUsername")
                    self.completeLogin(response: json["success"].stringValue, username: username, sender: sender)
                }
            }
        }
        loginTask.resume()
        }
        }
    }
    
    func completeLogin(response: String, username: String, sender: UIButton){
        switch response{
            case "true":
                //since user info matches, get user metdata from server and segue to homepage
                let getLoginParams = [
                    "usernames[0]": username
                ]
                let getLoginRequest = Global.createServerRequest(params: getLoginParams, intent: "getUsers")
                let getLoginTask = URLSession.shared.dataTask(with: getLoginRequest){data, response, error in
                    if let data = data{
                        let json = JSON(data: data)
                        Global.global.loggedInUser = Global.jsonToUser(json: json[0].dictionaryValue)
                        OperationQueue.main.addOperation {
                            self.performSegue(withIdentifier: "login", sender: sender)
                        }
                    }
                }
                getLoginTask.resume()
            break
            case "false":
                Global.showAlert(title: "Login failed!", message: "credentials didn't match", here: self)
            break
            default:
             Global.showAlert(title: "Invalid Username", message: "the entered username does not exist", here: self)
            break
        }
    }
    @IBAction func unwindToVC1(segue:UIStoryboardSegue) { }
}
